#include <stdio.h>
#include <stdlib.h>

#ifdef W32
#include <windows.h>
#else
#include <pthread.h>
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
#endif

#include "dpi.h"
#ifdef EMBED
#include "../embed/dpi.c"
#endif

#include "global.h"
#include "config.h"
#include "threads.h"

dpiContext *gContext;
char connectString[1024];

int main(const int argc, const char *argv[])
{
  if (argc < 2)
  {
    printf("Usage: OraBench.exe config_file\n");
    return -1;
  }
  load_config(argv[1]);
  load_bulk(fileBulkName);

  sprintf(
      connectString, "%s:%d/%s", connectionHost, connectionPort,
      connectionService);

  dpiErrorInfo errorInfo;
  if (dpiContext_create(
          DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &gContext,
          &errorInfo) != DPI_SUCCESS)
    FE("Cannot create DPI context", errorInfo);

  L("context created\n");

  LARGE_INTEGER elapsed;
  LARGE_INTEGER Frequency;
  QueryPerformanceFrequency(&Frequency);
  dpiConn *conn;
  dpiStmt *stmt = NULL;
  for (int t = 0; t < benchmarkTrials; ++t)
  {
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
    L("sqlDrop\n");
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
    L("sqlCreate\n");
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

    DWORD err;
    HANDLE *tid = (HANDLE *)malloc(benchmarkNumberPartitions * sizeof(HANDLE));
    threadArg *ta = (threadArg *)malloc(benchmarkNumberPartitions * sizeof(threadArg));
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
      ta[i].partition = i;
      ta[i].trial = t;
      tid[i] = CreateThread(NULL, 0, doInsert, &(ta[i]), 0, NULL);
      if (tid[i] == NULL)
        L("ERROR can't create thread");
    }

    L("WaitForMultipleObjects...\n");
    err = WaitForMultipleObjects(benchmarkNumberPartitions, tid, TRUE, INFINITE);
    if (!err)
      L("WaitForMultipleObjects %d\n", err);
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
      CloseHandle(tid[i]);
      elapsed.QuadPart = ta[i].qpcEnd.QuadPart - ta[i].qpcStart.QuadPart;
      elapsed.QuadPart *= 1000000;
      elapsed.QuadPart /= Frequency.QuadPart;
      L(
          "{%d} [%u] processed %d rows start : %04d-%02d-%02d %02d:%02d:%02d.%09d end : %04d-%02d-%02d %02d:%02d:%02d.%09d -- %llu\n",
          ta[i].trial, ta[i].partition, ta[i].processed,
          ta[i].start.wYear, ta[i].start.wMonth, ta[i].start.wDay, ta[i].start.wHour,
          ta[i].start.wMinute, ta[i].start.wSecond, ta[i].start.wMilliseconds,
          ta[i].end.wYear, ta[i].end.wMonth, ta[i].end.wDay, ta[i].end.wHour,
          ta[i].end.wMinute, ta[i].end.wSecond, ta[i].end.wMilliseconds,
          elapsed.QuadPart);
    }

    free(tid);
    free(ta);
  }

  if (dpiContext_destroy(gContext) != DPI_SUCCESS)
    L("ERROR Cannot destroy DPI context");

  return 0;
}
