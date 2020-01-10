#include <stdio.h>
#include <stdlib.h>

#ifdef W32
#include <windows.h>
#else
#include <pthread.h>
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
#endif

#include "global.h"
#include "config.h"
#include "odpis.h"

char connectString[1024];

typedef
#ifdef W32
    HANDLE
#else
    pthread_t
#endif
        THREAD;

int main(const int argc, const char *argv[])
{
  if (argc < 2)
  {
    printf("Usage: OraBench.exe config_file\n");
    return -1;
  }
  load_config(argv[1]);

  L("Start %s\n", __FILE__);

  load_bulk(fileBulkName);

  sprintf(
      connectString, "%s:%d/%s", connectionHost, connectionPort,
      connectionService);

  THREAD *tid = (THREAD *)malloc(benchmarkNumberPartitions * sizeof(THREAD));
  threadArg *ta = (threadArg *)malloc(benchmarkNumberPartitions * sizeof(threadArg));

#ifdef W32
  LARGE_INTEGER elapsed, Frequency;
  QueryPerformanceFrequency(&Frequency);
  DWORD err;
  LONGLONG maxDurationInsert = 0;
  LONGLONG maxDurationSelect = 0;
  FILETIME minStart, maxEnd, trialStart, trialEnd, benchmarkStart, benchmarkEnd;
  SYSTEMTIME minStartSys, minEndSys, trialStartSys, trialEndSys,
      benchmarkStartSys, benchmarkEndSys;
  LARGE_INTEGER trialQpcStart, trialQpcEnd, benchmarkQpcStart, benchmarkQpcEnd;
#else
  struct timespec minStart, maxEnd, trialStart, trialEnd, benchmarkStart,
      benchmarkEnd;
  struct tm minStartTm, maxEndTm, trialStartTm, trialEndTm, benchmarkStartTm,
      benchmarkEndTm;
  char strStart[32], strEnd[32];
  unsigned long long int elapsed, maxDurationInsert = 0, maxDurationSelect = 0;
#endif

  FILE *rfp = fopen(fileResultName, "r");
  if (rfp)
  {
    fclose(rfp);
    rfp = fopen(fileResultName, "a");
    if (rfp == NULL)
    {
      L("ERROR: Unable to open result file %s\n", fileResultName);
      exit(-1);
    }
  }
  else
  {
    rfp = fopen(fileResultName, "a");
    fprintf(rfp, "%s\n", fileResultHeader);
  }

  char resultFmt[1024];
  sprintf(
      resultFmt,
      "%s%s" // release
      "%s%s" // benchmark id
      "%s%s" // benchmark comment
      "%s%s" //	host name
      "%d%s" //	no. cores
      "%s%s" //	os
      "%s%s" //	user name
      "%s%s" //	database
#ifdef WIN32
      "cl %d%s" //	language
#else
      "gnu %d.%d.%d%s" //	language
#endif

      "OCPI-C (v3.2.2)%s" //	driver
      "%%d%s"             //	trial no.
      "%%s%s"             //	SQL statement
      "%d%s"              //	core multiplier
      "%d%s"              //	fetch size
      "%d%s"              //	transaction size
      "%d%s"              //	bulk length
      "%d%s"              //	bulk size
      "%d%s"              //	batch size
      "%%s%s"             //	action
#ifdef W32
      "%%04d-%%02d-%%02d %%02d:%%02d:%%02d.%%09d%s" //	start day time
      "%%04d-%%02d-%%02d %%02d:%%02d:%%02d.%%09d%s" //	end day time
      "%%llu%s"                                     //	duration (sec)
      "%%llu"                                       //	duration (ns)
#else
      "%%s.%%09ld%s"   //	start day time
      "%%s.%%09ld%s"   //	end day time
      "%%lu%s"         //	duration (sec)
      "%%lu"           //	duration (ns)
#endif
      "\n",
      benchmarkRelease, fileResultDelimiter,
      benchmarkId, fileResultDelimiter,
      benchmarkComment, fileResultDelimiter,
      benchmarkHostName, fileResultDelimiter,
      benchmarkNumberCores, fileResultDelimiter,
      benchmarkOs, fileResultDelimiter,
      benchmarkUserName, fileResultDelimiter,
      benchmarkDatabase, fileResultDelimiter,
#ifdef W32
      _MSC_VER, fileResultDelimiter,
#else
      __GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__, fileResultDelimiter,
#endif
      /*driver, */ fileResultDelimiter,
      /*trial no., */ fileResultDelimiter,
      /*SQL statement, */ fileResultDelimiter,
      benchmarkCoreMultiplier, fileResultDelimiter,
      connectionFetchSize, fileResultDelimiter,
      benchmarkTransactionSize, fileResultDelimiter,
      fileBulkLength, fileResultDelimiter,
      fileBulkSize, fileResultDelimiter,
      benchmarkBatchSize, fileResultDelimiter,
      /*action, */ fileResultDelimiter,
      /*start day time, */ fileResultDelimiter,
      /*end day time */ fileResultDelimiter,
      /*duration (sec), */ fileResultDelimiter
      /*,	duration (ns)*/);

#ifdef W32
  GetSystemTimeAsFileTime(&benchmarkStart);
  if (!QueryPerformanceCounter(&benchmarkQpcStart))
    L("ERROR QueryPerformanceCounter(&benchmarkQpcStart)\n");
#else
  if (clock_gettime(CLOCK_REALTIME, &benchmarkStart))
    L("ERROR clock_gettime(CLOCK_REALTIME, &benchmarkStart)\n");
#endif

  for (int t = 1; t <= benchmarkTrials; ++t)
  {
    L("Trial: %d\n", t); fflush(stdout);

    init_db();
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
      ta[i].trial = t;
      ta[i].partition = i;
      ta[i].processed = 0;
    }

#ifdef W32
    GetSystemTimeAsFileTime(&trialStart);
    if (!QueryPerformanceCounter(&trialQpcStart))
      L("ERROR QueryPerformanceCounter(&trialQpcStart)\n");
#else
    if (clock_gettime(CLOCK_REALTIME, &trialStart))
      L("ERROR clock_gettime(CLOCK_REALTIME, &trialStart)\n");
#endif
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
#ifdef W32
      tid[i] = CreateThread(NULL, 0, doInsert, &(ta[i]), 0, NULL);
      if (tid[i] == NULL)
#else
      if (pthread_create(tid + i, NULL, doInsert, ta + i))
#endif
        L("ERROR can't create insert thread");
    }
#ifdef W32
    err = WaitForMultipleObjects(benchmarkNumberPartitions, tid, TRUE, INFINITE);
    if (err)
      L("WaitForMultipleObjects(doInsert) ERROR %d\n", err);
#else
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
      if (pthread_join(tid[i], NULL))
      {
        L("ERROR failed to join insert thread %ld\n", tid[i]);
        exit(-1);
      }
#endif
    minStart = ta[0].start;
    maxEnd = ta[0].end;
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
#ifdef W32
      CloseHandle(tid[i]);
      elapsed.QuadPart = ta[i].qpcEnd.QuadPart - ta[i].qpcStart.QuadPart;
      elapsed.QuadPart *= 1000000;
      elapsed.QuadPart /= Frequency.QuadPart;
      if (maxDurationInsert < elapsed.QuadPart)
        maxDurationInsert = elapsed.QuadPart;
      if (CompareFileTime(&(ta[i].start), &minStart) < 0)
        minStart = ta[i].start;
      if (CompareFileTime(&(ta[i].end), &maxEnd) > 0)
        maxEnd = ta[i].end;
#else
      elapsed = (ta[i].end.tv_sec - ta[i].start.tv_sec) * 1000000000;
      elapsed += ta[i].end.tv_nsec - ta[i].start.tv_nsec;
      if (maxDurationSelect < elapsed)
        maxDurationInsert = elapsed;
      if (ta[i].start.tv_sec < minStart.tv_sec ||
          (ta[i].start.tv_sec == minStart.tv_sec &&
           ta[i].start.tv_nsec < minStart.tv_nsec))
        minStart = ta[i].start;
      if (ta[i].end.tv_sec > maxEnd.tv_sec ||
          (ta[i].end.tv_sec == maxEnd.tv_sec &&
           ta[i].end.tv_nsec > maxEnd.tv_nsec))
        maxEnd = ta[i].end;
#endif
    }
#ifdef W32
    FileTimeToSystemTime(&minStart, &minStartSys);
    FileTimeToSystemTime(&maxEnd, &minEndSys);
#else
    localtime_r(&minStart.tv_sec, &minStartTm);
    localtime_r(&maxEnd.tv_sec, &maxEndTm);
    strftime(strStart, 32, "%Y-%m-%d %H:%M:%S", &minStartTm);
    strftime(strEnd, 32, "%Y-%m-%d %H:%M:%S", &maxEndTm);
#endif
    fprintf(
        rfp, resultFmt, t, sqlInsert, "query",
#ifdef W32
        minStartSys.wYear, minStartSys.wMonth, minStartSys.wDay,
        minStartSys.wHour, minStartSys.wMinute, minStartSys.wSecond,
        minStartSys.wMilliseconds * 1000000,
        minEndSys.wYear, minEndSys.wMonth, minEndSys.wDay, minEndSys.wHour,
        minEndSys.wMinute, minEndSys.wSecond, minEndSys.wMilliseconds * 1000000,
        (LONGLONG)(maxDurationInsert / 1000000), maxDurationInsert * 1000
#else
        strStart, minStart.tv_nsec, strEnd, maxEnd.tv_nsec,
        maxDurationInsert / 1000000000, maxDurationInsert
#endif
    );

    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
      ta[i].processed = 0;
#ifdef W32
      tid[i] = CreateThread(NULL, 0, doSelect, &(ta[i]), 0, NULL);
      if (tid[i] == NULL)
#else
      if (pthread_create(tid + i, NULL, doSelect, ta + i))
#endif
        L("ERROR can't create select threads");
    }
#ifdef W32
    err = WaitForMultipleObjects(benchmarkNumberPartitions, tid, TRUE, INFINITE);
    if (err)
      L("WaitForMultipleObjects(doSelect) ERROR %d\n", err);
#else
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
      if (pthread_join(tid[i], NULL))
      {
        L("ERROR failed to join select thread %ld\n", tid[i]);
        exit(-1);
      }
#endif
    minStart = ta[0].start;
    maxEnd = ta[0].end;
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
#ifdef W32
      CloseHandle(tid[i]);
      elapsed.QuadPart = ta[i].qpcEnd.QuadPart - ta[i].qpcStart.QuadPart;
      elapsed.QuadPart *= 1000000;
      elapsed.QuadPart /= Frequency.QuadPart;
      if (maxDurationSelect < elapsed.QuadPart)
        maxDurationSelect = elapsed.QuadPart;
      if (CompareFileTime(&(ta[i].start), &minStart) < 0)
        minStart = ta[i].start;
      if (CompareFileTime(&(ta[i].end), &maxEnd) > 0)
        maxEnd = ta[i].end;
#else
      elapsed = (ta[i].end.tv_sec - ta[i].start.tv_sec) * 1000000000;
      elapsed += ta[i].end.tv_nsec - ta[i].start.tv_nsec;
      if (maxDurationSelect < elapsed)
        maxDurationSelect = elapsed;
      if (ta[i].start.tv_sec < minStart.tv_sec ||
          (ta[i].start.tv_sec == minStart.tv_sec &&
           ta[i].start.tv_nsec < minStart.tv_nsec))
        minStart = ta[i].start;
      if (ta[i].end.tv_sec > maxEnd.tv_sec ||
          (ta[i].end.tv_sec == maxEnd.tv_sec &&
           ta[i].end.tv_nsec > maxEnd.tv_nsec))
        maxEnd = ta[i].end;
#endif
    }
#ifdef W32
    GetSystemTimeAsFileTime(&trialEnd);
    if (!QueryPerformanceCounter(&trialQpcEnd))
      L("ERROR QueryPerformanceCounter(&trialQpcEnd)\n");
#else
    if (clock_gettime(CLOCK_REALTIME, &trialEnd))
      L("ERROR clock_gettime(CLOCK_REALTIME, &trialEnd)\n");
#endif
#ifdef W32
    FileTimeToSystemTime(&minStart, &minStartSys);
    FileTimeToSystemTime(&maxEnd, &minEndSys);
#else
    localtime_r(&minStart.tv_sec, &minStartTm);
    localtime_r(&maxEnd.tv_sec, &maxEndTm);
    strftime(strStart, 32, "%Y-%m-%d %H:%M:%S", &minStartTm);
    strftime(strEnd, 32, "%Y-%m-%d %H:%M:%S", &maxEndTm);
#endif
    fprintf(
        rfp, resultFmt, t, sqlSelect, "query",
#ifdef W32
        minStartSys.wYear, minStartSys.wMonth, minStartSys.wDay,
        minStartSys.wHour, minStartSys.wMinute, minStartSys.wSecond,
        minStartSys.wMilliseconds * 1000000,
        minEndSys.wYear, minEndSys.wMonth, minEndSys.wDay, minEndSys.wHour,
        minEndSys.wMinute, minEndSys.wSecond, minEndSys.wMilliseconds * 1000000,
        (LONGLONG)(maxDurationSelect / 1000000), maxDurationSelect * 1000
#else
        strStart, minStart.tv_nsec, strEnd, maxEnd.tv_nsec,
        maxDurationSelect / 1000000000, maxDurationSelect
#endif
    );

#ifdef W32
    elapsed.QuadPart = trialQpcEnd.QuadPart - trialQpcStart.QuadPart;
    elapsed.QuadPart *= 1000000;
    elapsed.QuadPart /= Frequency.QuadPart;
    FileTimeToSystemTime(&trialStart, &trialStartSys);
    FileTimeToSystemTime(&trialEnd, &trialEndSys);
#else
    localtime_r(&trialStart.tv_sec, &trialStartTm);
    localtime_r(&trialEnd.tv_sec, &trialEndTm);
    strftime(strStart, 32, "%Y-%m-%d %H:%M:%S", &trialStartTm);
    strftime(strEnd, 32, "%Y-%m-%d %H:%M:%S", &trialEndTm);
    elapsed = (trialEnd.tv_sec - trialStart.tv_sec) * 1000000000;
    elapsed += trialEnd.tv_nsec - trialStart.tv_nsec;
#endif
    fprintf(
        rfp, resultFmt, t, "", "trial",
#ifdef W32
        trialStartSys.wYear, trialStartSys.wMonth, trialStartSys.wDay,
        trialStartSys.wHour, trialStartSys.wMinute, trialStartSys.wSecond,
        trialStartSys.wMilliseconds * 1000000, trialEndSys.wYear,
        trialEndSys.wMonth, trialEndSys.wDay, trialEndSys.wHour,
        trialEndSys.wMinute, trialEndSys.wSecond,
        trialEndSys.wMilliseconds * 1000000,
        (LONGLONG)(elapsed.QuadPart / 1000000), elapsed.QuadPart * 1000
#else
        strStart, trialStart.tv_nsec, strEnd, trialEnd.tv_nsec,
        elapsed / 1000000000, elapsed
#endif
    );

    char error = 0;
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
      if (gBulk[ta[i].partition].count != ta[i].processed)
      {
        error = 1;
        L(
            "ERROR: %d of %d found in partition %d\n",
            ta[i].processed, gBulk[ta[i].partition].count, ta[i].partition);
      }
    if (error)
      exit(-1);
  }
#ifdef W32
  GetSystemTimeAsFileTime(&benchmarkEnd);
  if (!QueryPerformanceCounter(&benchmarkQpcEnd))
    L("ERROR QueryPerformanceCounter(&benchmarkQpcEnd)\n");
  elapsed.QuadPart = benchmarkQpcEnd.QuadPart - benchmarkQpcStart.QuadPart;
  elapsed.QuadPart *= 1000000;
  elapsed.QuadPart /= Frequency.QuadPart;
  FileTimeToSystemTime(&benchmarkStart, &benchmarkStartSys);
  FileTimeToSystemTime(&benchmarkEnd, &benchmarkEndSys);
#else
  if (clock_gettime(CLOCK_REALTIME, &benchmarkEnd))
    L("ERROR clock_gettime(CLOCK_REALTIME, &benchmarkEnd)\n");
  localtime_r(&benchmarkStart.tv_sec, &benchmarkStartTm);
  localtime_r(&benchmarkEnd.tv_sec, &benchmarkEndTm);
  strftime(strStart, 32, "%Y-%m-%d %H:%M:%S", &benchmarkStartTm);
  strftime(strEnd, 32, "%Y-%m-%d %H:%M:%S", &benchmarkEndTm);
  elapsed = (benchmarkEnd.tv_sec - benchmarkStart.tv_sec) * 1000000000;
  elapsed += benchmarkEnd.tv_nsec - benchmarkStart.tv_nsec;
#endif
  fprintf(
      rfp, resultFmt, 0, "", "benchmark",
#ifdef W32
      benchmarkStartSys.wYear, benchmarkStartSys.wMonth, benchmarkStartSys.wDay,
      benchmarkStartSys.wHour, benchmarkStartSys.wMinute,
      benchmarkStartSys.wSecond, benchmarkStartSys.wMilliseconds * 1000000,
      benchmarkEndSys.wYear, benchmarkEndSys.wMonth, benchmarkEndSys.wDay,
      benchmarkEndSys.wHour, benchmarkEndSys.wMinute, benchmarkEndSys.wSecond,
      benchmarkEndSys.wMilliseconds * 1000000,
      (LONGLONG)(elapsed.QuadPart / 1000000), elapsed.QuadPart * 1000
#else
      strStart, benchmarkStart.tv_nsec, strEnd, benchmarkEnd.tv_nsec,
      elapsed / 1000000000, elapsed
#endif
  );
#ifdef W32
  L("End %s (%llu sec, %llu nsec)\n", __FILE__, (LONGLONG)(elapsed.QuadPart / 1000000), elapsed.QuadPart * 1000);
#else
  L("End %s (%llu sec, %llu nsec)\n", __FILE__, elapsed / 1000000000, elapsed);
#endif

  fclose(rfp);

  free(tid);
  free(ta);

  cleanup_db();

  return 0;
}
