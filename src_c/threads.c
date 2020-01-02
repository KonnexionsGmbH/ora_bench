#include <windows.h>

#include "dpi.h"
#ifdef EMBED
#include "../embed/dpi.c"
#endif

#include "global.h"
#include "config.h"
#include "threads.h"

extern dpiContext *gContext;
extern char connectString[1024];

DWORD WINAPI doInsert(LPVOID arg)
{
  threadArg *targ = (threadArg *)arg;
  DWORD id = GetCurrentThreadId();

  L("{%d} [%u] %lu thread processing\n", targ->trial, targ->partition, id);
  dpiConn *conn;
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
  dpiVar *varKey, *varData;
  dpiData *dataKey, *dataData;
  if (dpiConn_newVar(
          conn, DPI_ORACLE_TYPE_VARCHAR, DPI_NATIVE_TYPE_BYTES,
          benchmarkBatchSize, 32, 0, 0, NULL, &varKey,
          &dataKey) != DPI_SUCCESS)
  {
    E("Unable to create new var key");
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
    D("%s", sqlInsert);
    exit(-1);
  }
  if (dpiStmt_bindByName(stmt, "key", strlen("key"), varKey) != DPI_SUCCESS)
  {
    E("Unable to bind key to insert stmt");
    D("%s", sqlInsert);
    exit(-1);
  }
  if (dpiStmt_bindByName(stmt, "data", strlen("data"), varData) != DPI_SUCCESS)
  {
    E("Unable to bind data insert stmt");
    D("%s", sqlInsert);
    exit(-1);
  }

  GetLocalTime(&targ->start);
  if (!QueryPerformanceCounter(&targ->qpcStart))
    L("ERROR QueryPerformanceCounter(&qpcStart)\n");
  unsigned int row = 0;
  targ->processed = 0;
  int bbs = 0;
  int bts = 0;
  benchmarkTransactionSize;
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
          exit(-1);
        }
        bbs = 0;
      }
      if (dpiVar_setFromBytes(varKey, bbs, gBulk[row].key, 32) != DPI_SUCCESS)
      {
        E("Unable to set key to insert stmt");
        exit(-1);
      }
      if (
          dpiVar_setFromBytes(varData, bbs, gBulk[row].data, 1024) != DPI_SUCCESS)
      {
        E("Unable to set data to insert stmt");
        exit(-1);
      }
      bbs++;
      bts++;
      if (bts > benchmarkTransactionSize)
      {
        if (dpiConn_commit(conn) != DPI_SUCCESS)
        {
          E("Unable to set commit insert stmt");
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
      exit(-1);
    }
  }
  if (dpiConn_commit(conn) != DPI_SUCCESS)
  {
    E("Unable to set commit insert stmt");
    exit(-1);
  }
  GetLocalTime(&targ->end);
  if (!QueryPerformanceCounter(&targ->qpcEnd))
    L("ERROR QueryPerformanceCounter(&qpcEnd)\n");

  if (dpiStmt_close(stmt, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close insert stmt");
    D("%s", sqlInsert);
    exit(-1);
  }
  if (dpiVar_release(varKey) != DPI_SUCCESS)
  {
    E("Unable to release varKey");
    exit(-1);
  }
  if (dpiVar_release(varData) != DPI_SUCCESS)
  {
    E("Unable to release dataKey");
    exit(-1);
  }
  if (dpiConn_close(conn, DPI_MODE_CONN_CLOSE_DEFAULT, NULL, 0) != DPI_SUCCESS)
  {
    E("Unable to close conection");
    exit(-1);
  }
  L(
      "{%d} [%u] %lu thread inserted %lu of %lu rows\n",
      targ->trial, targ->partition, id, targ->processed, row);

  return 0;
}