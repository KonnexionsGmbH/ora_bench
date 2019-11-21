import configparser
import csv
import datetime
import logging
import os
import platform
from pathlib import Path

import cx_Oracle

# ------------------------------------------------------------------------------
# Definition of the global variables.
# ------------------------------------------------------------------------------

benchmark_batch_size = None
benchmark_comment = None
benchmark_database = None
BENCHMARK_DRIVER = 'cx_Oracle (Version v' + cx_Oracle.version + ')'
BENCHMARK_ENVIRONMENT = platform.machine() + ' / ' + platform.platform()
BENCHMARK_MODULE = 'OraBench (Python ' + platform.python_version() + ')'
benchmark_transaction_size = None
benchmark_trials = None
bulk_data = None

connection = None
connection_host = None
connection_password = None
connection_pool_size = None
connection_port = None
connection_service = None
connection_user = None
cursor = None

duration_insert_maximum = 0
duration_insert_minimum = 0
duration_insert_sum = 0
duration_select_maximum = 0
duration_select_minimum = 0
duration_select_sum = 0

end_date_time = None

file_bulk_delimiter = None
file_bulk_length = None
file_bulk_name = None
file_bulk_size = None
file_configuration_name_cx_oracle_python = None
file_result_detailed_delimiter = None
file_result_detailed_header = None
file_result_detailed_name = None

last_benchmark = None
last_query = None
last_trial = None

result_file_detailed = None

sql_create = None
sql_drop = None
sql_insert = None
sql_select = None


# ------------------------------------------------------------------------------
# Recording the results of the benchmark.
# ------------------------------------------------------------------------------

def create_result(action, state, trial_number, sql_statement, sql_operation=None):
    global last_benchmark
    global last_query
    global last_trial

    global result_file_detailed

    if state == 'start':
        if action == 'query':
            last_query = datetime.datetime.now()
            return
        if action == 'trial':
            last_trial = datetime.datetime.now()
            return
        if action == 'benchmark':
            last_benchmark = datetime.datetime.now()
            create_result_detailed_file()
            return

    if state != 'end':
        logging.error('action="' + action + '"' + ' state="' + state + '"')
        return

    if action == 'query':
        create_result_detailed(action, trial_number, sql_statement, last_query, sql_operation)
        return
    if action == 'trial':
        create_result_detailed(action, trial_number, sql_statement, last_trial, sql_operation)
        return
    if action == 'benchmark':
        create_result_detailed(action, trial_number, sql_statement, last_benchmark, sql_operation)
        result_file_detailed.close()
        return

    logging.error('action="' + action + '"' + ' state="' + state + '"')


# ------------------------------------------------------------------------------
# writing the detailed results.
# ------------------------------------------------------------------------------

def create_result_detailed(action, trial_number, sql_statement, start_date_time, sql_operation):
    global benchmark_batch_size
    global benchmark_comment
    global benchmark_database
    global BENCHMARK_ENVIRONMENT
    global BENCHMARK_MODULE
    global BENCHMARK_DRIVER
    global benchmark_transaction_size
    global benchmark_trials

    global connection_host
    global connection_password
    global connection_pool_size
    global connection_port
    global connection_service
    global connection_user

    global duration_insert_maximum
    global duration_insert_minimum
    global duration_insert_sum
    global duration_select_maximum
    global duration_select_minimum
    global duration_select_sum

    global end_date_time

    global file_bulk_length
    global file_bulk_size
    global file_result_detailed_delimiter

    global result_file_detailed

    end_date_time = datetime.datetime.now()

    duration_ns = (end_date_time - start_date_time).total_seconds() * 100000000

    if sql_operation == 'insert':
        duration_insert_sum += duration_ns
        if duration_insert_maximum == 0:
            duration_insert_maximum = duration_ns
            duration_insert_minimum = duration_ns
        else:
            if duration_ns < duration_insert_minimum:
                duration_insert_minimum = duration_ns
            if duration_ns > duration_insert_maximum:
                duration_insert_maximum = duration_ns
    elif sql_operation == 'select':
        duration_select_sum += duration_ns
        if duration_select_maximum == 0:
            duration_select_maximum = duration_ns
            duration_select_minimum = duration_ns
        else:
            if duration_ns < duration_select_minimum:
                duration_select_minimum = duration_ns
            if duration_ns > duration_select_maximum:
                duration_select_maximum = duration_ns

    result_file_detailed.write(benchmark_comment + file_result_detailed_delimiter +
                               BENCHMARK_ENVIRONMENT + file_result_detailed_delimiter + benchmark_database +
                               file_result_detailed_delimiter + BENCHMARK_MODULE + file_result_detailed_delimiter +
                               BENCHMARK_DRIVER + file_result_detailed_delimiter +
                               str(trial_number) + file_result_detailed_delimiter +
                               sql_statement + file_result_detailed_delimiter +
                               str(connection_pool_size) + file_result_detailed_delimiter +
                               str(benchmark_transaction_size) + file_result_detailed_delimiter +
                               str(file_bulk_length) + file_result_detailed_delimiter +
                               str(file_bulk_size) + file_result_detailed_delimiter +
                               str(benchmark_batch_size) + file_result_detailed_delimiter +
                               action + file_result_detailed_delimiter +
                               start_date_time.strftime('%Y.%m.%d %H:%M:%S.%f000') + file_result_detailed_delimiter +
                               end_date_time.strftime('%Y.%m.%d %H:%M:%S.%f000') + file_result_detailed_delimiter +
                               str(round((end_date_time - start_date_time).total_seconds())) + file_result_detailed_delimiter +
                               str(round(duration_ns)) + file_result_detailed_delimiter +
                               '\n')


# ------------------------------------------------------------------------------
# Creating the detailed result file.
# ------------------------------------------------------------------------------

def create_result_detailed_file():
    global file_result_detailed_delimiter
    global file_result_detailed_header
    global file_result_detailed_name

    global result_file_detailed

    result_file_detailed = Path(file_result_detailed_name)

    if not result_file_detailed.is_file():
        result_file_detailed = open(os.path.abspath(file_result_detailed_name), 'w')
        result_file_detailed.write(file_result_detailed_header.replace(';', file_result_detailed_delimiter) + '\n')
        result_file_detailed.close()

    result_file_detailed = open(os.path.abspath(file_result_detailed_name), 'a')


# ------------------------------------------------------------------------------
# Loading the bulk file into memory.
# ------------------------------------------------------------------------------

def get_bulk_data():
    global bulk_data

    with open(os.path.abspath(file_bulk_name)) as csv_file:
        bulk_data = [tuple(line) for line in csv.reader(csv_file, delimiter=file_bulk_delimiter)]

    del bulk_data[0]


# ------------------------------------------------------------------------------
# Loading the configuration parameters into memory.
# ------------------------------------------------------------------------------

def get_config():
    global benchmark_batch_size
    global benchmark_comment
    global benchmark_database
    global benchmark_transaction_size
    global benchmark_trials
    global bulk_data

    global connection_host
    global connection_password
    global connection_pool_size
    global connection_port
    global connection_service
    global connection_user

    global file_bulk_delimiter
    global file_bulk_length
    global file_bulk_name
    global file_bulk_size
    global file_configuration_name_cx_oracle_python
    global file_result_detailed_delimiter
    global file_result_detailed_header
    global file_result_detailed_name

    global sql_create
    global sql_drop
    global sql_insert
    global sql_select

    config = configparser.ConfigParser()
    config.read('priv/properties/ora_bench_cx_oracle_python.ini')

    benchmark_batch_size = int(config['DEFAULT']['benchmark.batch.size'])
    benchmark_comment = config['DEFAULT']['benchmark.comment']
    benchmark_database = config['DEFAULT']['benchmark.database']
    benchmark_transaction_size = int(config['DEFAULT']['benchmark.transaction.size'])
    benchmark_trials = int(config['DEFAULT']['benchmark.trials'])

    connection_host = config['DEFAULT']['connection.host']
    connection_password = config['DEFAULT']['connection.password']
    connection_pool_size = int(config['DEFAULT']['connection.pool.size'])
    connection_port = int(config['DEFAULT']['connection.port'])
    connection_service = config['DEFAULT']['connection.service']
    connection_user = config['DEFAULT']['connection.user']

    file_bulk_delimiter = str(config['DEFAULT']['file.bulk.delimiter']).replace('TAB', '\t')
    file_bulk_length = int(config['DEFAULT']['file.bulk.length'])
    file_bulk_name = config['DEFAULT']['file.bulk.name']
    file_bulk_size = int(config['DEFAULT']['file.bulk.size'])
    file_configuration_name_cx_oracle_python = config['DEFAULT']['file.configuration.name.cx_oracle.python']
    file_result_detailed_delimiter = str(config['DEFAULT']['file.result.detailed.delimiter']).replace('TAB', '\t')
    file_result_detailed_header = config['DEFAULT']['file.result.detailed.header']
    file_result_detailed_name = config['DEFAULT']['file.result.detailed.name']

    sql_create = config['DEFAULT']['sql.create']
    sql_drop = config['DEFAULT']['sql.drop']
    sql_insert = config['DEFAULT']['sql.insert'].replace(':key', ':1').replace(':data', ':2')
    sql_select = config['DEFAULT']['sql.select']


# ------------------------------------------------------------------------------
# Main routine.
# ------------------------------------------------------------------------------

def main():
    logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.DEBUG)
    logging.info('Start OraBench.py')

    get_config()

    run_benchmark()

    logging.info('End   OraBench.py')


# ------------------------------------------------------------------------------
# Performing the benchmark run.
# ------------------------------------------------------------------------------

def run_benchmark():
    global benchmark_trials

    global connection
    global connection_host
    global connection_password
    global connection_port
    global connection_service
    global connection_user

    create_result('benchmark', 'start', 0, '')

    get_bulk_data()

    connection = cx_Oracle.connect(connection_user, connection_password, connection_host + ':' + str(connection_port) + '/' + connection_service)

    connection.autocommit = False

    for trial_number in range(1, benchmark_trials + 1):
        run_benchmark_trial(trial_number)

    connection.close()

    create_result('benchmark', 'end', 0, '')


# ------------------------------------------------------------------------------
# Performing the insert operations.
# ------------------------------------------------------------------------------

def run_benchmark_insert(trial_number):
    global benchmark_batch_size
    global benchmark_transaction_size
    global bulk_data
    global sql_insert

    create_result('query', 'start', trial_number, sql_insert)

    count = 0
    batch_data = []

    for key_data_tuple in bulk_data:
        count += 1

        if benchmark_transaction_size == 0:
            cursor.execute(sql_insert, [key_data_tuple[1], key_data_tuple[2]])
        else:
            batch_data.append(key_data_tuple)
            if count % benchmark_batch_size == 0:
                cursor.executemany(sql_insert, batch_data)
                batch_data = []

        if benchmark_transaction_size > 0 and count % benchmark_transaction_size == 0:
            connection.commit()

    if benchmark_transaction_size > 0 and batch_data.__len__() > 0:
        cursor.executemany(sql_insert, batch_data)

    if benchmark_transaction_size > 0 and count % benchmark_transaction_size == 0:
        connection.commit()

    create_result('query', 'end', trial_number, sql_insert, 'insert')


# ------------------------------------------------------------------------------
# Performing the select operations.
# ------------------------------------------------------------------------------

def run_benchmark_select(trial_number):
    global benchmark_batch_size
    global bulk_data
    global sql_select

    create_result('query', 'start', trial_number, sql_select)

    cursor.prepare(sql_select)

    for tuple in bulk_data:
        key, data = tuple
        cursor.execute(None, key=key)
        [(result,)] = cursor.fetchall()
        if result != data:
            logging.error('expected=' + data)
            logging.error('found   =' + result)

    create_result('query', 'end', trial_number, sql_select, 'select')


# ------------------------------------------------------------------------------
# Performing one trial.
# ------------------------------------------------------------------------------

def run_benchmark_trial(trial_number):
    global cursor

    create_result('trial', 'start', trial_number, '')
    logging.info('Start trial no. ' + str(trial_number))

    cursor = connection.cursor()

    try:
        cursor.execute(sql_create)
    except cx_Oracle.DatabaseError:
        cursor.execute(sql_drop)
        cursor.execute(sql_create)

    run_benchmark_insert(trial_number)
    run_benchmark_select(trial_number)

    cursor.execute(sql_drop)

    create_result('trial', 'end', trial_number, '')


# ------------------------------------------------------------------------------
# Program start.
# ------------------------------------------------------------------------------

main()
