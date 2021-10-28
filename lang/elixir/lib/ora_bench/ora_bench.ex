defmodule OraBench do
  require Logger

  @benchmark_language "Elixir #{System.version()}"
  @dpi_major_version 3
  @dpi_minor_version 0
  @file_configuration_name  "../priv/properties/ora_bench.properties"

  @moduledoc false

  # ----------------------------------------------------------------------------------------------
  # Creating the database objects of type connection.
  # ----------------------------------------------------------------------------------------------

  defp create_database_objects(config, driver) do
    Logger.debug("Start ==========> <==========")

    connection_string = :erlang.iolist_to_binary(
      config["connection.host"] <> ":" <> config["connection.port"] <> "/" <> config["connection.service"]
    )
    password = :erlang.iolist_to_binary(config["connection.password"])
    user = :erlang.iolist_to_binary(config["connection.user"])

    case config["benchmark.core.multiplier"] do
      "0" ->
        Map.new(
          [
            {
              1,
              :dpi.conn_create(
                driver,
                user,
                password,
                connection_string,
                %{},
                %{}
              )
            }
          ]
        )
      _ ->
        Enum.reduce(
          1..String.to_integer(config["benchmark.number.partitions"]),
          %{},
          fn (i, connections) ->
            Map.put(
              connections,
              i,
              :dpi.conn_create(
                driver,
                user,
                password,
                connection_string,
                %{},
                %{}
              )
            )
          end
        )
    end
  end

  # ----------------------------------------------------------------------------------------------
  # Writing the results.
  # ----------------------------------------------------------------------------------------------

  defp create_result(
         action,
         benchmark_driver,
         config,
         measurement_data,
         result_file,
         sql_operation,
         sql_statement,
         start_date_time,
         end_date_time,
         trial_number
       ) do
    Logger.debug("Start ==========> action: #{action} <==========")

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
        config["benchmark.release"],
        config["file.result.delimiter"],
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
        @benchmark_language,
        config["file.result.delimiter"],
        benchmark_driver,
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
        Process.exit(self(), ~s(fatal error: program abort =====> result file ") <> result_file_name <> ~s(" is missing <=====))
    end
  end

  # ----------------------------------------------------------------------------------------------
  # Recording the results of the benchmark - end processing.
  # ----------------------------------------------------------------------------------------------

  defp create_result_measuring_point_end(
         action,
         benchmark_driver,
         config,
         measurement_data,
         result_file,
         sql_operation,
         sql_statement,
         trial_number,
         end_date_time
       ) do
    Logger.debug("Start ==========> action: #{action} <==========")

    measurement_data_end = case action do
      "query" ->
        create_result(
          action,
          benchmark_driver,
          config,
          measurement_data,
          result_file,
          sql_operation,
          sql_statement,
          measurement_data[:last_query],
          end_date_time,
          trial_number
        )
      "trial" ->
        create_result(
          action,
          benchmark_driver,
          config,
          measurement_data,
          result_file,
          sql_operation,
          sql_statement,
          measurement_data[:last_trial],
          end_date_time,
          trial_number
        )
      "benchmark" ->
        create_result(
          action,
          benchmark_driver,
          config,
          measurement_data,
          result_file,
          sql_operation,
          sql_statement,
          measurement_data[:last_benchmark],
          end_date_time,
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

  defp create_result_measuring_point_start(action, measurement_data, start_date_time) do
    Logger.debug("Start ==========> action: #{action} <==========")

    case action do
      "query" ->
        Map.put(measurement_data, :last_query, start_date_time)
      "trial" ->
        Map.put(measurement_data, :last_trial, start_date_time)
      _ ->
        raise(
          "[Error in create_result_measuring_point_start] unknown action='#{
            action
          }'"
        )
    end
  end

  # ----------------------------------------------------------------------------------------------
  # Loading the bulk file into memory.
  # ----------------------------------------------------------------------------------------------

  defp get_bulk_data_partitions(config) do
    Logger.debug("Start ==========> <==========")

    bulk_data_partitions = Path.expand(~s(../../#{config["file.bulk.name"]}))
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
                                      case String.split(
                                             line,
                                             config["file.bulk.delimiter"]
                                           ) do
                                        [key, data] ->
                                          partition_key = rem(
                                            (String.at(key, 0)
                                             |> String.to_charlist()
                                             |> hd) * 251 + (String.at(key, 1)
                                                             |> String.to_charlist()
                                                             |> hd),
                                            String.to_integer(
                                              config["benchmark.number.partitions"]
                                            )
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
                                                  {
                                                    key,
                                                    data
                                                  } | bulk_data_partitions[partition_key]
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


    Logger.info("Start Distribution of the data in the partitions")

    Enum.each(
      Map.keys(bulk_data_partitions),
      fn key ->
        Logger.info(
          "Partition p#{
            key
            |> Integer.to_string
            |> String.pad_leading(5, "0")
          } contains #{
            length(bulk_data_partitions[key])
            |> Integer.to_string
            |> String.pad_leading(9, " ")
          } rows"
        )
      end
    )

    Logger.info("End   Distribution of the data in the partitions")

    bulk_data_partitions
  end

  # ----------------------------------------------------------------------------------------------
  # Loading the configuration parameters into memory.
  # ----------------------------------------------------------------------------------------------

  defp get_config do
    Logger.debug("Start ==========> <==========")

    config = Path.expand("../#{@file_configuration_name}")
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
         _batch_size,
         [],
         _config,
         connection,
         _count,
         count_batch,
         statement,
         {_key_var, _data_var},
         _transaction_size
       ) do
    Logger.debug("Start ==========> final <==========")

    if count_batch > 0 do
      :ok = :dpi.stmt_executeMany(statement, [], count_batch)
    end

    :dpi.conn_commit(connection)
  end

  defp insert(
         batch_size,
         [{key, data} | tail] = _bulk_data_partition,
         config,
         connection,
         count,
         count_batch,
         statement,
         {key_var, data_var},
         transaction_size
       ) do
    :ok = :dpi.var_setFromBytes(key_var, count_batch, key)
    :ok = :dpi.var_setFromBytes(data_var, count_batch, data)

    count_curr = count + 1
    count_batch_curr = count_batch + 1

    count_batch_new = case count_batch_curr == batch_size do
      true -> :ok = :dpi.stmt_executeMany(statement, [], count_batch_curr)
              0
      _ -> count_batch_curr
    end

    if transaction_size > 0  do
      if rem(count_curr, transaction_size) == 0 do
        :dpi.conn_commit(connection)
      end
    end

    insert(
      batch_size,
      tail,
      config,
      connection,
      count_curr,
      count_batch_new,
      statement,
      {key_var, data_var},
      transaction_size
    )
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the benchmark run.
  # ----------------------------------------------------------------------------------------------

  def run_benchmark() do
    Logger.debug("Start ==========> <==========")

    config = get_config()
    #    IO.inspect(config, label: "config")

    start_date_time = DateTime.utc_now()

    measurement_data = %{
      :last_benchmark => start_date_time,
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

    {:ok, oranif_vsn} = :application.get_key(:oranif, :vsn)
    benchmark_driver = :lists.flatten(
      :io_lib.format("oranif (Version ~s)", [oranif_vsn])
    )
    #   IO.inspect(benchmark_driver, label: "benchmark_driver")

    :ok = :dpi.load_unsafe()
    driver = :dpi.context_create(@dpi_major_version, @dpi_minor_version)
    #   IO.inspect(driver, label: "driver")

    connections = create_database_objects(config, driver)
    #   IO.inspect(connections, label: "connections")

    {measurement_data_run_trial, trial_max, trial_min, trial_sum} = run_trial(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      measurement_data,
      result_file,
      String.to_integer(config["benchmark.trials"]),
      1,
      0,
      0,
      0
    )
    #    IO.inspect(measurement_data_run_trial, label: "measurement_data_run_trial")

    Enum.each(
      Map.values(connections),
      fn connection ->
        :ok = :dpi.conn_close(connection, [], <<>>)
      end
    )

    :ok = :dpi.context_destroy(driver)

    end_date_time = DateTime.utc_now()

    create_result_measuring_point_end(
      "benchmark",
      benchmark_driver,
      config,
      measurement_data_run_trial,
      result_file,
      "",
      "",
      0,
      end_date_time
    )

    Logger.info(
      "Duration (ms) trial min.    : #{
        trial_min / 1000000.0
        |> Decimal.from_float()
        |> Decimal.round(0)
      }"
    )
    Logger.info(
      "Duration (ms) trial max.    : #{
        trial_max / 1000000.0
        |> Decimal.from_float()
        |> Decimal.round(0)
      }"
    )
    Logger.info(
      "Duration (ms) trial average : #{
        trial_sum / 1000000.0 / String.to_integer(config["benchmark.trials"])
        |> Decimal.from_float()
        |> Decimal.round(0)
      }"
    )
    Logger.info(
      "Duration (ms) benchmark run : #{
        DateTime.diff(end_date_time, start_date_time, :nanosecond) / 1000000.0
        |> Decimal.from_float()
        |> Decimal.round(0)
      }"
    )
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the insert operations.
  # ----------------------------------------------------------------------------------------------

  defp run_insert(
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         driver,
         measurement_data,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> <=========="
    )

    start_date_time = DateTime.utc_now()

    measurement_data_start = create_result_measuring_point_start(
      "query",
      measurement_data,
      start_date_time
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - partition key: #{partition_key_current}")

    run_insert_partitions(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      String.to_integer(config["benchmark.number.partitions"]),
      1,
      result_file,
      trial_number
    )

    end_date_time = DateTime.utc_now()

    create_result_measuring_point_end(
      "query",
      benchmark_driver,
      config,
      measurement_data_start,
      result_file,
      "insert",
      config["sql.insert"],
      trial_number,
      end_date_time
    )
  end

  defp run_insert_partitions(
         _benchmark_driver,
         _bulk_data_partitions,
         _config,
         _connections,
         _driver,
         0,
         _partition_key_current,
         _result_file,
         _trial_number
       ) do
    Logger.debug("Start ==========> final <==========")
  end

  defp run_insert_partitions(
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         driver,
         partition_key,
         partition_key_current,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key_current} <=========="
    )

    if trial_number == 1 do
      Logger.info(
        "Start insert partition_key=#{partition_key_current}"
      )
    end
      
    curr_key = case config["benchmark.core.multiplier"] do
      "0" -> 1
      _ -> partition_key
    end

    batch_size = case String.to_integer(config["benchmark.batch.size"]) do
      0 -> String.to_integer(config["file.bulk.size"])
      _ = other_value -> other_value
    end

    %{:var => key_var} = :dpi.conn_newVar(
      connections[curr_key],
      :DPI_ORACLE_TYPE_VARCHAR,
      :DPI_NATIVE_TYPE_BYTES,
      batch_size,
      String.to_integer(config["file.bulk.length"]),
      false,
      false,
      :null
    )
    %{:var => data_var} = :dpi.conn_newVar(
      connections[curr_key],
      :DPI_ORACLE_TYPE_VARCHAR,
      :DPI_NATIVE_TYPE_BYTES,
      batch_size,
      String.to_integer(config["file.bulk.length"]),
      false,
      false,
      :null
    )

    sql_insert = :dpi.conn_prepareStmt(
      connections[curr_key],
      false,
      :erlang.iolist_to_binary(config["sql.insert"]),
      <<>>
    )
    :ok = :dpi.stmt_bindByName(
      sql_insert,
      <<"key">>,
      key_var
    )
    :ok = :dpi.stmt_bindByName(
      sql_insert,
      <<"data">>,
      data_var
    )

    insert(
      batch_size,
      bulk_data_partitions[partition_key - 1],
      config,
      connections[curr_key],
      0,
      0,
      sql_insert,
      {key_var, data_var},
      String.to_integer(config["benchmark.transaction.size"])
    )
    :ok = :dpi.stmt_close(sql_insert, <<>>)

    if trial_number == 1 do
      Logger.info(
        "End   insert partition_key=#{partition_key_current}"
      )
    end
    
    run_insert_partitions(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      partition_key - 1,
      partition_key_current + 1,
      result_file,
      trial_number
    )
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the select operations.
  # ----------------------------------------------------------------------------------------------

  defp run_select(
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         driver,
         measurement_data,
         result_file,
         trial_number
       ) do
    Logger.debug("Start ==========> <==========")

    start_date_time = DateTime.utc_now()

    measurement_data_start = create_result_measuring_point_start(
      "query",
      measurement_data,
      start_date_time
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - partition key: #{partition_key_current}")

    run_select_partitions(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      String.to_integer(config["connection.fetch.size"]),
      String.to_integer(config["benchmark.number.partitions"]),
      0,
      result_file,
      trial_number
    )

    end_date_time = DateTime.utc_now()

    create_result_measuring_point_end(
      "query",
      benchmark_driver,
      config,
      measurement_data_start,
      result_file,
      "select",
      config["sql.select"],
      trial_number,
      end_date_time
    )
  end

  defp run_select_partitions(
         _benchmark_driver,
         _bulk_data_partitions,
         _config,
         _connections,
         _driver,
         _fetch_size,
         0,
         _partition_key_current,
         _result_file,
         _trial_number
       ) do
    Logger.debug("Start ==========> final <==========")
  end

  defp run_select_partitions(
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         driver,
         fetch_size,
         partition_key,
         partition_key_current,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key_current} <=========="
    )

    if trial_number == 1 do
      Logger.info(
        "Start select partition_key=#{partition_key_current}"
      )
    end

    curr_key = case config["benchmark.core.multiplier"] do
      "0" -> 1
      _ -> partition_key_current + 1
    end

    sql_select = :dpi.conn_prepareStmt(
      connections[curr_key],
      false,
      :erlang.iolist_to_binary(
        config["sql.select"] <> " where partition_key = " <> Integer.to_string(
          partition_key_current
                                )
      ),
      <<>>
    )

    2 = :dpi.stmt_execute(sql_select, [])
    :ok = :dpi.stmt_setFetchArraySize(sql_select, fetch_size)
    %{:found => return_var} = :dpi.stmt_fetch(sql_select)

    count = select(
      0,
      sql_select,
      return_var
    )

    if count != length(bulk_data_partitions[partition_key_current]) do
      Logger.error(
        "Partition p#{
          partition_key_current
          |> Integer.to_string
          |> String.pad_leading(5, "0")
        } number rows: expected=#{
          length(bulk_data_partitions[partition_key_current])
          |> Integer.to_string
        } - found=#{
          count
          |> Integer.to_string
        }"
      )
      #      Process.exit(self(), "fatal error: program abort")
    end

    :ok = :dpi.stmt_close(sql_select, <<>>)

    if trial_number == 1 do
      Logger.info(
        "End   select partition_key=#{partition_key_current}"
      )
    end

    run_select_partitions(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      fetch_size,
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
         _benchmark_driver,
         _bulk_data_partitions,
         _config,
         _connections,
         _driver,
         measurement_data,
         _result_file,
         0,
         _trial_number_current,
         trial_max,
         trial_min,
         trial_sum
       ) do
    Logger.debug("Start ==========> final <==========")

    #    IO.inspect(measurement_data, label: "measurement_data - final")
    {measurement_data, trial_max, trial_min, trial_sum}
  end

  defp run_trial(
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         driver,
         measurement_data,
         result_file,
         trial_number,
         trial_number_current,
         trial_max,
         trial_min,
         trial_sum
       ) do
    Logger.debug(
      "Start ==========> trial no.: #{trial_number_current} <=========="
    )

    start_date_time = DateTime.utc_now()

    measurement_data_start = create_result_measuring_point_start(
      "trial",
      measurement_data,
      start_date_time
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - trial no.: #{trial_number_current}")

    Logger.info("Start ==========> trial no. #{trial_number_current}")

    sql_create = :dpi.conn_prepareStmt(
      connections[1],
      false,
      :erlang.iolist_to_binary(config["sql.create"]),
      <<>>
    )
    #   IO.inspect(sql_create, label: "sql_create")
    sql_drop = :dpi.conn_prepareStmt(
      connections[1],
      false,
      :erlang.iolist_to_binary(config["sql.drop"]),
      <<>>
    )
    #   IO.inspect(sql_drop, label: "sql_drop")

    try do
      0 = :dpi.stmt_execute(sql_create, [])
      Logger.debug(~s(Last DDL statement=#{config["sql.create"]}))
    rescue
      _ ->
        0 = :dpi.stmt_execute(sql_drop, [])
        0 = :dpi.stmt_execute(sql_create, [])
        Logger.debug(
          ~s(Last DDL statement after DROP=#{config["sql.create"]})
        )
    end

    :ok = :dpi.stmt_close(sql_create, <<>>)

    measurement_data_insert = run_insert(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      measurement_data_start,
      result_file,
      trial_number_current
    )
    #   IO.inspect(measurement_data_insert, label: "measurement_data_insert - trial no.: #{trial_number_current}")

    measurement_data_select = run_select(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      measurement_data_insert,
      result_file,
      trial_number_current
    )
    #   IO.inspect(measurement_data_select, label: "measurement_data_select - trial no.: #{trial_number_current}")

    0 = :dpi.stmt_execute(sql_drop, [])
    :ok = :dpi.stmt_close(sql_drop, <<>>)
    Logger.debug(~s(last DDL statement=#{config["sql.drop"]}))

    end_date_time = DateTime.utc_now()

    measurement_data_end = create_result_measuring_point_end(
      "trial",
      benchmark_driver,
      config,
      measurement_data_select,
      result_file,
      "",
      "",
      trial_number_current,
      end_date_time
    )
    #   IO.inspect(measurement_data_end, label: "measurement_data_end - trial no.: #{trial_number_current}")

    duration_ns = DateTime.diff(end_date_time, start_date_time, :nanosecond)

    Logger.info(
      "Duration (ms) trial         : #{
        duration_ns / 1000000.0
        |> Decimal.from_float()
        |> Decimal.round(0)
      }"
    )

    run_trial(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      measurement_data_end,
      result_file,
      trial_number - 1,
      trial_number_current + 1,
      if trial_max == 0 or trial_max < duration_ns  do
        duration_ns
      else
        trial_max
      end,
      if trial_min == 0 or trial_min > duration_ns  do
        duration_ns
      else
        trial_min
      end,
      trial_sum + duration_ns
    )
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the select operations.
  # ----------------------------------------------------------------------------------------------

  defp select(
         count,
         _statement,
         false
       ) do
    Logger.debug(
      "Start ==========> <=========="
    )
    count
  end

  defp select(
         count,
         statement,
         true
       ) do
    Logger.debug(
      "Start ==========> <=========="
    )
    %{:found => return_var} = :dpi.stmt_fetch(statement)

    select(
      count + 1,
      statement,
      return_var
    )
  end
end
