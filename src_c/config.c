#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "global.h"
#include "config.h"

int benchmarkBatchSize;
char *benchmarkComment;
int benchmarkCoreMultiplier;
char *benchmarkDatabase;
char *benchmarkHostName;
char *benchmarkId;
int benchmarkNumberCores;
int benchmarkNumberPartitions;
char *benchmarkOs;
int benchmarkTransactionSize;
int benchmarkTrials;
char *benchmarkUserName;

int connectionFetchSize;
char *connectionHost;
char *connectionPassword;
int connectionPort;
char *connectionService;
char *connectionUser;

char *fileBulkDelimiter;
char *fileBulkHeader;
int fileBulkLength;
char *fileBulkName;
int fileBulkSize;
char *fileConfigurationName;
char *fileResultDelimiter;
char *fileResultHeader;
char *fileResultName;

char *sqlCreate;
char *sqlDrop;
char *sqlInsert;
char *sqlSelect;

#define CONF_STR_CP(_field, _var)                            \
  (strcmp(_field, key) == 0)                                 \
  {                                                          \
    _var = (char *)malloc((strlen(val) + 1) * sizeof(char)); \
    strcpy(_var, val);                                       \
  }

#define CONF_INT_CP(_field, _var) (strcmp(_field, key) == 0) _var = atoi(val);

void load_config(const char *file)
{
  FILE *fp = fopen(file, "r");
  if (fp == NULL)
  {
    L("ERROR: Unable to open config file %s\n", file);
    exit(-1);
  }

  char ch = getc(fp);
  char key[256];
  char val[1024];
  char *keyp = key;
  char *valp = NULL;

  while (ch != EOF)
  {
    if (ch == ' ' && !valp)
    {
      // skip white spaces
    }
    else if (ch != '=' && !valp)
    {
      if (ch != '\r' && ch != '\n')
      {
        *keyp = ch;
        keyp++;
      }
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
      if
        CONF_STR_CP("connection.host", connectionHost)
      else if
        CONF_INT_CP("connection.port", connectionPort)
      else if
        CONF_STR_CP("connection.user", connectionUser)
      else if
        CONF_STR_CP("connection.password", connectionPassword)
      else if
        CONF_INT_CP("benchmark.batch.size", benchmarkBatchSize)
      else if
        CONF_STR_CP("benchmark.comment", benchmarkComment)
      else if
        CONF_INT_CP("benchmark.core.multiplier", benchmarkCoreMultiplier)
      else if
        CONF_STR_CP("benchmark.database", benchmarkDatabase)
      else if
        CONF_STR_CP("benchmark.host.name", benchmarkHostName)
      else if
        CONF_STR_CP("benchmark.id", benchmarkId)
      else if
        CONF_INT_CP("benchmark.number.cores", benchmarkNumberCores)
      else if
        CONF_INT_CP("benchmark.number.partitions", benchmarkNumberPartitions)
      else if
        CONF_STR_CP("benchmark.os", benchmarkOs)
      else if
        CONF_INT_CP("benchmark.transaction.size", benchmarkTransactionSize)
      else if
        CONF_INT_CP("benchmark.trials", benchmarkTrials)
      else if
        CONF_STR_CP("benchmark.user.name", benchmarkUserName)
      else if
        CONF_INT_CP("connection.fetch.size", connectionFetchSize)
      else if
        CONF_STR_CP("connection.host", connectionHost)
      else if
        CONF_STR_CP("connection.password", connectionPassword)
      else if
        CONF_INT_CP("connection.port", connectionPort)
      else if
        CONF_STR_CP("connection.service", connectionService)
      else if
        CONF_STR_CP("connection.user", connectionUser)
      else if
        CONF_STR_CP("file.bulk.delimiter", fileBulkDelimiter)
      else if
        CONF_STR_CP("file.bulk.header", fileBulkHeader)
      else if
        CONF_INT_CP("file.bulk.length", fileBulkLength)
      else if
        CONF_STR_CP("file.bulk.name", fileBulkName)
      else if
        CONF_INT_CP("file.bulk.size", fileBulkSize)
      else if
        CONF_STR_CP("file.configuration.name", fileConfigurationName)
      else if
        CONF_STR_CP("file.result.delimiter", fileResultDelimiter)
      else if
        CONF_STR_CP("file.result.header", fileResultHeader)
      else if
        CONF_STR_CP("file.result.name", fileResultName)
      else if
        CONF_STR_CP("sql.create", sqlCreate)
      else if
        CONF_STR_CP("sql.drop", sqlDrop)
      else if
        CONF_STR_CP("sql.insert", sqlInsert)
      else if
        CONF_STR_CP("sql.select", sqlSelect)
    }
    ch = getc(fp);
  }

  fclose(fp);
}