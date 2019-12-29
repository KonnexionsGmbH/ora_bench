#ifndef _CONFIG_H_
#pragma once


extern int benchmarkBatchSize;
extern char *benchmarkComment;
extern int benchmarkCoreMultiplier;
extern char *benchmarkDatabase;
extern char *benchmarkHostName;
extern char *benchmarkId;
extern int benchmarkNumberCores;
extern int benchmarkNumberPartitions;
extern char *benchmarkOs;
extern int benchmarkTransactionSize;
extern int benchmarkTrials;
extern char *benchmarkUserName;

extern int connectionFetchSize;
extern char *connectionHost;
extern char *connectionPassword;
extern int connectionPort;
extern char *connectionService;
extern char *connectionUser;

extern char *fileBulkDelimiter;
extern char *fileBulkHeader;
extern int fileBulkLength;
extern char *fileBulkName;
extern int fileBulkSize;
extern char *fileConfigurationName;
extern char *fileResultDelimiter;
extern char *fileResultHeader;
extern char *fileResultName;

extern char *sqlCreate;
extern char *sqlDrop;
extern char *sqlInsert;
extern char *sqlSelect;

extern void load_config(const char *);

#endif // _CONFIG_H_