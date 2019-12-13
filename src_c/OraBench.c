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

    config c = get_config(argv[1]);

    char connectString[1024];
    sprintf(connectString,
            "%s:%s/%s", c.connection.host, c.connection.port, c.connection.service);
    L("connectString %s\n", connectString);
    dpiErrorInfo errorInfo;
    if (dpiContext_create(DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &gContext,
                          &errorInfo) < 0)
        FE("Cannot create DPI context", errorInfo);

    L("context created\n");

    dpiConn *conn;
    if (dpiConn_create(
            gContext,
            c.connection.user, strlen(c.connection.user),
            c.connection.password, strlen(c.connection.password),
            connectString, strlen(connectString),
            NULL, NULL, &conn) < 0)
    {
        E("Unable to create connection");
        exit(1);
    }
    L("connected!\n");

    return 0;
}
