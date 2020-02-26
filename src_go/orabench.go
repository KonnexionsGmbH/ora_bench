package main

import (
	"bufio"
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
  "strings"
  "strconv"

	godror "github.com/godror/godror"
	errors "golang.org/x/xerrors"
)

type row struct {	key, val string }

func main() {
  confs := load_config(os.Args[1])
	dsn := "oracle://" +
    confs["connection.user"].(string) +
		":" + confs["connection.password"].(string)  +
		"@" + confs["connection.host"].(string)  +
		":" + fmt.Sprintf("%v", confs["connection.port"])  +
		"/" + confs["connection.service"].(string)
	sqlStrDrop := confs["sql.drop"].(string) 
	sqlStrCreate := confs["sql.create"].(string) 
	sqlStrInsert := confs["sql.insert"].(string) 
	sqlStrSelect := confs["sql.select"].(string) 
	benchmarkNumberPartitions := confs["benchmark.number.partitions"].(int)
  
  partitions := load_bulk(
    benchmarkNumberPartitions,
    confs["file.bulk.name"].(string),
    confs["file.bulk.delimiter"].(string))

  log.Printf("partitions %d, partitions[0] %d, partitions[1] %d\n", len(partitions), len(partitions[0]), len(partitions[1]))

	log.Println("dsn:", dsn)
	log.Println("sqlStrInsert:", sqlStrInsert)
	log.Println("sqlStrSelect:", sqlStrSelect)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	db, err := sql.Open("godror", dsn)
	if err != nil {
		log.Fatal(errors.Errorf("%s: %w", dsn, err))

	}
	defer db.Close()

	resultDrop, err := db.ExecContext(ctx, sqlStrDrop)
	if err != nil {
		log.Println(errors.Errorf("%s -> %w", sqlStrDrop, err))
	}
	log.Println("DROP", sqlStrDrop, resultDrop)

	resultCreate, err := db.ExecContext(ctx, sqlStrCreate)
	if err != nil {
		log.Fatal(errors.Errorf("%s -> %w", sqlStrCreate, err))
	}
	log.Println("CRAETE", sqlStrCreate, resultCreate)

	stmt, err := db.PrepareContext(ctx, "SELECT 1, 'test' FROM dual")
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()
	rows, err := stmt.Query()
	for rows.Next() {
		var num int
		var str string
		if err := rows.Scan(&num, &str); err != nil {
			log.Fatal(err)
		}
		fmt.Printf("num is %d, str is %s\n", num, str)
	}
	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	oraDB, err := godror.DriverConn(ctx, db)
	if err != nil {
		log.Fatal(errors.Errorf("%s: %w", dsn, err))
	}
	log.Println("Connected!!!!")
	oraDB.Shutdown(godror.ShutdownFinal)
}

func load_bulk(benchmarkNumberPartitions int, fileBulkName string, fileBulkDelimiter string) [][]row {
	partitions := make([][]row, benchmarkNumberPartitions)

	bulkFile, err := os.Open(fileBulkName)
	if err != nil { log.Fatal(err) }
	defer bulkFile.Close()

	scanner := bufio.NewScanner(bulkFile)
	for scanner.Scan() {
    parts := strings.Split(scanner.Text(), fileBulkDelimiter)
    partition := (int(parts[0][0]) * 256 + int(parts[0][1])) % benchmarkNumberPartitions
    partitions[partition] = append(partitions[partition], row{parts[0], parts[1]})
	}

  if err := scanner.Err(); err != nil {	log.Fatal(err) }
  
  return partitions
}

func load_config(configFile string) map[string]interface{} {
	configurations := make(map[string]interface{})

	confFile, err := os.Open(configFile)
	if err != nil { log.Fatal(err) }
	defer confFile.Close()

	scanner := bufio.NewScanner(confFile)
	for scanner.Scan() {
    parts := strings.Split(scanner.Text(), "=")
    if len(parts) > 1 {
      if n, err := strconv.Atoi(parts[1]); err == nil {
        configurations[parts[0]] = n
      } else {
        configurations[parts[0]] = parts[1]
      }
    }
  }

  if err := scanner.Err(); err != nil {	log.Fatal(err) }
  
  return configurations
}
