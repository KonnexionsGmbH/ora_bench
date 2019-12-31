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

dpiContext *gContext;

typedef struct threadArg
{
    unsigned int partition;
} threadArg;

#ifdef W32
DWORD WINAPI doThread(LPVOID arg)
#else
void *doThread(void *arg)
#endif
{
    threadArg *targ = (threadArg *)arg;
#ifdef W32
    DWORD id = GetCurrentThreadId();
#else
    pthread_t id = pthread_self();
#endif

    L("[%u] %lu thread processing\n", targ->partition, id);

    unsigned int row = 0, processed = 0;
    do
    {
        if (row > 0)
        {
            if (gBulk[row].partition == targ->partition)
            {
                processed++;
                L("[%lu] key = %s, partition %d, row %d\n", id, gBulk[row].key, targ->partition, row);
                //L("[%lu] data = %s\n", id, data);
            }
        }
    } while (row++ < 50);

    L("[%u] %lu thread end, total %d processed %d rows\n", targ->partition, id, row, processed);

#ifdef W32
    return 0;
#else
    return NULL;
#endif
}

int main(const int argc, const char *argv[])
{
    if (argc < 2)
    {
        printf("Usage: OraBench.exe config_file\n");
        return -1;
    }
    load_config(argv[1]);
    load_bulk(fileBulkName);

    char connectString[1024];
    sprintf(
        connectString, "%s:%d/%s", connectionHost, connectionPort,
        connectionService);

    dpiErrorInfo errorInfo;
    if (dpiContext_create(
            DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &gContext,
            &errorInfo) != DPI_SUCCESS)
        FE("Cannot create DPI context", errorInfo);

    L("context created\n");

    /*dpiConn *conn;
    if (dpiConn_create(
            gContext,
            gConnUser, strlen(gConnUser),
            gConnPaswd, strlen(gConnPaswd),
            connectString, strlen(connectString),
            NULL, NULL, &conn) != DPI_SUCCESS)
    {
        E("Unable to create connection");
        exit(1);
    }
    L("connected!\n");

    dpiStmt *stmt = NULL;

    L("sql.drop %s\n", gSqlDrop);
    if (dpiConn_prepareStmt(
            conn, 0, gSqlDrop, strlen(gSqlDrop), NULL, 0, &stmt) != DPI_SUCCESS)
    {
        E("Unable to prepare drop stmt");
        exit(-1);
    }
    if (dpiStmt_execute(
            stmt, DPI_MODE_EXEC_COMMIT_ON_SUCCESS, NULL) != DPI_SUCCESS)
        E("Unable to execute drop stmt");
    if (dpiStmt_close(stmt, NULL, 0) != DPI_SUCCESS)
    {
        E("Unable to close drop stmt");
        exit(-1);
    }

    L("sql.create %s\n", gSqlCreate);
    stmt = NULL;
    if (dpiConn_prepareStmt(
            conn, 0, gSqlCreate, strlen(gSqlCreate), NULL, 0, &stmt) != DPI_SUCCESS)
    {
        E("Unable to prepare create stmt");
        exit(-1);
    }
    if (dpiStmt_execute(
            stmt, DPI_MODE_EXEC_COMMIT_ON_SUCCESS, NULL) != DPI_SUCCESS)
    {
        E("Unable to execute create stmt");
        exit(-1);
    }
    if (dpiStmt_close(stmt, NULL, 0) != DPI_SUCCESS)
    {
        E("Unable to close create stmt");
        exit(-1);
    }*/

#ifdef W32
    DWORD err;
    HANDLE *tid = (HANDLE *)malloc(benchmarkNumberPartitions * sizeof(HANDLE));
#else
    int err;
    pthread_t *tid = (pthread_t *)malloc(benchmarkNumberPartitions * sizeof(pthread_t));
#endif
    threadArg *ta = (threadArg *)malloc(benchmarkNumberPartitions * sizeof(threadArg));
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
        ta[i].partition = i;
#ifdef W32
        tid[i] = CreateThread(NULL, 0, doThread, &(ta[i]), 0, NULL);
        if (tid[i] == NULL)
            L("ERROR can't create thread");
#else
        err = pthread_create(&(tid[i]), NULL, &doThread, &(ta[i]));
        if (err != 0)
            L("ERROR can't create thread :[%s]", strerror(err));
#endif
    }

#ifdef W32
    L("WaitForMultipleObjects...\n");
    err = WaitForMultipleObjects(benchmarkNumberPartitions, tid, TRUE, INFINITE);
    L("WaitForMultipleObjects %d\n", err);
#endif
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
#ifdef W32
        CloseHandle(tid[i]);
#else
        err = pthread_join(tid[i], NULL);
        if (err != 0)
            L("ERROR can't join thread :[%s]", strerror(err));
#endif
    }
    free(tid);
    free(ta);

    if (dpiContext_destroy(gContext) != DPI_SUCCESS)
        L("ERROR Cannot destroy DPI context");

    L("exit main!\n");
    return 0;
}
