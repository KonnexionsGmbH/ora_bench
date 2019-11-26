#include <stdio.h>

#define L(_fmt, ...) \
    printf("[%s:%s:%d] "_fmt, __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__)

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

    char connStr[256], connUser[256], connPassword[256];
    memset(connStr, '\0', sizeof(connStr));

    while (ch != EOF)
    {
        if (ch == ' ')
        {
            // skip white spaces
        }
        else if (ch != '=' && !valp)
        {
            *keyp = ch;
            keyp++;
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
                strcpy(connStr, val);
            else if (strcmp("connection.user", key) == 0)
                strcpy(connUser, val);
            else if (strcmp("connection.password", key) == 0)
                strcpy(connPassword, val);
            L("key %s, value %s\n", key, val);
        }
        ch = getc(fp);
    }

    L("connection.string (connStr) %s (%s, %s)\n", connStr, connUser, connPassword);

    fclose(fp);
    return 0;
}
