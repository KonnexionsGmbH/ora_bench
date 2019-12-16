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
    if (dpiContext_create(DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &gContext,
                          &errorInfo) < 0)
        FE("Cannot create DPI context", errorInfo);

    L("context created\n");

    dpiConn *conn;
    if (dpiConn_create(
            gContext,
            gConnUser, strlen(gConnUser),
            gConnPaswd, strlen(gConnPaswd),
            connectString, strlen(connectString),
            NULL, NULL, &conn) < 0)
    {
        E("Unable to create connection");
        exit(1);
    }
    L("connected!\n");

    L("sql.create %s\n", gSqlCreate);
    L("sql.drop %s\n", gSqlDrop);
    L("sql.insert %s\n", gSqlInsert);
    L("sql.select %s\n", gSqlSelect);

    return 0;
}
