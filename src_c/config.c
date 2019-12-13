#include <stdio.h>
#include "global.h"
#include "config.h"

#define CONF_CP(_field) (strcmp(#_field, key) == 0) strcpy(c._field, val)
const config get_config(const char *file)
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

    config c;
    memset(&c, 0, sizeof(config));

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

    L("connection.user %s\n", c.connection.user);
    L("connection.password %s\n", c.connection.password);
    L("connection.service %s\n", c.connection.service);
    L("sql.create %s\n", c.sql.create);
    L("sql.drop %s\n", c.sql.drop);
    L("sql.insert %s\n", c.sql.insert);
    L("sql.select %s\n", c.sql.select);

    fclose(fp);

    return c;
}