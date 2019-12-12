#include <stdio.h>
#include "dpi.h"
#ifdef EMBED
#include "../embed/dpi.c"
#endif

#define L(_fmt, ...) \
    printf("[%s:%s:%d] "_fmt, __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__)

struct
{
    char user[128];
    char password[128];
    char service[128];
    char host[128];
    char port[8];
} connection;

struct
{
    char create[1024];
    char drop[1024];
    char insert[1024];
    char select[1024];
} sql;

dpiContext *gContext;

// error logging
#define FE(_m, _e)                                                   \
    {                                                                \
        L(                                                           \
            "FATAL: %s - %.*s (%s: %s)\n",                           \
            _m, _e.messageLength, _e.message, _e.fnName, _e.action); \
        exit(1);                                                     \
    }

#define E(_m)                                                        \
    {                                                                \
        dpiErrorInfo _i;                                             \
        dpiContext_getError(gContext, &_i);                          \
        L(                                                           \
            "ERROR: %s - %.*s (%s: %s)\n",                           \
            _m, _i.messageLength, _i.message, _i.fnName, _i.action); \
    }

#define CONF_CP(_field) (strcmp(#_field, key) == 0) strcpy(_field, val)

int main(const int argc, const char *argv[])
{
    if (argc < 2)
    {
        printf("Usage: OraBench.exe config_file\n");
        return -1;
    }
    FILE *fp = fopen(argv[1], "r");
    if (fp == NULL)
    {
        printf("ERROR: Unable to open config file %s\n", argv[1]);
        return -1;
    }

    char ch = getc(fp);
    char key[256];
    char val[1024];
    char *keyp = key;
    char *valp = NULL;

    while (ch != EOF)
    {
        if (ch == ' ' && !valp)
        {
            // skip white spaces
        }
        else if (ch != '=' && !valp)
        {
            if (ch != '\r' && ch != '\n')
            {
                *keyp = ch;
                keyp++;
            }
        }
        else if (ch == '=' && !valp)
        {
            *keyp = '\0';
            keyp = NULL;
            valp = val;
        }
        else if (ch != '\r' && ch != '\n' && !keyp)
        {
            *valp = ch;
            valp++;
        }
        else if (ch == '\r' || ch == '\n')
        {
            keyp = key;
            *valp = '\0';
            valp = NULL;
            if
                CONF_CP(connection.host);
            else if
                CONF_CP(connection.port);
            else if
                CONF_CP(connection.user);
            else if
                CONF_CP(connection.password);
            else if
                CONF_CP(connection.service);
            else if
                CONF_CP(sql.create);
            else if
                CONF_CP(sql.drop);
            else if
                CONF_CP(sql.insert);
            else if
                CONF_CP(sql.select);
        }
        ch = getc(fp);
    }

    L("connection.user %s\n", connection.user);
    L("connection.password %s\n", connection.password);
    L("connection.service %s\n", connection.service);
    L("sql.create %s\n", sql.create);
    L("sql.drop %s\n", sql.drop);
    L("sql.insert %s\n", sql.insert);
    L("sql.select %s\n", sql.select);

    fclose(fp);

    char connectString[1024];
    sprintf(connectString,
            "%s:%s/%s", connection.host, connection.port, connection.service);
    L("connectString %s\n", connectString);
    dpiErrorInfo errorInfo;
    if (dpiContext_create(DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &gContext,
                          &errorInfo) < 0)
        FE("Cannot create DPI context", errorInfo);

    L("context created\n");

    dpiConn *conn;
    if (dpiConn_create(
            gContext,
            connection.user, strlen(connection.user),
            connection.password, strlen(connection.password),
            connectString, strlen(connectString),
            NULL, NULL, &conn) < 0)
    {
        E("Unable to create connection");
        exit(1);
    }
    L("connected!\n");

    return 0;
}
