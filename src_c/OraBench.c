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

int main(const int argc, const char *argv[])
{
  if (argc < 2)
  {
    printf("Usage: OraBench.exe config_file\n");
    return -1;
  }
  load_config(argv[1]);
  load_bulk(fileBulkName);

  sprintf(
      connectString, "%s:%d/%s", connectionHost, connectionPort,
      connectionService);

  LARGE_INTEGER elapsed, Frequency;
  QueryPerformanceFrequency(&Frequency);
  DWORD err;
  HANDLE *tid = (HANDLE *)malloc(benchmarkNumberPartitions * sizeof(HANDLE));
  threadArg *ta = (threadArg *)malloc(benchmarkNumberPartitions * sizeof(threadArg));
  LONGLONG maxDurationInsert = 0;
  LONGLONG maxDurationSelect = 0;
  FILETIME minStart, maxEnd, trialStart, trialEnd, benchmarkStart, benchmarkEnd;
  SYSTEMTIME minStartSys, minEndSys, trialStartSys, trialEndSys,
      benchmarkStartSys, benchmarkEndSys;
  LARGE_INTEGER trialQpcStart, trialQpcEnd, benchmarkQpcStart, benchmarkQpcEnd;

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
      "%s%s"                                        // benchmark id
      "%s%s"                                        // benchmark comment
      "%s%s"                                        //	host name
      "%d%s"                                        //	no. cores
      "%s%s"                                        //	os
      "%s%s"                                        //	user name
      "%s%s"                                        //	database
      "OraBench.exe (v0.1)%s"                       //	module
      "OCPI-C (v3.2.2)%s"                           //	driver
      "%%d%s"                                       //	trial no.
      "%%s%s"                                       //	SQL statement
      "%d%s"                                        //	core multiplier
      "%d%s"                                        //	fetch size
      "%d%s"                                        //	transaction size
      "%d%s"                                        //	bulk length
      "%d%s"                                        //	bulk size
      "%d%s"                                        //	batch size
      "%%s%s"                                       //	action
      "%%04d-%%02d-%%02d %%02d:%%02d:%%02d.%%09d%s" //	start day time
      "%%04d-%%02d-%%02d %%02d:%%02d:%%02d.%%09d%s" //	end day time
      "%%llu%s"                                     //	duration (sec)
      "%%llu\n",                                    //	duration (ns)
      benchmarkId, fileResultDelimiter,
      benchmarkComment, fileResultDelimiter,
      benchmarkHostName, fileResultDelimiter,
      benchmarkNumberCores, fileResultDelimiter,
      benchmarkOs, fileResultDelimiter,
      benchmarkUserName, fileResultDelimiter,
      benchmarkDatabase, fileResultDelimiter,
      /*module, */ fileResultDelimiter,
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

  GetSystemTimeAsFileTime(&benchmarkStart);
  if (!QueryPerformanceCounter(&benchmarkQpcStart))
    L("ERROR QueryPerformanceCounter(&benchmarkQpcStart)\n");

  for (int t = 0; t < benchmarkTrials; ++t)
  {
    init_db();
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
      ta[i].trial = t;
      ta[i].partition = i;
      ta[i].processed = 0;
    }

    GetSystemTimeAsFileTime(&trialStart);
    if (!QueryPerformanceCounter(&trialQpcStart))
      L("ERROR QueryPerformanceCounter(&trialQpcStart)\n");
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
      tid[i] = CreateThread(NULL, 0, doInsert, &(ta[i]), 0, NULL);
      if (tid[i] == NULL)
        L("ERROR can't create insert thread");
    }
    err = WaitForMultipleObjects(benchmarkNumberPartitions, tid, TRUE, INFINITE);
    if (err)
      L("WaitForMultipleObjects(doInsert) ERROR %d\n", err);
    minStart = ta[0].start;
    maxEnd = ta[0].end;
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
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
    }
    FileTimeToSystemTime(&minStart, &minStartSys);
    FileTimeToSystemTime(&maxEnd, &minEndSys);
    /*L(
        "Trial {%d} insert duration: %llu s, %llu ns\n"
        "\tstart: %04d-%02d-%02d %02d:%02d:%02d.%09d\n"
        "\tend: %04d-%02d-%02d %02d:%02d:%02d.%09d\n",
        t, (LONGLONG)(maxDurationInsert / 1000000), maxDurationInsert * 1000,
        minStartSys.wYear, minStartSys.wMonth, minStartSys.wDay, minStartSys.wHour,
        minStartSys.wMinute, minStartSys.wSecond, minStartSys.wMilliseconds * 1000000,
        minEndSys.wYear, minEndSys.wMonth, minEndSys.wDay, minEndSys.wHour,
        minEndSys.wMinute, minEndSys.wSecond, minEndSys.wMilliseconds * 1000000);*/
    fprintf(
        rfp, resultFmt, 0, sqlInsert, "query",
        minStartSys.wYear, minStartSys.wMonth, minStartSys.wDay,
        minStartSys.wHour, minStartSys.wMinute, minStartSys.wSecond,
        minStartSys.wMilliseconds * 1000000,
        minEndSys.wYear, minEndSys.wMonth, minEndSys.wDay, minEndSys.wHour,
        minEndSys.wMinute, minEndSys.wSecond, minEndSys.wMilliseconds * 1000000,
        (LONGLONG)(maxDurationInsert / 1000000), maxDurationInsert * 1000);

    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
      tid[i] = CreateThread(NULL, 0, doSelect, &(ta[i]), 0, NULL);
      if (tid[i] == NULL)
        L("ERROR can't create select threads");
    }
    err = WaitForMultipleObjects(benchmarkNumberPartitions, tid, TRUE, INFINITE);
    if (err)
      L("WaitForMultipleObjects(doSelect) ERROR %d\n", err);
    minStart = ta[0].start;
    maxEnd = ta[0].end;
    for (int i = 0; i < benchmarkNumberPartitions; ++i)
    {
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
    }
    GetSystemTimeAsFileTime(&trialEnd);
    if (!QueryPerformanceCounter(&trialQpcEnd))
      L("ERROR QueryPerformanceCounter(&trialQpcEnd)\n");

    /*L(
        "Trial {%d} select duration: %llu s, %llu ns\n"
        "\tstart: %04d-%02d-%02d %02d:%02d:%02d.%09d\n"
        "\tend: %04d-%02d-%02d %02d:%02d:%02d.%09d\n",
        t, (LONGLONG)(maxDurationSelect / 1000000), maxDurationSelect * 1000,
        minStartSys.wYear, minStartSys.wMonth, minStartSys.wDay, minStartSys.wHour,
        minStartSys.wMinute, minStartSys.wSecond, minStartSys.wMilliseconds * 1000000,
        minEndSys.wYear, minEndSys.wMonth, minEndSys.wDay, minEndSys.wHour,
        minEndSys.wMinute, minEndSys.wSecond, minEndSys.wMilliseconds * 1000000);*/
    FileTimeToSystemTime(&minStart, &minStartSys);
    FileTimeToSystemTime(&maxEnd, &minEndSys);
    fprintf(
        rfp, resultFmt, 0, sqlSelect, "query",
        minStartSys.wYear, minStartSys.wMonth, minStartSys.wDay,
        minStartSys.wHour, minStartSys.wMinute, minStartSys.wSecond,
        minStartSys.wMilliseconds * 1000000,
        minEndSys.wYear, minEndSys.wMonth, minEndSys.wDay, minEndSys.wHour,
        minEndSys.wMinute, minEndSys.wSecond, minEndSys.wMilliseconds * 1000000,
        (LONGLONG)(maxDurationInsert / 1000000), maxDurationInsert * 1000);

    elapsed.QuadPart = trialQpcEnd.QuadPart - trialQpcStart.QuadPart;
    elapsed.QuadPart *= 1000000;
    elapsed.QuadPart /= Frequency.QuadPart;
    FileTimeToSystemTime(&trialStart, &trialStartSys);
    FileTimeToSystemTime(&trialEnd, &trialEndSys);
    fprintf(
        rfp, resultFmt, t, "", "trial",
        trialStartSys.wYear, trialStartSys.wMonth, trialStartSys.wDay,
        trialStartSys.wHour, trialStartSys.wMinute, trialStartSys.wSecond,
        trialStartSys.wMilliseconds * 1000000, trialEndSys.wYear,
        trialEndSys.wMonth, trialEndSys.wDay, trialEndSys.wHour,
        trialEndSys.wMinute, trialEndSys.wSecond,
        trialEndSys.wMilliseconds * 1000000,
        (LONGLONG)(elapsed.QuadPart / 1000000), elapsed.QuadPart * 1000);
  }

  GetSystemTimeAsFileTime(&benchmarkEnd);
  if (!QueryPerformanceCounter(&benchmarkQpcEnd))
    L("ERROR QueryPerformanceCounter(&benchmarkQpcEnd)\n");
  elapsed.QuadPart = benchmarkQpcEnd.QuadPart - benchmarkQpcStart.QuadPart;
  elapsed.QuadPart *= 1000000;
  elapsed.QuadPart /= Frequency.QuadPart;
  FileTimeToSystemTime(&benchmarkStart, &benchmarkStartSys);
  FileTimeToSystemTime(&benchmarkEnd, &benchmarkEndSys);
  fprintf(
      rfp, resultFmt, 0, "", "benchmark",
      benchmarkStartSys.wYear, benchmarkStartSys.wMonth, benchmarkStartSys.wDay,
      benchmarkStartSys.wHour, benchmarkStartSys.wMinute,
      benchmarkStartSys.wSecond, benchmarkStartSys.wMilliseconds * 1000000,
      benchmarkEndSys.wYear, benchmarkEndSys.wMonth, benchmarkEndSys.wDay,
      benchmarkEndSys.wHour, benchmarkEndSys.wMinute, benchmarkEndSys.wSecond,
      benchmarkEndSys.wMilliseconds * 1000000,
      (LONGLONG)(elapsed.QuadPart / 1000000), elapsed.QuadPart * 1000);

  fclose(rfp);

  free(tid);
  free(ta);

  cleanup_db();

  return 0;
}
