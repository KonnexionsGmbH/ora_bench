#ifndef _THREADS_H_
#define _THREADS_H_

typedef struct threadArg
{
  unsigned int partition;
  unsigned int trial;
  SYSTEMTIME start;
  SYSTEMTIME end;
  LARGE_INTEGER qpcStart, qpcEnd;
  int processed;
} threadArg;

extern DWORD WINAPI doInsert(LPVOID);

#endif // _THREADS_H_