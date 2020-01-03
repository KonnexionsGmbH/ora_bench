#ifndef _THREADS_H_
#define _THREADS_H_

typedef struct threadArg
{
  unsigned int partition;
  unsigned int trial;
  FILETIME start;
  FILETIME end;
  LARGE_INTEGER qpcStart, qpcEnd;
  int processed;
} threadArg;

extern DWORD WINAPI doInsert(LPVOID);
extern DWORD WINAPI doSelect(LPVOID);

extern void init_db(void);
extern void cleanup_db(void);

#endif // _THREADS_H_