defmodule OraBench do
  require Logger

  # @benchmark_driver  "jamdb_oracle (Version v#{Jamdb.Oracle.version_info()}})"
  @benchmark_driver  "jamdb_oracle (Version v0.3.6})"
  @benchmark_module "OraBench (Elixir #{System.version()})"

  @file_configuration_name  "priv/properties/ora_bench.properties"

  @moduledoc false

  # ----------------------------------------------------------------------------------------------
  # Creating the database objects of type connection.
  # ----------------------------------------------------------------------------------------------

  defp create_database_objects(config) do
    Logger.debug("Start ==========> <==========")

    case config["benchmark.core.multiplier"] do
      "0" ->
        case Jamdb.Oracle.start_link(jamdb_oracle_config(config)) do
          {:ok, conn} ->
            Map.new([{1, conn}])
          _ = other_reason ->
            raise(
              "[Error in create_database_objects] Jamdb.Oracle.start_list: reason=#{
                other_reason
              }"
            )
        end
      _ ->
        Enum.reduce(
          1..String.to_integer(config["benchmark.number.partitions"]),
          %{},
          fn (i, connections) ->
            case Jamdb.Oracle.start_link(jamdb_oracle_config(config)) do
              {:ok, conn} -> Map.put(connections, i, conn)
              _ = other_reason ->
                raise(
                  "[Error in create_database_objects] Jamdb.Oracle.start_list: reason=#{
                    other_reason
                  }"
                )
            end
          end
        )
    end
  end

  # ----------------------------------------------------------------------------------------------
  # Writing the results.
  # ----------------------------------------------------------------------------------------------

  defp create_result(
         action,
         config,
         measurement_data,
         result_file,
         sql_operation,
         sql_statement,
         start_date_time,
         trial_number
       ) do
    Logger.debug("Start ==========> action: #{action} <==========")

    end_date_time = DateTime.utc_now()

    duration_ns = DateTime.diff(end_date_time, start_date_time, :nanosecond)
    duration_ss = DateTime.diff(end_date_time, start_date_time, :second)

    measurement_data_end = case sql_operation do
      "insert" ->
        Map.put(
          measurement_data,
          :duration_insert_sum,
          measurement_data[:duration_insert_sum] + duration_ns
        )
      "select" ->
        Map.put(
          measurement_data,
          :duration_select_sum,
          measurement_data[:duration_select_sum] + duration_ns
        )
      _ -> measurement_data
    end
    #    IO.inspect(measurement_data_end, label: "measurement_data_end")

    :ok = IO.puts(
      result_file,
      [
        config["benchmark.id"],
        config["file.result.delimiter"],
        config["benchmark.comment"],
        config["file.result.delimiter"],
        config["benchmark.host.name"],
        config["file.result.delimiter"],
        config["benchmark.number.cores"],
        config["file.result.delimiter"],
        config["benchmark.os"],
        config["file.result.delimiter"],
        config["benchmark.user.name"],
        config["file.result.delimiter"],
        config["benchmark.database"],
        config["file.result.delimiter"],
        @benchmark_module,
        config["file.result.delimiter"],
        @benchmark_driver,
        config["file.result.delimiter"],
        Integer.to_string(trial_number),
        config["file.result.delimiter"],
        sql_statement,
        config["file.result.delimiter"],
        config["benchmark.core.multiplier"],
        config["file.result.delimiter"],
        config["connection.fetch.size"],
        config["file.result.delimiter"],
        config["benchmark.transaction.size"],
        config["file.result.delimiter"],
        config["file.bulk.length"],
        config["file.result.delimiter"],
        config["file.bulk.size"],
        config["file.result.delimiter"],
        config["benchmark.batch.size"],
        config["file.result.delimiter"],
        action,
        config["file.result.delimiter"],
        String.replace(
          Calendar.ISO.datetime_to_string(
            start_date_time.year,
            start_date_time.month,
            start_date_time.day,
            start_date_time.hour,
            start_date_time.minute,
            start_date_time.second,
            start_date_time.microsecond,
            start_date_time.time_zone,
            start_date_time.zone_abbr,
            start_date_time.utc_offset,
            start_date_time.std_offset
          ),
          "Z",
          "000"
        ),
        config["file.result.delimiter"],
        String.replace(
          Calendar.ISO.datetime_to_string(
            end_date_time.year,
            end_date_time.month,
            end_date_time.day,
            end_date_time.hour,
            end_date_time.minute,
            end_date_time.second,
            end_date_time.microsecond,
            end_date_time.time_zone,
            end_date_time.zone_abbr,
            end_date_time.utc_offset,
            end_date_time.std_offset
          ),
          "Z",
          "000"
        ),
        config["file.result.delimiter"],
        Integer.to_string(duration_ss),
        config["file.result.delimiter"],
        Integer.to_string(round(duration_ns))
      ]
    )

    measurement_data_end
  end

  # ----------------------------------------------------------------------------------------------
  # Creating the result file.
  # ----------------------------------------------------------------------------------------------

  defp create_result_file(config) do
    Logger.debug("Start ==========> <==========")

    result_file_name = Path.expand(
                         ~s(../../#{config["file.result.name"]})
                       )
                       |> Path.absname

    case File.exists?(result_file_name) do
      true ->
        {:ok, file} = File.open(result_file_name, [:append])
        file
      _ ->
        {:ok, file} = File.open(result_file_name, [:write])
        :ok = IO.puts(
          file,
          String.replace(
            config["file.result.header"],
            ";",
            config["file.result.delimiter"]
          )
        )
        file
    end
  end

  # ----------------------------------------------------------------------------------------------
  # Recording the results of the benchmark - end processing.
  # ----------------------------------------------------------------------------------------------

  defp create_result_measuring_point_end(
         action,
         config,
         measurement_data,
         result_file,
         sql_operation,
         sql_statement,
         trial_number
       ) do
    Logger.debug("Start ==========> action: #{action} <==========")

    measurement_data_end = case action do
      "query" ->
        create_result(
          action,
          config,
          measurement_data,
          result_file,
          sql_operation,
          sql_statement,
          measurement_data[:last_query],
          trial_number
        )
      "trial" ->
        create_result(
          action,
          config,
          measurement_data,
          result_file,
          sql_operation,
          sql_statement,
          measurement_data[:last_trial],
          trial_number
        )
      "benchmark" ->
        create_result(
          action,
          config,
          measurement_data,
          result_file,
          sql_operation,
          sql_statement,
          measurement_data[:last_benchmark],
          trial_number
        )
        File.close(result_file)
      _ ->
        raise(
          "[Error in create_result_measuring_point_end] unknown action='#{
            action
          }'"
        )
    end
    #   IO.inspect(measurement_data_end, label: "measurement_data_end")

    measurement_data_end
  end

  # ----------------------------------------------------------------------------------------------
  # Recording the results of the benchmark - start processing.
  # ----------------------------------------------------------------------------------------------

  defp create_result_measuring_point_start(action, measurement_data) do
    Logger.debug("Start ==========> action: #{action} <==========")

    measurement_data_end = case action do
      "query" ->
        Map.put(measurement_data, :last_query, DateTime.utc_now())
      "trial" ->
        Map.put(measurement_data, :last_trial, DateTime.utc_now())
      _ ->
        raise(
          "[Error in create_result_measuring_point_start] unknown action='#{
            action
          }'"
        )
    end
    #    IO.inspect(measurement_data_end, label: "measurement_data_end")

    measurement_data_end
  end

  # ----------------------------------------------------------------------------------------------
  # Loading the bulk file into memory.
  # ----------------------------------------------------------------------------------------------

  defp get_bulk_data_partitions(config) do
    Logger.debug("Start ==========> <==========")

    Path.expand(~s(../../#{config["file.bulk.name"]}))
    |> Path.absname
    |> File.stream!()
    |> Stream.map(&(String.replace(&1, "\n", "")))
    |> Enum.reduce(
         %{},
         fn (line, bulk_data_partitions) ->
           case line == config["file.bulk.header"] do
             true ->
               bulk_data_partitions
             _ ->
               case String.split(line, config["file.bulk.delimiter"]) do
                 [key, data] ->
                   partition_key = rem(
                     (String.at(key, 0)
                      |> String.to_charlist()
                      |> hd) * 256 + (String.at(key, 1)
                                      |> String.to_charlist()
                                      |> hd),
                     String.to_integer(config["benchmark.number.partitions"])
                   )
                   case Map.has_key?(
                          bulk_data_partitions,
                          partition_key
                        ) do
                     true ->
                       Map.put(
                         bulk_data_partitions,
                         partition_key,
                         [
                           {key, data} | bulk_data_partitions[partition_key]
                         ]
                       )
                     _ ->
                       Map.put(
                         bulk_data_partitions,
                         partition_key,
                         [{key, data}]
                       )
                   end
                 _ ->
                   bulk_data_partitions
               end
           end
         end
       )
  end

  # ----------------------------------------------------------------------------------------------
  # Loading the configuration parameters into memory.
  # ----------------------------------------------------------------------------------------------

  defp get_config do
    Logger.debug("Start ==========> <==========")

    config = Path.expand("../../#{@file_configuration_name}")
             |> Path.absname
             |> File.stream!()
             |> Stream.map(&(String.replace(&1, "\n", "")))
             |> Enum.reduce(
                  %{},
                  fn (line, config) ->
                    case String.split(line, "=", [parts: 2]) do
                      [key, value] -> Map.put_new(config, key, value)
                      _ -> config
                    end
                  end
                )

    case config["file.result.delimiter"] do
      "\\t" -> Map.put(config, "file.result.delimiter", <<"\t">>)
      _ -> config
    end
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the insert operations.
  # ----------------------------------------------------------------------------------------------

  defp insert(
         _batch_data,
         _batch_size,
         [],
         _config,
         _connection,
         _count,
         _transaction_size
       ) do
    Logger.debug("Start ==========> final <==========")

    #    if batch_size > 0 and batch_data.__len__() > 0 do
    #      cursor.executemany(config["sql.insert"], batch_data)
    #
    #      if transaction_size == 0 or rem(count, transaction_size) != 0 do
    #        connection.commit()
    #      end
  end

  defp insert(
         [],
         0,
         [_key_data_tuple | tail] = _bulk_data_partition,
         config,
         connection,
         count,
         transaction_size
       ) do
    #    cursor.execute(config["sql.insert"], [key_data_tuple[0], key_data_tuple[1]])

    #    if transaction_size == 0 or rem(count, transaction_size) != 0 do
    #      connection.commit()

    insert([], 0, tail, config, connection, count + 1, transaction_size)
  end

  defp insert(
         batch_data,
         batch_size,
         [_key_data_tuple | tail] = _bulk_data_partition,
         config,
         connection,
         count,
         transaction_size
       ) do
    #    batch_data.append(key_data_tuple)
    #    if count % config["benchmark.batch.size"] == 0:
    #      cursor.executemany(config["sql.insert"], batch_data)
    #      batch_data = list()

    #    if transaction_size == 0 or rem(count, transaction_size) != 0 do
    #       connection.commit()

    insert(
      batch_data,
      batch_size,
      tail,
      config,
      connection,
      count + 1,
      transaction_size
    )
  end

  # ----------------------------------------------------------------------------------------------
  # Database configuration.
  # ----------------------------------------------------------------------------------------------

  defp jamdb_oracle_config(config)  do
    Logger.debug("Start ==========> <==========")

    [
      database: config["connection.service"],
      hostname: config["connection.host"],
      idle_interval: 1000000,
      parameters: [
        autocommit: false,
        fetch: String.to_integer(config["connection.fetch.size"])
      ],
      password: config["connection.password"],
      pool_size: case config["benchmark.core.multiplier"] do
        "0" -> String.to_integer(config["benchmark.number.partitions"])
        _ -> 1
      end,
      port: String.to_integer(config["connection.port"]),
      timeout: :infinity,
      username: config["connection.user"]
    ]
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the benchmark run - jamdb_oracle.
  # ----------------------------------------------------------------------------------------------

  def run_benchmark_jamdb_oracle do
    Logger.debug("Start ==========> <==========")

    config = get_config()
    #    IO.inspect(config, label: "config")

    measurement_data = %{
      :last_benchmark => DateTime.utc_now(),
      :last_trial => "n/a",
      :last_query => "n/a",
      :duration_insert_sum => 0,
      :duration_select_sum => 0
    }
    #    IO.inspect(measurement_data, label: "measurement_data")

    result_file = create_result_file(config)
    #    IO.inspect(result_file, label: "result_file")

    bulk_data_partitions = get_bulk_data_partitions(config)
    #   IO.inspect(bulk_data_partitions, label: "bulk_data_partitions")

    connections = create_database_objects(config)
    #    IO.inspect(connections, label: "connections")

    measurement_data_run_trial = run_trial(
      bulk_data_partitions,
      config,
      connections,
      measurement_data,
      result_file,
      String.to_integer(config["benchmark.trials"]),
      1
    )
    #    IO.inspect(measurement_data_run_trial, label: "measurement_data_run_trial")

    Enum.each(
      Map.values(connections),
      fn conn ->
        Process.exit(conn, :normal)
      end
    )

    create_result_measuring_point_end(
      "benchmark",
      config,
      measurement_data_run_trial,
      result_file,
      "",
      "",
      0
    )
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the insert operations.
  # ----------------------------------------------------------------------------------------------

  defp run_insert(
         _bulk_data_partitions,
         _config,
         _connections,
         measurement_data,
         0,
         _partition_key_current,
         _result_file,
         _trial_number
       ) do
    Logger.debug("Start ==========> final <==========")

    #    IO.inspect(measurement_data, label: "measurement_data - final")
    measurement_data
  end

  defp run_insert(
         bulk_data_partitions,
         config,
         connections,
         measurement_data,
         partition_key,
         partition_key_current,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key_current} <=========="
    )

    measurement_data_start = create_result_measuring_point_start(
      "query",
      measurement_data
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - partition key: #{partition_key_current}")

    case config["benchmark.core.multiplier"] do
      "0" ->
        insert(
          [],
          String.to_integer(config["benchmark.batch.size"]),
          bulk_data_partitions[partition_key - 1],
          config,
          connections[1],
          0,
          String.to_integer(config["benchmark.transaction.size"])
        )
      _ ->
        insert(
          [],
          String.to_integer(config["benchmark.batch.size"]),
          bulk_data_partitions[partition_key - 1],
          config,
          connections[partition_key],
          0,
          String.to_integer(config["benchmark.transaction.size"])
        )
    end

    measurement_data_end = create_result_measuring_point_end(
      "query",
      config,
      measurement_data_start,
      result_file,
      "insert",
      config["sql.insert"],
      trial_number
    )
    #    IO.inspect(measurement_data_end, label: "measurement_data_end - partition key: #{partition_key_current}")

    run_insert(
      bulk_data_partitions,
      config,
      connections,
      measurement_data_end,
      partition_key - 1,
      partition_key_current + 1,
      result_file,
      trial_number
    )
  end

  defp run_select(
         _bulk_data_partitions,
         _config,
         _connections,
         measurement_data,
         0,
         _partition_key_current,
         _result_file,
         _trial_number
       ) do
    Logger.debug("Start ==========> final <==========")

    #    IO.inspect(measurement_data, label: "measurement_data - final")
    measurement_data
  end

  defp run_select(
         bulk_data_partitions,
         config,
         connections,
         measurement_data,
         partition_key,
         partition_key_current,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key_current} <=========="
    )

    measurement_data_start = create_result_measuring_point_start(
      "query",
      measurement_data
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - partition key: #{partition_key_current}")

    case config["benchmark.core.multiplier"] do
      "0" ->
        select(
          bulk_data_partitions[partition_key - 1],
          connections[1],
          partition_key,
          config["sql.select"]
        )
      _ ->
        select(
          bulk_data_partitions[partition_key - 1],
          connections[partition_key],
          partition_key,
          config["sql.select"]
        )
    end

    measurement_data_end = create_result_measuring_point_end(
      "query",
      config,
      measurement_data_start,
      result_file,
      "select",
      config["sql.select"],
      trial_number
    )
    #    IO.inspect(measurement_data_end, label: "measurement_data_end - partition key: #{partition_key_current}")

    run_select(
      bulk_data_partitions,
      config,
      connections,
      measurement_data_end,
      partition_key - 1,
      partition_key_current + 1,
      result_file,
      trial_number
    )
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the trials.
  # ----------------------------------------------------------------------------------------------

  defp run_trial(
         _bulk_data_partitions,
         _config,
         _connections,
         measurement_data,
         _result_file,
         0,
         _trial_number_current
       ) do
    Logger.debug("Start ==========> final <==========")

    #    IO.inspect(measurement_data, label: "measurement_data - final")
    measurement_data
  end

  defp run_trial(
         bulk_data_partitions,
         config,
         connections,
         measurement_data,
         result_file,
         trial_number,
         trial_number_current
       ) do
    Logger.debug(
      "Start ==========> trial no.: #{trial_number_current} <=========="
    )

    measurement_data_start = create_result_measuring_point_start(
      "trial",
      measurement_data
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - trial no.: #{trial_number_current}")

    Logger.info("Start ==========> trial no. #{trial_number_current}")

    _sql_create = %Jamdb.Oracle.Query{statement: config["sql.create"]}
    _sql_drop = %Jamdb.Oracle.Query{statement: config["sql.drop"]}

    #    IO.inspect(connections, label: "connections")
    #    DBConnection.prepare_execute(connections[1], sql_create, [])
    #    |> IO.inspect()

    #    case DBConnection.prepare_execute(connections[1], sql_create, []) do
    #      {:ok, Result} ->
    #        Logger.info("wwe_011")
    #        DBConnection.close(connections[1], sql_create)
    #        Logger.debug(~s(last DDL statement=#{config["sql.create"]}))
    #      _ ->
    #        Logger.info("wwe_021")
    #        {:ok, Result} = DBConnection.prepare_execute(
    #          connections[1],
    #          sql_drop,
    #          []
    #        )
    #        DBConnection.close(connections[1], sql_drop)
    #        {:ok, Result} = DBConnection.prepare_execute(
    #          connections[1],
    #          sql_create,
    #          []
    #        )
    #        DBConnection.close(connections[1], sql_create)
    #        Logger.debug(~s(Last DDL statement after DROP=#{config["sql.create"]}))
    #    end

    measurement_data_insert = run_insert(
      bulk_data_partitions,
      config,
      connections,
      measurement_data_start,
      String.to_integer(config["benchmark.number.partitions"]),
      1,
      result_file,
      trial_number_current
    )
    #    IO.inspect(measurement_data_insert, label: "measurement_data_insert - trial no.: #{trial_number_current}")

    measurement_data_select = run_select(
      bulk_data_partitions,
      config,
      connections,
      measurement_data_insert,
      String.to_integer(config["benchmark.number.partitions"]),
      1,
      result_file,
      trial_number_current
    )
    #    IO.inspect(measurement_data_select, label: "measurement_data_select - trial no.: #{trial_number_current}")

    #    {:ok, Result} = DBConnection.prepare_execute(
    #      connections[1],
    #      sql_drop,
    #      []
    #    )
    #    DBConnection.close(connections[1], sql_drop)
    Logger.debug(~s(last DDL statement=#{config["sql.drop"]}))

    measurement_data_end = create_result_measuring_point_end(
      "trial",
      config,
      measurement_data_select,
      result_file,
      "",
      "",
      trial_number_current
    )
    #    IO.inspect(measurement_data_end, label: "measurement_data_end - trial no.: #{trial_number_current}")

    run_trial(
      bulk_data_partitions,
      config,
      connections,
      measurement_data_end,
      result_file,
      trial_number - 1,
      trial_number_current + 1
    )
  end


  # ----------------------------------------------------------------------------------------------
  # Performing the select operations.
  # ----------------------------------------------------------------------------------------------

  defp select(
         _bulk_size_partition,
         _connection,
         partition_key,
         _sql_statement
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key} <=========="
    )

    _count = 0
    #     cursor.execute(sql_statement + ' where partition_key = ' + str(partition_key))
    #
    #     for _ in cursor:
    #         count += 1
    #
    #     if count != len(bulk_size_partition):
    #         logging.error('Number rows: expected=' + str(len(bulk_size_partition)) + ' - found=' + str(count))
    #         sys.exit(1)

  end
end
