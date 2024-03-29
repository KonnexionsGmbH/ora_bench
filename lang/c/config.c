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
char *benchmarkRelease;
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

#define CONF_STR_CP(_var)                                    \
  (strcmp(#_var, key) == 0)                                  \
  {                                                          \
    _var = (char *)malloc((strlen(val) + 1) * sizeof(char)); \
    strcpy(_var, val);                                       \
  }

#define CONF_INT_CP(_var) (strcmp(#_var, key) == 0) _var = atoi(val);

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
        CONF_STR_CP(connectionHost)
      else if
        CONF_INT_CP(connectionPort)
      else if
        CONF_STR_CP(connectionUser)
      else if
        CONF_STR_CP(connectionPassword)
      else if
        CONF_INT_CP(benchmarkBatchSize)
      else if
        CONF_STR_CP(benchmarkComment)
      else if
        CONF_INT_CP(benchmarkCoreMultiplier)
      else if
        CONF_STR_CP(benchmarkDatabase)
      else if
        CONF_STR_CP(benchmarkHostName)
      else if
        CONF_STR_CP(benchmarkId)
      else if
        CONF_INT_CP(benchmarkNumberCores)
      else if
        CONF_INT_CP(benchmarkNumberPartitions)
      else if
        CONF_STR_CP(benchmarkOs)
      else if
        CONF_STR_CP(benchmarkRelease)
      else if
        CONF_INT_CP(benchmarkTransactionSize)
      else if
        CONF_INT_CP(benchmarkTrials)
      else if
        CONF_STR_CP(benchmarkUserName)
      else if
        CONF_INT_CP(connectionFetchSize)
      else if
        CONF_STR_CP(connectionHost)
      else if
        CONF_STR_CP(connectionPassword)
      else if
        CONF_INT_CP(connectionPort)
      else if
        CONF_STR_CP(connectionService)
      else if
        CONF_STR_CP(connectionUser)
      else if
        CONF_STR_CP(fileBulkDelimiter)
      else if
        CONF_STR_CP(fileBulkHeader)
      else if
        CONF_INT_CP(fileBulkLength)
      else if
        CONF_STR_CP(fileBulkName)
      else if
        CONF_INT_CP(fileBulkSize)
      else if
        CONF_STR_CP(fileConfigurationName)
      else if
        CONF_STR_CP(fileResultDelimiter)
      else if
        CONF_STR_CP(fileResultHeader)
      else if
        CONF_STR_CP(fileResultName)
      else if
        CONF_STR_CP(sqlCreate)
      else if
        CONF_STR_CP(sqlDrop)
      else if
        CONF_STR_CP(sqlInsert)
      else if
        CONF_STR_CP(sqlSelect)
    }
    ch = getc(fp);
  }

  fclose(fp);
}

struct partition *gBulk = NULL;
void load_bulk(const char *file)
{
  FILE *fp = fopen(file, "r");
  if (fp == NULL)
  {
    L("ERROR: Unable to open bulk file %s\n", file);
    exit(-1);
  }

  if (gBulk)
    free(gBulk);
  gBulk = (struct partition *)calloc(
      benchmarkNumberPartitions, sizeof(struct partition));

  struct row *rows = (struct row *)calloc(
      fileBulkSize, sizeof(struct row));
  struct row r, *row;
  if (fscanf(fp, "%[^;];%[^\r\n]\r\n", r.key, r.data) < 2)
  {
    L("ERROR bad bulk file. expected 2 input items at first(header) row\n");
    exit(-1);
  };
  row = rows;
  L("Loading(%%).");
  while (fscanf(fp, "%[^;];%[^\r\n]\r\n", row->key, row->data) != EOF)
  {
    row->partition = (row->key[0] * 251 + row->key[1]) % benchmarkNumberPartitions;
    gBulk[row->partition].count++;
    row++;
  }
  for (int i = 0; i < benchmarkNumberPartitions; ++i)
    gBulk[i].rows = (struct row *)malloc(
        gBulk[i].count * sizeof(struct row));
  int rowIdx = 0;
  struct partition *p;
  while (rowIdx < fileBulkSize)
  {
    row = rows + rowIdx;
    p = &gBulk[row->partition];
    memcpy(p->rows + p->rowIdx, row, sizeof(struct row));
    p->rowIdx++;
    rowIdx++;
    if (rowIdx % 5000 == 0)
    {
      printf("..%d", rowIdx * 100 / fileBulkSize);
      fflush(stdout);
    }
  }
  printf("...finished\n");
  free(rows);

  for (int i = 0; i < benchmarkNumberPartitions; ++i)
    L("Partition %d contains %d rows\n", i + 1, gBulk[i].count);
  fflush(stdout);

  fclose(fp);
}
