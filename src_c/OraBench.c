#include <stdio.h>
#include "dpi.h"
#ifdef EMBED
#include "../embed/dpi.c"
#endif

#define L(_fmt, ...) \
    printf("[%s:%s:%d] "_fmt, __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__)

struct
{
    char user[256];
    char password[256];
    char string[1024];
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
        if (ch == ' ')
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
            if (strcmp("connection.string", key) == 0)
                strcpy(connection.string, val);
            else if (strcmp("connection.user", key) == 0)
                strcpy(connection.user, val);
            else if (strcmp("connection.password", key) == 0)
                strcpy(connection.password, val);
            //L("key %s, value %s\n", key, val);
        }
        ch = getc(fp);
    }

    L("connection.string (connStr) %s (%s, %s)\n", connection.string, connection.user, connection.string);

    fclose(fp);

    dpiErrorInfo errorInfo;
    if (dpiContext_create(DPI_MAJOR_VERSION, DPI_MINOR_VERSION, &gContext,
                          &errorInfo) < 0)
        FE("Cannot create DPI context", errorInfo);

    L("context created\n");

    const char userName[] = "scott";
    const char password[] = "regit";
    const char connectString[] = "(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521)))(CONNECT_DATA=(SERVER=dedicated)(SERVICE_NAME=orclpdb1)))";
    dpiConn *conn;
    if (dpiConn_create(
            gContext,
            userName, strlen(userName),
            password, strlen(password),
            connectString, strlen(connectString),
            NULL, NULL, &conn) < 0)
    {
        E("Unable to create connection");
        exit(1);
    }
    L("connected!\n");

    return 0;
}
