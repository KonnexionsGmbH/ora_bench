import configparser
import csv
import datetime
import locale
import logging
import os
import platform
import sys
import threading
from pathlib import Path

import cx_Oracle

# ------------------------------------------------------------------------------
# Definition of the global variables.
# ------------------------------------------------------------------------------

BENCHMARK_DRIVER = 'cx_Oracle (Version v' + cx_Oracle.version + ')'
BENCHMARK_MODULE = 'OraBench (Python ' + platform.python_version() + ')'

FILE_CONFIGURATION_NAME_CX_ORACLE_PYTHON = 'priv/properties/ora_bench_cx_oracle_python.ini'

IX_DURATION_INSERT_SUM = 3
IX_DURATION_SELECT_SUM = 4
IX_LAST_BENCHMARK = 0
IX_LAST_QUERY = 2
IX_LAST_TRIAL = 1


# ------------------------------------------------------------------------------
# Creating the database objects connection and cursor.
# ------------------------------------------------------------------------------

def create_database_objects(config):
    connections = list()
    cursors = list()

    for i in range(0, config['benchmark.number.partitions']):
        connection = cx_Oracle.connect(config['connection.user'], config['connection.password'],
                                       config['connection.host'] + ':' + str(config['connection.port']) + '/' + config['connection.service'])
        connection.autocommit = False

        connections.append(connection)
        cursors.append(connection.cursor())

    connections_cursors = (connections, cursors)

    return connections_cursors


# ------------------------------------------------------------------------------
# Writing the results.
# ------------------------------------------------------------------------------

def create_result(config, result_file, measurement_data, action, trial_number, sql_statement, start_date_time, sql_operation):
    global IX_DURATION_INSERT_SUM
    global IX_DURATION_SELECT_SUM

    end_date_time = datetime.datetime.now()

    duration_ns = (end_date_time - start_date_time).total_seconds() * 100000000

    if sql_operation == 'insert':
        measurement_data[IX_DURATION_INSERT_SUM] += duration_ns
    elif sql_operation == 'select':
        measurement_data[IX_DURATION_SELECT_SUM] += duration_ns

    result_file.write(config['benchmark.id'] + config['file.result.delimiter'] +
                      config['benchmark.comment'] + config['file.result.delimiter'] +
                      config['benchmark.host.name'] + config['file.result.delimiter'] +
                      str(config['benchmark.number.cores']) + config['file.result.delimiter'] +
                      config['benchmark.os'] + config['file.result.delimiter'] +
                      config['benchmark.user.name'] + config['file.result.delimiter'] +
                      config['benchmark.database'] + config['file.result.delimiter'] +
                      BENCHMARK_MODULE + config['file.result.delimiter'] +
                      BENCHMARK_DRIVER + config['file.result.delimiter'] +
                      str(trial_number) + config['file.result.delimiter'] +
                      sql_statement + config['file.result.delimiter'] +
                      str(config['benchmark.core.multiplier']) + config['file.result.delimiter'] +
                      str(config['connection.fetch.size']) + config['file.result.delimiter'] +
                      str(config['benchmark.transaction.size']) + config['file.result.delimiter'] +
                      str(config['file.bulk.length']) + config['file.result.delimiter'] +
                      str(config['file.bulk.size']) + config['file.result.delimiter'] +
                      str(config['benchmark.batch.size']) + config['file.result.delimiter'] +
                      action + config['file.result.delimiter'] +
                      start_date_time.strftime('%Y-%m-%d %H:%M:%S.%f000') + config['file.result.delimiter'] +
                      end_date_time.strftime('%Y-%m-%d %H:%M:%S.%f000') + config['file.result.delimiter'] +
                      str(round((end_date_time - start_date_time).total_seconds())) + config['file.result.delimiter'] +
                      str(round(duration_ns)) + '\n')


# ------------------------------------------------------------------------------
# Creating the result file.
# ------------------------------------------------------------------------------

def create_result_file(config):
    result_file = Path(config['file.result.name'])

    if not result_file.is_file():
        result_file = open(os.path.abspath(config['file.result.name']), 'w')
        result_file.write(config['file.result.header'].replace(';', config['file.result.delimiter']) + '\n')
        result_file.close()

    result_file = open(os.path.abspath(config['file.result.name']), 'a')

    return result_file


# ------------------------------------------------------------------------------
# Recording the results of the benchmark - end processing.
# ------------------------------------------------------------------------------

def create_result_measuring_point_end(config, result_file, measurement_data, action, trial_number=0, sql_statement='', sql_operation=''):
    global IX_LAST_BENCHMARK
    global IX_LAST_QUERY
    global IX_LAST_TRIAL

    if action == 'query':
        create_result(config, result_file, measurement_data, action, trial_number, sql_statement, measurement_data[IX_LAST_QUERY], sql_operation)
    elif action == 'trial':
        create_result(config, result_file, measurement_data, action, trial_number, sql_statement, measurement_data[IX_LAST_TRIAL], sql_operation)
    elif action == 'benchmark':
        create_result(config, result_file, measurement_data, action, trial_number, sql_statement, measurement_data[IX_LAST_BENCHMARK], sql_operation)
        result_file.close()
    else:
        logging.error('action="' + action + '"' + ' state="end"')
        sys.exit(1)


# ------------------------------------------------------------------------------
# Recording the results of the benchmark - start processing.
# ------------------------------------------------------------------------------

def create_result_measuring_point_start(measurement_data, action):
    global IX_LAST_QUERY
    global IX_LAST_TRIAL

    if action == 'query':
        measurement_data[IX_LAST_QUERY] = datetime.datetime.now()
    elif action == 'trial':
        measurement_data[IX_LAST_TRIAL] = datetime.datetime.now()
    else:
        logging.error('Unknown action="' + action + '"' + ' state="start"')
        sys.exit(1)

    return measurement_data


def create_result_measuring_point_start_benchmark(config):
    global IX_LAST_BENCHMARK

    measurement_data = [None, None, None, 0, 0]

    measurement_data[IX_LAST_BENCHMARK] = datetime.datetime.now()

    result_file = create_result_file(config)

    measurement_data_result_file = (measurement_data, result_file)

    return measurement_data_result_file


# ------------------------------------------------------------------------------
# Loading the bulk file into memory.
# ------------------------------------------------------------------------------

def get_bulk_data_partitions(config):
    with open(os.path.abspath(config['file.bulk.name'])) as csv_file:
        bulk_data = [tuple(line) for line in csv.reader(csv_file, delimiter=config['file.bulk.delimiter'])]

    del bulk_data[0]

    bulk_data_partitions = [[] for _ in range(config['benchmark.number.partitions'])]

    for key_data_tuple in bulk_data:
        key = key_data_tuple[0]
        partition_key = (ord(key[0]) * 256 + ord(key[1])) % config['benchmark.number.partitions']
        bulk_data_partition = bulk_data_partitions[partition_key]
        # noinspection PyTypeChecker
        bulk_data_partition.append(key_data_tuple)
        bulk_data_partitions[partition_key] = bulk_data_partition

    logging.info('Start Distribution of the data in the partitions')

    for partition_key in range(0, config['benchmark.number.partitions'] - 1):
        logging.info('Partition p' + '{:0>5d}'.format(partition_key) + ' contains ' + '{0:n}'.format(len(bulk_data_partitions[partition_key])) + ' rows')

    logging.info('End   Distribution of the data in the partitions')

    return bulk_data_partitions


# ------------------------------------------------------------------------------
# Loading the configuration parameters into memory.
# ------------------------------------------------------------------------------

def get_config():
    global FILE_CONFIGURATION_NAME_CX_ORACLE_PYTHON

    config_parser = configparser.ConfigParser()
    config_parser.read(FILE_CONFIGURATION_NAME_CX_ORACLE_PYTHON)

    config = dict()

    config['benchmark.batch.size'] = int(config_parser['DEFAULT']['benchmark.batch.size'])
    config['benchmark.comment'] = config_parser['DEFAULT']['benchmark.comment']
    config['benchmark.core.multiplier'] = int(config_parser['DEFAULT']['benchmark.core.multiplier'])
    config['benchmark.database'] = config_parser['DEFAULT']['benchmark.database']
    config['benchmark.host.name'] = config_parser['DEFAULT']['benchmark.host.name']
    config['benchmark.id'] = config_parser['DEFAULT']['benchmark.id']
    config['benchmark.number.cores'] = int(config_parser['DEFAULT']['benchmark.number.cores'])
    config['benchmark.number.partitions'] = int(config_parser['DEFAULT']['benchmark.number.partitions'])
    config['benchmark.os'] = config_parser['DEFAULT']['benchmark.os']
    config['benchmark.transaction.size'] = int(config_parser['DEFAULT']['benchmark.transaction.size'])
    config['benchmark.trials'] = int(config_parser['DEFAULT']['benchmark.trials'])
    config['benchmark.user.name'] = config_parser['DEFAULT']['benchmark.user.name']

    config['connection.fetch.size'] = int(config_parser['DEFAULT']['connection.fetch.size'])
    config['connection.host'] = config_parser['DEFAULT']['connection.host']
    config['connection.password'] = config_parser['DEFAULT']['connection.password']
    config['connection.port'] = int(config_parser['DEFAULT']['connection.port'])
    config['connection.service'] = config_parser['DEFAULT']['connection.service']
    config['connection.user'] = config_parser['DEFAULT']['connection.user']

    config['file.bulk.delimiter'] = str(config_parser['DEFAULT']['file.bulk.delimiter']).replace('TAB', '\t')
    config['file.bulk.length'] = int(config_parser['DEFAULT']['file.bulk.length'])
    config['file.bulk.name'] = config_parser['DEFAULT']['file.bulk.name']
    config['file.bulk.size'] = int(config_parser['DEFAULT']['file.bulk.size'])
    config['file.configuration.name.cx_oracle.python'] = config_parser['DEFAULT']['file.configuration.name.cx_oracle.python']
    config['file.result.delimiter'] = str(config_parser['DEFAULT']['file.result.delimiter']).replace('TAB', '\t')
    config['file.result.header'] = config_parser['DEFAULT']['file.result.header']
    config['file.result.name'] = config_parser['DEFAULT']['file.result.name']

    config['sql.create'] = config_parser['DEFAULT']['sql.create']
    config['sql.drop'] = config_parser['DEFAULT']['sql.drop']
    config['sql.insert'] = config_parser['DEFAULT']['sql.insert'].replace(':key', ':1').replace(':data', ':2')
    config['sql.select'] = config_parser['DEFAULT']['sql.select']

    return config


# ------------------------------------------------------------------------------
# Performing the insert operations.
# ------------------------------------------------------------------------------

def insert(config, connection, cursor, bulk_data_partition):
    count = 0
    batch_data = list()

    for key_data_tuple in bulk_data_partition:
        count += 1

        if config['benchmark.batch.size'] == 0:
            cursor.execute(config['sql.insert'], [key_data_tuple[0], key_data_tuple[1]])
        else:
            batch_data.append(key_data_tuple)
            if count % config['benchmark.batch.size'] == 0:
                cursor.executemany(config['sql.insert'], batch_data)
                batch_data = list()

        if config['benchmark.transaction.size'] > 0 and count % config['benchmark.transaction.size'] == 0:
            connection.commit()

    if config['benchmark.batch.size'] > 0 and batch_data.__len__() > 0:
        cursor.executemany(config['sql.insert'], batch_data)

    if config['benchmark.transaction.size'] == 0 or count % config['benchmark.transaction.size'] != 0:
        connection.commit()


# ------------------------------------------------------------------------------
# Main routine.
# ------------------------------------------------------------------------------

def main():
    logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
    logging.info('Start OraBench.py')

    locale.setlocale(locale.LC_ALL, 'de_DE')

    run_benchmark()

    logging.info('End   OraBench.py')


# ------------------------------------------------------------------------------
# Performing the benchmark run.
# ------------------------------------------------------------------------------

def run_benchmark():
    config = get_config()

    measurement_data_result_file = create_result_measuring_point_start_benchmark(config)

    measurement_data = measurement_data_result_file[0]
    result_file = measurement_data_result_file[1]

    bulk_data_partitions = get_bulk_data_partitions(config)

    connections_cursors = create_database_objects(config)

    connections = connections_cursors[0]
    cursors = connections_cursors[1]

    for trial_number in range(1, config['benchmark.trials']):
        run_trial(config, connections, cursors, bulk_data_partitions, measurement_data, result_file, trial_number)

    for cursor in cursors:
        cursor.close()

    for connection in connections:
        connection.close()

    create_result_measuring_point_end(config, result_file, measurement_data, 'benchmark')


# ------------------------------------------------------------------------------
# Performing the insert operations.
# ------------------------------------------------------------------------------

def run_insert(config, connections, cursors, bulk_data_partitions, result_file, measurement_data, trial_number):
    measurement_data = create_result_measuring_point_start(measurement_data, 'query')

    threads = list()

    for partition_key in range(0, config['benchmark.number.partitions'] - 1):
        if config['benchmark.core.multiplier'] == 0:
            insert(config, connections[partition_key], cursors[partition_key], bulk_data_partitions[partition_key])
        else:
            thread = threading.Thread(target=insert, args=(config, connections[partition_key], cursors[partition_key], bulk_data_partitions[partition_key],))
            threads.append(thread)
            thread.start()

    if config['benchmark.core.multiplier'] > 0:
        for thread in threads:
            thread.join()

    create_result_measuring_point_end(config, result_file, measurement_data, 'query', trial_number, config['sql.insert'], 'insert')

    return measurement_data


# ------------------------------------------------------------------------------
# Performing the select operations.
# ------------------------------------------------------------------------------

def run_select(config, cursors, bulk_data_partitions, result_file, measurement_data, trial_number):
    measurement_data = create_result_measuring_point_start(measurement_data, 'query')

    threads = list()

    for partition_key in range(0, config['benchmark.number.partitions'] - 1):
        if config['benchmark.core.multiplier'] == 0:
            select(cursors[partition_key], bulk_data_partitions[partition_key], partition_key, config['sql.select'])
        else:
            thread = threading.Thread(target=select, args=(cursors[partition_key], bulk_data_partitions[partition_key], partition_key, config['sql.select'],))
            threads.append(thread)
            thread.start()

    if config['benchmark.core.multiplier'] > 0:
        for thread in threads:
            thread.join()

    create_result_measuring_point_end(config, result_file, measurement_data, 'query', trial_number, config['sql.select'], 'select')

    return measurement_data


# ------------------------------------------------------------------------------
# Performing one trial.
# ------------------------------------------------------------------------------

def run_trial(config, connections, cursors, bulk_data_partitions, measurement_data, result_file, trial_number):
    measurement_data = create_result_measuring_point_start(measurement_data, 'trial')

    logging.info('Start trial no. ' + str(trial_number))

    try:
        cursors[0].execute(config['sql.create'])
        logging.debug('last DDL statement=' + config['sql.create'])
    except cx_Oracle.DatabaseError:
        cursors[0].execute(config['sql.drop'])
        cursors[0].execute(config['sql.create'])
        logging.debug('last DDL statement after DROP=' + config['sql.create'])

    run_insert(config, connections, cursors, bulk_data_partitions, result_file, measurement_data, trial_number)

    run_select(config, cursors, bulk_data_partitions, result_file, measurement_data, trial_number)

    cursors[0].execute(config['sql.drop'])
    logging.debug('last DDL statement=' + config['sql.drop'])

    create_result_measuring_point_end(config, result_file, measurement_data, 'trial', trial_number)

    return measurement_data


# ------------------------------------------------------------------------------
# Performing the select operations.
# ------------------------------------------------------------------------------

def select(cursor, bulk_size_partition, partition_key, sql_statement):
    count = 0

    cursor.execute(sql_statement + ' where partition_key = ' + str(partition_key))

    for _ in cursor:
        count += 1

    if count != len(bulk_size_partition):
        logging.error('Number rows: expected=' + str(len(bulk_size_partition)) + ' - found=' + str(count))
        sys.exit(1)


# ------------------------------------------------------------------------------
# Program start.
# ------------------------------------------------------------------------------

main()
