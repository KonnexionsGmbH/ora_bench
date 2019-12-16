#include <stdio.h>
#include "global.h"
#include "config.h"

char gConnHost[1024];
char gConnPort[1024];
char gConnUser[1024];
char gConnPaswd[1024];
char gConnService[1024];
char gSqlCreate[1024];
char gSqlDrop[1024];
char gSqlInsert[1024];
char gSqlSelect[1024];

#define CONF_CP(_field, _var) (strcmp(#_field, key) == 0) strcpy(_var, val)
void load_config(const char *file)
{
    FILE *fp = fopen(file, "r");
    if (fp == NULL)
    {
        L("ERROR: Unable to open config file %s\n", file);
        exit(-1);
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
                CONF_CP(connection.host, gConnHost);
            else if
                CONF_CP(connection.port, gConnPort);
            else if
                CONF_CP(connection.user, gConnUser);
            else if
                CONF_CP(connection.password, gConnPaswd);
            else if
                CONF_CP(connection.service, gConnService);
            else if
                CONF_CP(sql.create, gSqlCreate);
            else if
                CONF_CP(sql.drop, gSqlDrop);
            else if
                CONF_CP(sql.insert, gSqlInsert);
            else if
                CONF_CP(sql.select, gSqlSelect);
        }
        ch = getc(fp);
    }

    fclose(fp);
}