#ifndef _CONFIG_H_
#pragma once

extern char gConnHost[1024];
extern char gConnPort[1024];
extern char gConnUser[1024];
extern char gConnPaswd[1024];
extern char gConnService[1024];
extern char gSqlCreate[1024];
extern char gSqlDrop[1024];
extern char gSqlInsert[1024];
extern char gSqlSelect[1024];

extern void load_config(const char *);

#endif // _CONFIG_H_