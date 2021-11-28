#ifndef _ODPIS_H_
#define _ODPIS_H_

#ifdef W32
#include <windows.h>
#else
#include <time.h>
#endif

typedef struct threadArg
{
  unsigned int partition;
  unsigned int trial;
#ifdef W32
  FILETIME start;
  FILETIME end;
  LARGE_INTEGER qpcStart, qpcEnd;
#else
  struct timespec start;
  struct timespec end;
#endif
  int processed;
} threadArg;

#ifdef W32
extern DWORD WINAPI doInsert(LPVOID);
extern DWORD WINAPI doSelect(LPVOID);
#else
extern void *doInsert(void *);
extern void *doSelect(void *);
#endif

extern void init_db(void);
extern void cleanup_db(void);

#endif // _ODPIS_H_