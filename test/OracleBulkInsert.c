#include "dpi.h"
#include "embed/dpi.c"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>

// config
#define CONNFMT "(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=tcp)(HOST=%s)(PORT=%s)))(CONNECT_DATA=(SERVICE_NAME=%s)))"
#define DROP "drop table test"
#define CREATE "create table test (item varchar2(4000))"
#define INSERT "insert into test (ITEM) values (:ITEM)"
#define SELECT "select ITEM from test"

void dpi_error(dpiContext *ctx, dpiErrorInfo err, unsigned line)
{
  if (ctx != NULL)
  dpiContext_getError(ctx, &err);

  printf(
    "\n%d: ERROR: %.*s (%s: %s)\n",
    line, err.messageLength, err.message, err.fnName, err.action
  );
}

int main(const int argc, char *argv[])
{
  FILE *logFp = fopen("/home/travis/ora_bench_test_result.log", "a");
  if(!logFp) {
    fprintf(
      stderr,
      "ERROR: unable to open /home/travis/ora_bench_test_result.log\n"
    );
    exit(1);
  }

  if(argc != 6) {
    fprintf(stderr, "Parameters : user password host port serviceName\n");
    exit(1);
  }
  char
    *user = argv[1],
    *password = argv[2],
    *host = argv[3],
    *port = argv[4],
    *service = argv[5],
    connection[512];
  sprintf(connection, CONNFMT, host, port, service);

  dpiContext *ctx;
  dpiErrorInfo err;

  if (dpiContext_create(DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &ctx, &err) < 0) {
    dpi_error(NULL, err, __LINE__);
    exit(1);
  }

  dpiConn *conn;
  if (
    dpiConn_create(
      ctx, user, strlen(user), password, strlen(password),
      connection, strlen(connection), NULL, NULL, &conn
    ) < 0
  ) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }

  printf("[%s:%d] Connected\n", __FILE__, __LINE__);

  dpiStmt *stmt;

  // Drop the existing table
  if (dpiConn_prepareStmt(conn, 0, DROP, strlen(DROP), NULL, 0, &stmt) < 0) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }
  if (dpiStmt_execute(stmt, DPI_MODE_EXEC_COMMIT_ON_SUCCESS, NULL) < 0) {
    dpi_error(ctx, err, __LINE__);
    // Table also may not exist, we can continue
  }
  dpiStmt_close(stmt, NULL, 0);

  // Create the table
  if (dpiConn_prepareStmt(conn, 0, CREATE, strlen(CREATE), NULL, 0, &stmt) < 0) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }
  if (dpiStmt_execute(stmt, DPI_MODE_EXEC_COMMIT_ON_SUCCESS, NULL) < 0) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }
  dpiStmt_close(stmt, NULL, 0);

  printf("[%s:%d] Initialized\n", __FILE__, __LINE__);

  dpiData *arrayValue;
  dpiVar *stringColVar;
  const uint32_t maxArraySize = 10000;
  if (
    dpiConn_newVar(
      conn, DPI_ORACLE_TYPE_VARCHAR, DPI_NATIVE_TYPE_BYTES,
      maxArraySize, 16, 1, 0, NULL, &stringColVar, &arrayValue
    ) < 0
  ) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }

  if (dpiConn_prepareStmt(conn, 0, INSERT, strlen(INSERT), NULL, 0, &stmt) < 0) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }

  if (dpiStmt_bindByName(stmt, "ITEM", strlen("ITEM"), stringColVar) < 0) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }

  char c[12];
  unsigned long count = 0;
  clock_t begin = clock();
  uint32_t idx = 0;
  printf("[%s:%d] Inserting...\n", __FILE__, __LINE__);
  do {
    c[11] = '\0';
    sprintf(c, "%010lu", count);
    count++;
    if (dpiVar_setFromBytes(stringColVar, idx, c, strlen(c)) < 0) {
        dpi_error(ctx, err, __LINE__);
        exit(1);
    }
    idx++;
    if (idx >= maxArraySize) {
      idx = 0;
      if (dpiStmt_executeMany(stmt, DPI_MODE_EXEC_DEFAULT, maxArraySize) < 0) {
        dpi_error(ctx, err, __LINE__);
        break;
      }
    }

    if (count % 100000 == 0) {
      printf(" %lu", count);
      fflush(stdout);
    }

  } while (1);

  if (
    idx > 0 &&
    dpiStmt_executeMany(stmt, DPI_MODE_EXEC_DEFAULT, idx) < 0
  ) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }
  dpiConn_commit(conn);
  dpiStmt_close(stmt, NULL, 0);
  dpiVar_release(stringColVar);

  clock_t end = clock();
  double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
  double rate = count / time_spent;
  printf(
    "\nODPI-C inserted %lu rows in %f seconds (%f rows / sec)\n",
    count, time_spent, rate
  );
  fprintf(
    logFp,
    "ODPI-C\tINSERT\t%lu rows in %f seconds (%f rows/sec)\n",
    count, time_spent, rate
  );

  begin = end;

  if (dpiConn_prepareStmt(conn, 0, SELECT, strlen(SELECT), NULL, 0, &stmt) < 0) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }
  if (dpiStmt_execute(stmt, DPI_MODE_EXEC_DEFAULT, NULL) < 0) {
    dpi_error(ctx, err, __LINE__);
    exit(1);
  }

  dpiNativeTypeNum nativeTypeNum;
  dpiData *data;
  count = 0;
  int found;
  uint32_t bufferRowIndex;
  dpiBytes *bytes;
  printf("[%s:%d] Selecting...\n", __FILE__, __LINE__);
  do {
    if (dpiStmt_fetch(stmt, &found, &bufferRowIndex)) {
      dpi_error(ctx, err, __LINE__);
      break;
    }
    if(found < 1) break;

    if (dpiStmt_getQueryValue(stmt, 1, &nativeTypeNum, &data)) {
      dpi_error(ctx, err, __LINE__);
      break;
    }

    bytes = dpiData_getBytes(data);
    if(bytes->length != 10) {
      fprintf(stderr, "bad read length %d\n", bytes->length);
      break;
    }

    count++;
    if (count % 100000 == 0) {
      printf(" %lu", count);
      fflush(stdout);
    }

  } while (1);

  end = clock();
  time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
  rate = count / time_spent;
  printf(
    "\nODPI-C selected %lu rows in %f seconds (%f rows / sec)\n",
    count, time_spent, rate
  );
  fprintf(
    logFp,
    "ODPI-C\tSELECT\t%lu rows in %f seconds (%f rows/sec)\n",
    count, time_spent, rate
  );

  dpiConn_close(conn, DPI_MODE_CONN_CLOSE_DEFAULT, NULL, 0);
  dpiContext_destroy(ctx);

  fclose(logFp);
  return 0;
}
