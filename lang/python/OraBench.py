import configparser
import csv
import cx_Oracle
import datetime
import locale
import logging
import logging.config
import os
import sys
import threading
import yaml
from pathlib import Path

# ----------------------------------------------------------------------------------
# Definition of the global variables.
# ----------------------------------------------------------------------------------

FILE_CONFIGURATION_NAME_PYTHON = "priv/properties/ora_bench_python.properties"

IX_BENCHMARK_DRIVER = 6
IX_BENCHMARK_LANGUAGE = 6
IX_DURATION_INSERT_SUM = 3
IX_DURATION_SELECT_SUM = 4
IX_LAST_BENCHMARK = 0
IX_LAST_QUERY = 2
IX_LAST_TRIAL = 1


# ----------------------------------------------------------------------------------
# Creating the database objects connection and cursor.
# ----------------------------------------------------------------------------------

def create_database_objects(logger,
                            config):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    connections = list()
    cursors = list()

    for _ in range(0,
                   config["benchmark.number.partitions"]):
        try:
            connection = cx_Oracle.connect(config["connection.user"],
                                           config["connection.password"],
                                           config["connection.host"] + ":" + str(config["connection.port"]) + "/" + config["connection.service"])
            connection.autocommit = False
        except cx_Oracle.DatabaseError as reason:
            logger.info("connection.host    =" + config["connection.host"])
            logger.info("connection.port    =" + str(config["connection.port"]))
            logger.info("connection.service =" + config["connection.service"])
            logger.info("connection.user    =" + config["connection.user"])
            logger.info("connection.password=" + config["connection.password"])
            sys.exit("database connect error: " + str(reason))

        connections.append(connection)
        cursors.append(connection.cursor())

    connections_cursors = (connections, cursors)

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return connections_cursors


# ----------------------------------------------------------------------------------
# Writing the results.
# ----------------------------------------------------------------------------------

def create_result(logger,
                  action,
                  benchmark_globals,
                  config,
                  result_file,
                  sql_operation,
                  sql_statement,
                  start_date_time,
                  trial_number):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    global IX_BENCHMARK_DRIVER
    global IX_BENCHMARK_LANGUAGE
    global IX_DURATION_INSERT_SUM
    global IX_DURATION_SELECT_SUM

    end_date_time = datetime.datetime.now()

    duration_ns = (end_date_time - start_date_time).total_seconds() * 1000000000

    if sql_operation == "insert":
        benchmark_globals[IX_DURATION_INSERT_SUM] += duration_ns
    elif sql_operation == "select":
        benchmark_globals[IX_DURATION_SELECT_SUM] += duration_ns

    result_file.write(config["benchmark.release"] + config["file.result.delimiter"] +
                      config["benchmark.id"] + config["file.result.delimiter"] +
                      config["benchmark.comment"] + config["file.result.delimiter"] +
                      config["benchmark.host.name"] + config["file.result.delimiter"] +
                      str(config["benchmark.number.cores"]) + config["file.result.delimiter"] +
                      config["benchmark.os"] + config["file.result.delimiter"] +
                      config["benchmark.user.name"] + config["file.result.delimiter"] +
                      config["benchmark.database"] + config["file.result.delimiter"] +
                      benchmark_globals[IX_BENCHMARK_LANGUAGE] + config["file.result.delimiter"] +
                      benchmark_globals[IX_BENCHMARK_DRIVER] + config["file.result.delimiter"] +
                      str(trial_number) + config["file.result.delimiter"] +
                      sql_statement + config["file.result.delimiter"] +
                      str(config["benchmark.core.multiplier"]) + config["file.result.delimiter"] +
                      str(config["connection.fetch.size"]) + config["file.result.delimiter"] +
                      str(config["benchmark.transaction.size"]) + config["file.result.delimiter"] +
                      str(config["file.bulk.length"]) + config["file.result.delimiter"] +
                      str(config["file.bulk.size"]) + config["file.result.delimiter"] +
                      str(config["benchmark.batch.size"]) + config["file.result.delimiter"] +
                      action + config["file.result.delimiter"] +
                      start_date_time.strftime("%Y-%m-%d %H:%M:%S.%f000") + config["file.result.delimiter"] +
                      end_date_time.strftime("%Y-%m-%d %H:%M:%S.%f000") + config["file.result.delimiter"] +
                      str(round((end_date_time - start_date_time).total_seconds())) + config["file.result.delimiter"] +
                      str(round(duration_ns)) + "\n")

    if action == "trial":
        logger.info("Duration (ms) trial         : " + str(round(duration_ns / 1000000)))

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return duration_ns


# ----------------------------------------------------------------------------------
# Creating the result file.
# ----------------------------------------------------------------------------------

def create_result_file(logger,
                       config):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    result_file = Path(config["file.result.name"])

    if not result_file.is_file():
        logger.error("fatal error: program abort =====> result file '" + config["file.result.name"] + "' is missing <=====")
        sys.exit(1)

    result_file = open(os.path.abspath(config["file.result.name"]),
                       "a")

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return result_file


# ----------------------------------------------------------------------------------
# Recording the results of the benchmark - end processing.
# ----------------------------------------------------------------------------------

def create_result_measuring_point_end(logger,
                                      action,
                                      benchmark_globals,
                                      config,
                                      result_file,
                                      sql_operation="",
                                      sql_statement="",
                                      trial_number=0):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    global IX_LAST_BENCHMARK
    global IX_LAST_QUERY
    global IX_LAST_TRIAL

    if action == "query":
        duration_ns = create_result(logger,
                                    action,
                                    benchmark_globals,
                                    config,
                                    result_file,
                                    sql_operation,
                                    sql_statement,
                                    benchmark_globals[IX_LAST_QUERY],
                                    trial_number
                                    )
    elif action == "trial":
        duration_ns = create_result(logger,
                                    action,
                                    benchmark_globals,
                                    config,
                                    result_file,
                                    sql_operation,
                                    sql_statement,
                                    benchmark_globals[IX_LAST_TRIAL],
                                    trial_number
                                    )
    elif action == "benchmark":
        duration_ns = create_result(logger,
                                    action,
                                    benchmark_globals,
                                    config,
                                    result_file,
                                    sql_operation,
                                    sql_statement,
                                    benchmark_globals[IX_LAST_BENCHMARK],
                                    trial_number
                                    )
        result_file.close()
    else:
        logger.error("action='" + action + "' state=end")

        if logger.isEnabledFor(logging.DEBUG):
            logger.debug("End")

        sys.exit(1)

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return duration_ns


# ----------------------------------------------------------------------------------
# Recording the results of the benchmark - start processing.
# ----------------------------------------------------------------------------------

def create_result_measuring_point_start(logger,
                                        action,
                                        benchmark_globals):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    global IX_LAST_QUERY
    global IX_LAST_TRIAL

    if action == "query":
        benchmark_globals[IX_LAST_QUERY] = datetime.datetime.now()
    elif action == "trial":
        benchmark_globals[IX_LAST_TRIAL] = datetime.datetime.now()
    else:
        logger.error("Unknown action='" + action + "' state=start")
        sys.exit(1)

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return benchmark_globals


def create_result_measuring_point_start_benchmark(logger,
                                                  config):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    global IX_LAST_BENCHMARK

    benchmark_globals = [None, None, None, 0, 0, 0, 0, 0, None, None]

    benchmark_globals[IX_LAST_BENCHMARK] = datetime.datetime.now()

    benchmark_globals[IX_BENCHMARK_DRIVER] = "cx_Oracle (Version v" + cx_Oracle.version + ")"
    benchmark_globals[IX_BENCHMARK_LANGUAGE] = "Python 3 " + sys.version

    measurement_data_result_file = (benchmark_globals, create_result_file(logger,
                                                                          config))

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return measurement_data_result_file


# ----------------------------------------------------------------------------------
# Loading the bulk file into memory.
# ----------------------------------------------------------------------------------

def get_bulk_data_partitions(logger,
                             config):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    benchmark_number_partitions = config["benchmark.number.partitions"]
    file_bulk_delimiter = config["file.bulk.delimiter"]

    with open(os.path.abspath(config["file.bulk.name"])) as csv_file:
        bulk_data = [tuple(line) for line in csv.reader(csv_file,
                                                        delimiter=file_bulk_delimiter)]

    del bulk_data[0]

    bulk_data_partitions = [[] for _ in range(0,
                                              benchmark_number_partitions)]

    # ----------------------------------------------------------------------------------
    # Loading the bulk file into memory.
    # ----------------------------------------------------------------------------------

    for key_data_tuple in bulk_data:
        key = key_data_tuple[0]
        partition_key = (ord(key[0]) * 251 + ord(key[1])) % benchmark_number_partitions
        bulk_data_partition = bulk_data_partitions[partition_key]
        bulk_data_partition.append([key_data_tuple])
        bulk_data_partitions[partition_key] = bulk_data_partition

    logger.info("Start Distribution of the data in the partitions")

    for partition_key in range(0,
                               benchmark_number_partitions):
        logger.info("Partition p" + "{:0>5d}".format(partition_key) + " contains " + "{0:n}".format(len(bulk_data_partitions[partition_key])) + " rows")

    logger.info("End   Distribution of the data in the partitions")

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return bulk_data_partitions


# ----------------------------------------------------------------------------------
# Loading the configuration parameters into memory.
# ----------------------------------------------------------------------------------

def get_config(logger):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    global FILE_CONFIGURATION_NAME_PYTHON

    config_parser = configparser.ConfigParser()
    config_parser.read(FILE_CONFIGURATION_NAME_PYTHON)

    config = dict()

    config["benchmark.batch.size"] = int(config_parser["DEFAULT"]["benchmark.batch.size"])
    config["benchmark.comment"] = config_parser["DEFAULT"]["benchmark.comment"]
    config["benchmark.core.multiplier"] = int(config_parser["DEFAULT"]["benchmark.core.multiplier"])
    config["benchmark.database"] = config_parser["DEFAULT"]["benchmark.database"]
    config["benchmark.host.name"] = config_parser["DEFAULT"]["benchmark.host.name"]
    config["benchmark.id"] = config_parser["DEFAULT"]["benchmark.id"]
    config["benchmark.number.cores"] = int(config_parser["DEFAULT"]["benchmark.number.cores"])
    config["benchmark.number.partitions"] = int(config_parser["DEFAULT"]["benchmark.number.partitions"])
    config["benchmark.os"] = config_parser["DEFAULT"]["benchmark.os"]
    config["benchmark.release"] = config_parser["DEFAULT"]["benchmark.release"]
    config["benchmark.transaction.size"] = int(config_parser["DEFAULT"]["benchmark.transaction.size"])
    config["benchmark.trials"] = int(config_parser["DEFAULT"]["benchmark.trials"])
    config["benchmark.user.name"] = config_parser["DEFAULT"]["benchmark.user.name"]

    config["connection.fetch.size"] = int(config_parser["DEFAULT"]["connection.fetch.size"])
    config["connection.host"] = config_parser["DEFAULT"]["connection.host"]
    config["connection.password"] = config_parser["DEFAULT"]["connection.password"]
    config["connection.port"] = int(config_parser["DEFAULT"]["connection.port"])
    config["connection.service"] = config_parser["DEFAULT"]["connection.service"]
    config["connection.user"] = config_parser["DEFAULT"]["connection.user"]

    config["file.bulk.delimiter"] = str(config_parser["DEFAULT"]["file.bulk.delimiter"]).replace("TAB",
                                                                                                 "\t")
    config["file.bulk.length"] = int(config_parser["DEFAULT"]["file.bulk.length"])
    config["file.bulk.name"] = config_parser["DEFAULT"]["file.bulk.name"]
    config["file.bulk.size"] = int(config_parser["DEFAULT"]["file.bulk.size"])
    config["file.configuration.name.python"] = config_parser["DEFAULT"]["file.configuration.name.python"]
    config["file.result.delimiter"] = str(config_parser["DEFAULT"]["file.result.delimiter"]).replace("TAB",
                                                                                                     "\t")
    config["file.result.name"] = config_parser["DEFAULT"]["file.result.name"]

    config["sql.create"] = config_parser["DEFAULT"]["sql.create"]
    config["sql.drop"] = config_parser["DEFAULT"]["sql.drop"]
    config["sql.insert"] = config_parser["DEFAULT"]["sql.insert"].replace(":key",
                                                                          ":1").replace(":data",
                                                                                        ":2")
    config["sql.select"] = config_parser["DEFAULT"]["sql.select"]

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return config


# ----------------------------------------------------------------------------------
# Main routine.
# ----------------------------------------------------------------------------------

def main():
    with open("lang/python/logging.yaml",
              "r") as f:
        log_config = yaml.safe_load(f.read())

    logging.config.dictConfig(log_config)

    logger = logging.getLogger("OraBench.py")
    logger.setLevel(logging.DEBUG)

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    logger.info("Start OraBench.py")

    locale.setlocale(locale.LC_ALL,
                     "de_CH.utf8")

    run_benchmark(logger)

    logger.info("End   OraBench.py")

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")


# ----------------------------------------------------------------------------------
# Performing a complete benchmark run that can consist of several trial runs.
# ----------------------------------------------------------------------------------

def run_benchmark(logger):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    # READ the configuration parameters into the memory (config params `file.configuration.name ...`)
    config = get_config(logger)

    # save the current time as the start time of the "benchmark" action
    measurement_data_result_file = create_result_measuring_point_start_benchmark(logger,
                                                                                 config)

    benchmark_globals = measurement_data_result_file[0]
    result_file = measurement_data_result_file[1]

    # READ the bulk file data into the partitioned collection bulk_data_partitions (config param "file.bulk.name")
    bulk_data_partitions = get_bulk_data_partitions(logger,
                                                    config)

    connections_cursors = create_database_objects(logger,
                                                  config)

    connections = connections_cursors[0]
    cursors = connections_cursors[1]

    # trial_max = 0
    # trial_min = 0
    # trial_no = 0
    # trial_sum = 0
    # WHILE trial_no < config_param 'benchmark.trials'
    #       duration_trial = DO run_trial(database connections,
    #                                     trial_no,
    #                                     bulk_data_partitions)
    #       IF trial_max == 0 OR duration_trial > trial_max
    #          trial_max = duration_trial
    #       END IF
    #       IF trial_min == 0 OR duration_trial < trial_min
    #          trial_min = duration_trial
    #       END IF
    #       trial_sum + duration_trial
    # ENDWHILE
    benchmark_trials = config["benchmark.trials"]
    sql_create = config["sql.create"]
    sql_drop = config["sql.drop"]
    trial_max = 0
    trial_min = 0
    trial_sum = 0

    for trial_number in range(0,
                              benchmark_trials):
        duration_ns_trial = run_trial(logger,
                                      benchmark_globals,
                                      bulk_data_partitions,
                                      config,
                                      connections,
                                      cursors,
                                      result_file,
                                      sql_create,
                                      sql_drop,
                                      trial_number + 1)

        if trial_max == 0 or trial_max < duration_ns_trial:
            trial_max = duration_ns_trial

        if trial_min == 0 or trial_min > duration_ns_trial:
            trial_min = duration_ns_trial

        trial_sum += duration_ns_trial

    # partition_key = 0
    # WHILE partition_key < config_param "benchmark.number.partitions"
    #       close the database connection
    # ENDWHILE
    for cursor in cursors:
        cursor.close()

    for connection in connections:
        connection.close()

    # WRITE an entry for the action "benchmark" in the result file (config param "file.result.name")
    duration_ns_benchmark = create_result_measuring_point_end(logger,
                                                              "benchmark",
                                                              benchmark_globals,
                                                              config,
                                                              result_file)

    # INFO  Duration (ms) trial min.    : trial_min
    # INFO  Duration (ms) trial max.    : trial_max
    # INFO  Duration (ms) trial average : trial_sum / config_param 'benchmark.trials'
    logger.info("Duration (ms) trial min.    : " + str(round(trial_min / 1000000)))
    logger.info("Duration (ms) trial max.    : " + str(round(trial_max / 1000000)))
    logger.info("Duration (ms) trial average : " + str(round(trial_sum / 1000000 / benchmark_trials)))

    # INFO  Duration (ms) benchmark run : duration_benchmark
    logger.info("Duration (ms) benchmark run : " + str(round(duration_ns_benchmark / 1000000)))

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")


# ----------------------------------------------------------------------------------
# Supervise function for inserting data into the database.
# ----------------------------------------------------------------------------------

def run_insert(logger,
               benchmark_batch_size,
               benchmark_core_multiplier,
               benchmark_globals,
               benchmark_number_partitions,
               benchmark_transaction_size,
               bulk_data_partitions,
               config,
               connections,
               cursors,
               result_file,
               sql_insert,
               trial_number):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    # save the current time as the start time of the "query" action
    benchmark_globals = create_result_measuring_point_start(logger,
                                                            "query",
                                                            benchmark_globals)

    # partition_key = 0
    # WHILE partition_key < config_param "benchmark.number.partitions"
    #     IF config_param "benchmark.core.multiplier" = 0
    #        DO run_insert_helper(database connections(partition_key),
    #                             bulk_data_partitions(partition_key),
    #                             partition_key)
    #     ELSE
    #        DO run_insert_helper (database connections(partition_key),
    #                              bulk_data_partitions(partition_key),
    #                              partition_key) as a thread
    #     ENDIF
    # ENDWHILE
    threads = list()

    for partition_key in range(0,
                               benchmark_number_partitions):
        if benchmark_core_multiplier == 0:
            run_insert_helper(logger,
                              benchmark_batch_size,
                              benchmark_transaction_size,
                              bulk_data_partitions[partition_key],
                              connections[partition_key],
                              cursors[partition_key],
                              partition_key,
                              sql_insert,
                              trial_number)
        else:
            thread = threading.Thread(target=run_insert_helper,
                                      args=(
                                              logger, benchmark_batch_size, benchmark_transaction_size,
                                              bulk_data_partitions[partition_key],
                                              connections[partition_key],
                                              cursors[partition_key], partition_key, sql_insert, trial_number))
            threads.append(thread)
            thread.start()

    if benchmark_core_multiplier > 0:
        for thread in threads:
            thread.join()

    # WRITE an entry for the action "query" in the result file (config param "file.result.name")
    create_result_measuring_point_end(logger,
                                      "query",
                                      benchmark_globals,
                                      config,
                                      result_file,
                                      "insert",
                                      sql_insert,
                                      trial_number)

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return benchmark_globals


# ----------------------------------------------------------------------------------
# Helper function for inserting data into the database.
# ----------------------------------------------------------------------------------

def run_insert_helper(logger,
                      benchmark_batch_size,
                      benchmark_transaction_size,
                      bulk_data_partition,
                      connection,
                      cursor,
                      partition_key,
                      sql_insert,
                      trial_number):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    # IF trial_no == 1
    #    INFO Start insert partition_key=partition_key
    # ENDIF
    if trial_number == 1:
        logger.info("Start insert partition_key=" + str(partition_key))

    # count = 0
    # collection batch_collection = empty
    # WHILE iterating through the collection bulk_data_partition
    #       count + 1
    #
    #       add the SQL statement in config param "sql.insert" with the current bulk_data entry to the collection batch_collection
    #
    #       IF config_param "benchmark.batch.size" > 0
    #          IF count modulo config param "benchmark.batch.size" = 0
    #             execute the SQL statements in the collection batch_collection
    #             batch_collection = empty
    #          ENDIF
    #       ENDIF
    #
    #       IF  config param "benchmark.transaction.size" > 0
    #       AND count modulo config param "benchmark.transaction.size" = 0
    #           commit
    #       ENDIF
    # ENDWHILE
    count = 0
    batch_data = list()

    for [key_data_tuple] in bulk_data_partition:
        count += 1

        if benchmark_batch_size == 1:
            cursor.execute(sql_insert,
                           [key_data_tuple[0], key_data_tuple[1]])
        else:
            batch_data.append(key_data_tuple)
            if benchmark_batch_size > 0 and count % benchmark_batch_size == 0:
                cursor.executemany(sql_insert,
                                   batch_data)
                batch_data = list()

        if benchmark_transaction_size > 0 and count % benchmark_transaction_size == 0:
            connection.commit()

    # IF collection batch_collection is not empty
    #    execute the SQL statements in the collection batch_collection
    # ENDIF
    if benchmark_batch_size == 0 or batch_data.__len__() > 0:
        cursor.executemany(sql_insert,
                           batch_data)

    connection.commit()

    # IF trial_no == 1
    #    INFO End   insert partition_key=partition_key
    # ENDIF
    if trial_number == 1:
        logger.info("End   insert partition_ley=" + str(partition_key))

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")


# ----------------------------------------------------------------------------------
# Supervise function for retrieving of the database data.
# ----------------------------------------------------------------------------------

def run_select(logger,
               benchmark_core_multiplier,
               benchmark_globals,
               benchmark_number_partitions,
               bulk_data_partitions,
               config,
               cursors,
               result_file,
               sql_select,
               trial_number):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    # save the current time as the start time of the "query" action
    benchmark_globals = create_result_measuring_point_start(logger,
                                                            "query",
                                                            benchmark_globals)

    # partition_key = 0
    # WHILE partition_key < config_param "benchmark.number.partitions"
    #       IF config_param "benchmark.core.multiplier" = 0
    #          DO run_select_helper(database connections(partition_key),
    #                               bulk_data_partitions(partition_key,
    #                               partition_key)
    #       ELSE
    #          DO run_select_helper(database connections(partition_key),
    #                               bulk_data_partitions(partition_key,
    #                               partition_key) as a thread
    #       ENDIF
    # ENDWHILE
    threads = list()

    for partition_key in range(0,
                               benchmark_number_partitions):
        if benchmark_core_multiplier == 0:
            run_select_helper(logger,
                              bulk_data_partitions[partition_key],
                              cursors[partition_key],
                              partition_key,
                              sql_select,
                              trial_number)
        else:
            thread = threading.Thread(target=run_select_helper,
                                      args=(logger, bulk_data_partitions[partition_key], cursors[partition_key], partition_key,
                                            sql_select, trial_number))
            threads.append(thread)
            thread.start()

    if benchmark_core_multiplier > 0:
        for thread in threads:
            thread.join()

    # WRITE an entry for the action "query" in the result file (config param "file.result.name")
    create_result_measuring_point_end(logger,
                                      "query",
                                      benchmark_globals,
                                      config,
                                      result_file,
                                      "select",
                                      sql_select,
                                      trial_number)

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return benchmark_globals


# ----------------------------------------------------------------------------------
# Helper function for retrieving data from the database.
# ----------------------------------------------------------------------------------

def run_select_helper(logger,
                      bulk_size_partition,
                      cursor,
                      partition_key,
                      sql_statement,
                      trial_number):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    # IF trial_no == 1
    #    INFO Start select partition_key=partition_key
    # ENDIF
    if trial_number == 1:
        logger.info("Start select partition_key=" + str(partition_key))

    # execute the SQL statement in config param "sql.select"
    cursor.execute(sql_statement + " where partition_key = " + str(partition_key))

    # int count = 0;
    # WHILE iterating through the result set
    #       count + 1
    # ENDWHILE
    count = 0

    for _ in cursor:
        count += 1

    # IF NOT count = size(bulk_data_partition)
    #    display an error message
    # ENDIF
    if count != len(bulk_size_partition):
        logger.error("Number rows: expected=" + str(len(bulk_size_partition)) + " - found=" + str(count))
        sys.exit(1)

    # IF trial_no == 1
    #    INFO End   insert partition_key=partition_key
    # ENDIF
    if trial_number == 1:
        logger.info("End   select partition_ley=" + str(partition_key))

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")


# ----------------------------------------------------------------------------------
# Performing a single trial run..
# ----------------------------------------------------------------------------------

def run_trial(logger,
              benchmark_globals,
              bulk_data_partitions,
              config,
              connections,
              cursors,
              result_file,
              sql_create,
              sql_drop,
              trial_number):
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("Start")

    # save the current time as the start time of the "trial" action
    benchmark_globals = create_result_measuring_point_start(logger,
                                                            "trial",
                                                            benchmark_globals)

    # INFO  Start trial no. trial_no
    logger.info("Start trial no. " + str(trial_number))

    # create the database table (config param "sql.create")
    # IF error
    #    drop the database table (config param "sql.drop")
    #    create the database table (config param "sql.create")
    # ENDIF
    try:
        cursors[0].execute(sql_create)
        logger.debug("last DDL statement=" + sql_create)
    except cx_Oracle.DatabaseError:
        cursors[0].execute(sql_drop)
        cursors[0].execute(sql_create)
        logger.debug("last DDL statement after DROP=" + sql_create)

    benchmark_core_multiplier = config["benchmark.core.multiplier"]
    benchmark_number_partitions = config["benchmark.number.partitions"]

    # DO run_insert(database connections,
    #               trial_no,
    #               bulk_data_partitions)
    run_insert(logger,
               config["benchmark.batch.size"],
               benchmark_core_multiplier,
               benchmark_globals,
               benchmark_number_partitions,
               config["benchmark.transaction.size"],
               bulk_data_partitions,
               config,
               connections,
               cursors,
               result_file,
               config["sql.insert"],
               trial_number)

    # DO run_select(database connections,
    #               trial_no,
    #               bulk_data_partitions)
    run_select(logger,
               benchmark_core_multiplier,
               benchmark_globals,
               benchmark_number_partitions,
               bulk_data_partitions,
               config,
               cursors,
               result_file,
               config["sql.select"],
               trial_number)

    # drop the database table (config param "sql.drop")
    cursors[0].execute(sql_drop)
    logger.debug("last DDL statement=" + sql_drop)

    # RITE an entry for the action "trial" in the result file (config param "file.result.name")
    duration_ns = create_result_measuring_point_end(logger,
                                                    "trial",
                                                    benchmark_globals,
                                                    config,
                                                    result_file,
                                                    "",
                                                    "",
                                                    trial_number)

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("End")

    return duration_ns


# ----------------------------------------------------------------------------------
# Program start.
# ----------------------------------------------------------------------------------

main()
