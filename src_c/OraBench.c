#include <stdio.h>

#include "dpi.h"
#ifdef EMBED
#include "../embed/dpi.c"
#endif

#include "global.h"
#include "config.h"

dpiContext *gContext;

int main(const int argc, const char *argv[])
{
    if (argc < 2)
    {
        printf("Usage: OraBench.exe config_file\n");
        return -1;
    }

    load_config(argv[1]);

    char connectString[1024];
    sprintf(connectString,
            "%s:%s/%s", gConnHost, gConnPort, gConnService);

    L("connection.user %s\n", gConnUser);
    L("connection.password %s\n", gConnPaswd);
    L("connectString %s\n", connectString);

    dpiErrorInfo errorInfo;
    if (dpiContext_create(
            DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &gContext,
            &errorInfo) != DPI_SUCCESS)
        FE("Cannot create DPI context", errorInfo);

    L("context created\n");

    dpiConn *conn;
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
    }

    L("sql.insert %s\n", gSqlInsert);
    L("sql.select %s\n", gSqlSelect);

    return 0;
}
