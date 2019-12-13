#ifndef _CONFIG_H_
#pragma once

typedef struct config_t
{
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
} config;

extern const config get_config(const char *);

#endif // _CONFIG_H_