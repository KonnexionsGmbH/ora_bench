#ifndef _GLOBAL_H_
#define _GLOBAL_H_

#define L(_fmt, ...) \
    printf("[%s:%s:%d] "_fmt, __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__)

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

#endif //_GLOBAL_H_