defmodule OraBenchJamdb do
  require Logger
  require OraBench

  # @benchmark_driver  "jamdb_oracle (Version v#{Jamdb.Oracle.version_info()}})"
  @benchmark_driver  "JamDB Oracle (Version v0.3.6})"

  @moduledoc false

  # ----------------------------------------------------------------------------------------------
  # Creating the database objects of type connection.
  # ----------------------------------------------------------------------------------------------

  defp create_database_objects(config, driver) do
    Logger.debug("Start ==========> driver: #{driver} }<==========")

    case config["benchmark.core.multiplier"] do
      "0" ->
        case driver.start_link(OraBench.driver_config(config)) do
          {:ok, conn} ->
            Map.new([{1, conn}])
          _ = other_reason ->
            raise(
              "[Error in create_database_objects] #{
                driver
              }.start_list: reason=#{
                other_reason
              }"
            )
        end
      _ ->
        Enum.reduce(
          1..String.to_integer(config["benchmark.number.partitions"]),
          %{},
          fn (i, connections) ->
            case driver.start_link(OraBench.driver_config(config)) do
              {:ok, conn} -> Map.put(connections, i, conn)
              _ = other_reason ->
                raise(
                  "[Error in create_database_objects] #{
                    driver
                  }.start_list: reason=#{
                    other_reason
                  }"
                )
            end
          end
        )
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
  # Performing the benchmark run.
  # ----------------------------------------------------------------------------------------------

  def run_benchmark() do
    Logger.debug("Start ==========> <==========")

    driver = Jamdb.Oracle

    config = OraBench.get_config()
    #    IO.inspect(config, label: "config")

    measurement_data = %{
      :last_benchmark => DateTime.utc_now(),
      :last_trial => "n/a",
      :last_query => "n/a",
      :duration_insert_sum => 0,
      :duration_select_sum => 0
    }
    #    IO.inspect(measurement_data, label: "measurement_data")

    result_file = OraBench.create_result_file(config)
    #    IO.inspect(result_file, label: "result_file")

    bulk_data_partitions = OraBench.get_bulk_data_partitions(config)
    #   IO.inspect(bulk_data_partitions, label: "bulk_data_partitions")

    connections = create_database_objects(config, driver)
    IO.inspect(connections, label: "connections")

    measurement_data_run_trial = run_trial(
      @benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
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

    OraBench.create_result_measuring_point_end(
      "benchmark",
      @benchmark_driver,
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
         _benchmark_driver,
         _bulk_data_partitions,
         _config,
         _connections,
         _driver,
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
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         driver,
         measurement_data,
         partition_key,
         partition_key_current,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key_current} <=========="
    )

    measurement_data_start = OraBench.create_result_measuring_point_start(
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

    measurement_data_end = OraBench.create_result_measuring_point_end(
      "query",
      benchmark_driver,
      config,
      measurement_data_start,
      result_file,
      "insert",
      config["sql.insert"],
      trial_number
    )
    #    IO.inspect(measurement_data_end, label: "measurement_data_end - partition key: #{partition_key_current}")

    run_insert(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      measurement_data_end,
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
         _benchmark_driver,
         _bulk_data_partitions,
         _config,
         _connections,
         _driver,
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
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         driver,
         measurement_data,
         partition_key,
         partition_key_current,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key_current} <=========="
    )

    measurement_data_start = OraBench.create_result_measuring_point_start(
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

    measurement_data_end = OraBench.create_result_measuring_point_end(
      "query",
      benchmark_driver,
      config,
      measurement_data_start,
      result_file,
      "select",
      config["sql.select"],
      trial_number
    )
    #    IO.inspect(measurement_data_end, label: "measurement_data_end - partition key: #{partition_key_current}")

    run_select(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
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
         _benchmark_driver,
         _bulk_data_partitions,
         _config,
         _connections,
         _driver,
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
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         driver,
         measurement_data,
         result_file,
         trial_number,
         trial_number_current
       ) do
    Logger.debug(
      "Start ==========> trial no.: #{trial_number_current} <=========="
    )

    measurement_data_start = OraBench.create_result_measuring_point_start(
      "trial",
      measurement_data
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - trial no.: #{trial_number_current}")

    Logger.info("Start ==========> trial no. #{trial_number_current}")

    sql_create = %Jamdb.Oracle.Query{statement: config["sql.create"]}
    sql_drop = %Jamdb.Oracle.Query{statement: config["sql.drop"]}
    IO.inspect(connections[1], label: "connections[1]")
    Logger.info("wwe_017")
    IO.inspect(sql_create, label: "sql_create")
    Logger.info("wwe_018")

    try do
      Logger.info("wwe_019")
      case DBConnection.prepare_execute(connections[1], sql_create, []) do
        {:ok, Result} ->
          Logger.info("wwe_020")
          DBConnection.close(connections[1], sql_create)
        _ ->
          Logger.info("wwe_021")
          {:ok, Result} = DBConnection.prepare_execute(
            connections[1],
            sql_drop,
            []
          )
          DBConnection.close(connections[1], sql_drop)
          {:ok, Result} = DBConnection.prepare_execute(
            connections[1],
            sql_create,
            []
          )
          DBConnection.close(connections[1], sql_create)
          Logger.debug(~s(Last DDL statement after DROP=#{config["sql.create"]}))
      end
    catch
      e -> IO.inspect e
    end
    IO.inspect(:ok, label: "created")

    measurement_data_insert = run_insert(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      measurement_data_start,
      String.to_integer(config["benchmark.number.partitions"]),
      1,
      result_file,
      trial_number_current
    )
    #    IO.inspect(measurement_data_insert, label: "measurement_data_insert - trial no.: #{trial_number_current}")

    measurement_data_select = run_select(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
      measurement_data_insert,
      String.to_integer(config["benchmark.number.partitions"]),
      1,
      result_file,
      trial_number_current
    )
    #    IO.inspect(measurement_data_select, label: "measurement_data_select - trial no.: #{trial_number_current}")

    {:ok, Result} = DBConnection.prepare_execute(
      connections[1],
      sql_drop,
      []
    )
    #    DBConnection.close(connections[1], sql_drop)
    Logger.debug(~s(last DDL statement=#{config["sql.drop"]}))

    measurement_data_end = OraBench.create_result_measuring_point_end(
      "trial",
      benchmark_driver,
      config,
      measurement_data_select,
      result_file,
      "",
      "",
      trial_number_current
    )
    #    IO.inspect(measurement_data_end, label: "measurement_data_end - trial no.: #{trial_number_current}")

    run_trial(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      driver,
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
    #     cursor.execute(sql_statement + " where partition_key = " + str(partition_key))
    #
    #     for _ in cursor:
    #         count += 1
    #
    #     if count != len(bulk_size_partition):
    #         logging.error("Number rows: expected=" + str(len(bulk_size_partition)) + " - found=" + str(count))
    #         sys.exit(1)

  end
end
