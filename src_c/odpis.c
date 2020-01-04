#include "global.h"
#include "config.h"
#include "odpis.h"

#include "dpi.h"
#ifdef EMBED
#include "../embed/dpi.c"
#endif

dpiContext *gContext;
extern char connectString[1024];

#ifdef W32
DWORD WINAPI doInsert(LPVOID arg)
#else
void *doInsert(void *arg)
#endif
{
  threadArg *targ = (threadArg *)arg;
#ifdef W32
  DWORD id = GetCurrentThreadId();
#else
  pthread_t id = pthread_self();
#endif

  //L("{%d} [%u] %lu thread processing\n", targ->trial, targ->partition, id);
  dpiConn *conn;
  if (dpiConn_create(
          gContext,
          connectionUser, strlen(connectionUser),
          connectionPassword, strlen(connectionPassword),
          connectString, strlen(connectString),
          NULL, NULL, &conn) != DPI_SUCCESS)
  {
    E("Unable to create connection");
    D("{%d} [%u] %lu", targ->trial, targ->partition, id);
    exit(1);
  }
  dpiVar *varKey, *varData;
  dpiData *dataKey, *dataData;
  if (dpiConn_newVar(
          conn, DPI_ORACLE_TYPE_VARCHAR, DPI_NATIVE_TYPE_BYTES,
          benchmarkBatchSize, 32, 0, 0, NULL, &varKey,
          &dataKey) != DPI_SUCCESS)
  {
    E("Unable to create new var key");
    D("{%d} [%u] %lu", targ->trial, targ->partition, id);
    exit(1);
  }
  if (dpiConn_newVar(
          conn, DPI_ORACLE_TYPE_VARCHAR, DPI_NATIVE_TYPE_BYTES,
          benchmarkBatchSize, fileBulkLength, 0, 0, NULL, &varData,
          &dataData) != DPI_SUCCESS)
  {
    E("Unable to create new var data");
    exit(1);
  }
  dpiStmt *stmt = NULL;
  if (dpiConn_prepareStmt(
          conn, 0, sqlInsert, strlen(sqlInsert), NULL, 0, &stmt) != DPI_SUCCESS)
  {
    E("Unable to prepare insert stmt");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
    exit(-1);
  }
  if (dpiStmt_bindByName(stmt, "key", strlen("key"), varKey) != DPI_SUCCESS)
  {
    E("Unable to bind key to insert stmt");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
    exit(-1);
  }
  if (dpiStmt_bindByName(stmt, "data", strlen("data"), varData) != DPI_SUCCESS)
  {
    E("Unable to bind data insert stmt");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
    exit(-1);
  }

#ifdef W32
  GetSystemTimeAsFileTime(&targ->start);
  if (!QueryPerformanceCounter(&targ->qpcStart))
    L(
        "{%d} [%u] %lu ERROR QueryPerformanceCounter(&qpcStart)\n",
        targ->trial, targ->partition, id);
#else
  if (clock_gettime(CLOCK_REALTIME, &targ->start))
    L(
        "{%d} [%u] %lu ERROR clock_gettime(CLOCK_REALTIME, start)\n",
        targ->trial, targ->partition, id);
#endif
  unsigned int row = 0;
  int bbs = 0;
  int bts = 0;
  do
  {
    if (gBulk[row].partition == targ->partition)
    {
      targ->processed++;
      if (bbs >= benchmarkBatchSize)
      {
        if (
            dpiStmt_executeMany(
                stmt, DPI_MODE_EXEC_DEFAULT,
                benchmarkBatchSize) != DPI_SUCCESS)
        {
          E("Unable to execute insert stmt");
          D(
              "{%d} [%u] %lu, numIters/benchmarkBatchSize %d, %s",
              targ->trial, targ->partition, id, benchmarkBatchSize, sqlInsert);
          exit(-1);
        }
        bbs = 0;
      }
      if (dpiVar_setFromBytes(varKey, bbs, gBulk[row].key, 32) != DPI_SUCCESS)
      {
        E("Unable to set key to insert stmt");
        D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
        exit(-1);
      }
      if (
          dpiVar_setFromBytes(
              varData, bbs, gBulk[row].data, 1024) != DPI_SUCCESS)
      {
        E("Unable to set data to insert stmt");
        D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
        exit(-1);
      }
      bbs++;
      bts++;
      if (bts > benchmarkTransactionSize)
      {
        if (dpiConn_commit(conn) != DPI_SUCCESS)
        {
          E("Unable to set commit insert stmt");
          D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
          exit(-1);
        }
        bts = 0;
      }
    }
  } while (++row < fileBulkSize);
  if (bbs)
  {
    if (dpiStmt_executeMany(stmt, DPI_MODE_EXEC_DEFAULT, bbs) != DPI_SUCCESS)
    {
      E("Unable to execute insert stmt");
      D(
          "{%d} [%u] %lu, numIters %d, %s",
          targ->trial, targ->partition, id, bbs, sqlInsert);
      exit(-1);
    }
  }
  if (dpiConn_commit(conn) != DPI_SUCCESS)
  {
    E("Unable to set commit insert stmt");
    exit(-1);
  }
#ifdef W32
  GetSystemTimeAsFileTime(&targ->end);
  if (!QueryPerformanceCounter(&targ->qpcEnd))
    L(
        "{%d} [%u] %lu ERROR QueryPerformanceCounter(&qpcEnd)\n",
        targ->trial, targ->partition, id);
#else
  if (clock_gettime(CLOCK_REALTIME, &targ->end))
    L(
        "{%d} [%u] %lu ERROR clock_gettime(CLOCK_REALTIME, end)\n",
        targ->trial, targ->partition, id);
#endif

  if (dpiStmt_close(stmt, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close insert stmt");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
    exit(-1);
  }
  if (dpiVar_release(varKey) != DPI_SUCCESS)
  {
    E("Unable to release varKey");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
    exit(-1);
  }
  if (dpiVar_release(varData) != DPI_SUCCESS)
  {
    E("Unable to release dataKey");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
    exit(-1);
  }
  if (dpiConn_close(conn, DPI_MODE_CONN_CLOSE_DEFAULT, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close conection");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, sqlInsert);
    exit(-1);
  }
  /*L(
      "{%d} [%u] %lu thread inserted %lu of %lu rows\n",
      targ->trial, targ->partition, id, targ->processed, row);*/

  return 0;
}

#ifdef W32
DWORD WINAPI doSelect(LPVOID arg)
#else
void *doSelect(void *arg)
#endif
{
  threadArg *targ = (threadArg *)arg;
#ifdef W32
  DWORD id = GetCurrentThreadId();
#else
  pthread_t id = pthread_self();
#endif

  //L("{%d} [%u] %lu thread processing\n", targ->trial, targ->partition, id);
  dpiConn *conn;
  if (dpiConn_create(
          gContext,
          connectionUser, strlen(connectionUser),
          connectionPassword, strlen(connectionPassword),
          connectString, strlen(connectString),
          NULL, NULL, &conn) != DPI_SUCCESS)
  {
    E("Unable to create connection");
    D("{%d} [%u] %lu", targ->trial, targ->partition, id);
    exit(1);
  }

  char *patchedSqlSelect =
      (char *)malloc(sizeof(char) * (strlen(sqlSelect) + 32));
  sprintf(
      patchedSqlSelect, "%s WHERE partition_key = %d", sqlSelect,
      targ->partition);
  dpiStmt *stmt = NULL;
  if (dpiConn_prepareStmt(
          conn, 0, patchedSqlSelect, strlen(patchedSqlSelect), NULL, 0,
          &stmt) != DPI_SUCCESS)
  {
    E("Unable to prepare select stmt");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, patchedSqlSelect);
    exit(-1);
  }
  uint32_t numQueryColumns = 0;
  if (
      dpiStmt_execute(
          stmt, DPI_MODE_EXEC_DEFAULT, &numQueryColumns) != DPI_SUCCESS ||
      numQueryColumns != 2)
  {
    E("Unable to execute select stmt");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, patchedSqlSelect);
    exit(-1);
  }
  if (dpiStmt_setFetchArraySize(stmt, connectionFetchSize) != DPI_SUCCESS)
  {
    E("Unable to set select fetch size to");
    D(
        "{%d} [%u] %lu connectionFetchSize %d, %s",
        targ->trial, targ->partition, id, connectionFetchSize,
        patchedSqlSelect);
    exit(-1);
  }

  int found, err;
  uint32_t bufferRowIndex;
  dpiNativeTypeNum nativeTypeNumKey, nativeTypeNumData;
  dpiData *key, *data;
  dpiBytes *keyBytes, *dataBytes;

#ifdef W32
  GetSystemTimeAsFileTime(&targ->start);
  if (!QueryPerformanceCounter(&targ->qpcStart))
    L("ERROR QueryPerformanceCounter(&qpcStart)\n");
#else
  if (clock_gettime(CLOCK_REALTIME, &targ->start))
    L(
        "{%d} [%u] %lu ERROR clock_gettime(CLOCK_REALTIME, start)\n",
        targ->trial, targ->partition, id);
#endif
  while (
      (err = dpiStmt_fetch(stmt, &found, &bufferRowIndex)) == DPI_SUCCESS && found > 0)
  {
    if (dpiStmt_getQueryValue(stmt, 1, &nativeTypeNumKey, &key) != DPI_SUCCESS)
    {
      E("Unable to get key from select query");
      D("%s", patchedSqlSelect);
      exit(-1);
    }

    if (dpiStmt_getQueryValue(stmt, 2, &nativeTypeNumData, &data) != DPI_SUCCESS)
    {
      E("Unable to get data from select query");
      D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, patchedSqlSelect);
      exit(-1);
    }
    keyBytes = dpiData_getBytes(key);
    dataBytes = dpiData_getBytes(data);
    if (keyBytes->length <= 0 || dataBytes->length <= 0)
      L(
          "{%d} [%u] %lu ERROR key/data select retrieve failed",
          targ->trial, targ->partition, id);

    targ->processed++;
  }
#ifdef W32
  GetSystemTimeAsFileTime(&targ->end);
  if (!QueryPerformanceCounter(&targ->qpcEnd))
    L("ERROR QueryPerformanceCounter(&qpcEnd)\n");
#else
  if (clock_gettime(CLOCK_REALTIME, &targ->end))
    L(
        "{%d} [%u] %lu ERROR clock_gettime(CLOCK_REALTIME, end)\n",
        targ->trial, targ->partition, id);
#endif

  if (dpiStmt_close(stmt, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close select stmt");
    D("{%d} [%u] %lu %s", targ->trial, targ->partition, id, patchedSqlSelect);
    exit(-1);
  }
  free(patchedSqlSelect);
  if (dpiConn_close(conn, DPI_MODE_CONN_CLOSE_DEFAULT, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close conection");
    D("{%d} [%u] %lu", targ->trial, targ->partition, id);
    exit(-1);
  }
  /*L(
      "{%d} [%u] %lu thread selected %lu of %lu rows\n",
      targ->trial, targ->partition, id, targ->processed, fileBulkSize);*/

  return 0;
}

void init_db(void)
{
  if (!gContext)
  {
    dpiErrorInfo errorInfo;
    if (dpiContext_create(
            DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &gContext,
            &errorInfo) != DPI_SUCCESS)
      FE("Cannot create DPI context", errorInfo);
    L("context created\n");
  }

  dpiConn *conn;
  dpiStmt *stmt = NULL;
  if (dpiConn_create(
          gContext,
          connectionUser, strlen(connectionUser),
          connectionPassword, strlen(connectionPassword),
          connectString, strlen(connectString),
          NULL, NULL, &conn) != DPI_SUCCESS)
  {
    E("Unable to create connection");
    exit(1);
  }
  if (dpiConn_prepareStmt(
          conn, 0, sqlDrop, strlen(sqlDrop), NULL, 0, &stmt) != DPI_SUCCESS)
  {
    E("Unable to prepare drop stmt");
    D("%s", sqlDrop);
    exit(-1);
  }
  if (dpiStmt_execute(
          stmt, DPI_MODE_EXEC_COMMIT_ON_SUCCESS, NULL) != DPI_SUCCESS)
  {
    E("Unable to execute drop stmt");
    D("%s", sqlDrop);
  }
  if (dpiStmt_close(stmt, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close drop stmt");
    D("%s", sqlDrop);
    exit(-1);
  }
  stmt = NULL;
  if (dpiConn_prepareStmt(
          conn, 0, sqlCreate, strlen(sqlCreate), NULL, 0, &stmt) != DPI_SUCCESS)
  {
    E("Unable to prepare create stmt");
    D("%s", sqlCreate);
    exit(-1);
  }
  if (dpiStmt_execute(
          stmt, DPI_MODE_EXEC_COMMIT_ON_SUCCESS, NULL) != DPI_SUCCESS)
  {
    E("Unable to execute create stmt");
    D("%s", sqlCreate);
    exit(-1);
  }
  if (dpiStmt_close(stmt, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close create stmt");
    D("%s", sqlCreate);
    exit(-1);
  }
  if (dpiConn_close(conn, DPI_MODE_CONN_CLOSE_DEFAULT, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close create stmt");
    exit(-1);
  }
}

void cleanup_db(void)
{

  if (dpiContext_destroy(gContext) != DPI_SUCCESS)
    L("ERROR Cannot destroy DPI context");
}