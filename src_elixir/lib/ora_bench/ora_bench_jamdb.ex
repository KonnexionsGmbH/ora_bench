defmodule OraBenchJamdb do
  require Logger
  require OraBench

  # @benchmark_driver  "jamdb_oracle (Version v#{@module.version_info()}})"
  @benchmark_driver  "JamDB Oracle (Version v0.3.6})"

  @module  Jamdb.Oracle

  @moduledoc false

  # ----------------------------------------------------------------------------------------------
  # Creating the database objects of type connection.
  # ----------------------------------------------------------------------------------------------

  defp create_database_objects(config) do
    Logger.debug("Start ==========> <==========")

    IO.inspect(OraBench.driver_config(config), label: "driver_config")
    IO.inspect(self(), label: "self")

    {:ok, conn} = Jamdb.Oracle.start_link(OraBench.driver_config(config))
    IO.inspect(conn, label: "conn 1")
    query = %Jamdb.Oracle.Query{statement: "SELECT * FROM dual"}
    IO.inspect(query, label: "query")
    DBConnection.execute(conn, query, []) |> IO.inspect
    DBConnection.close(conn, query) |> IO.inspect
    IO.inspect(conn, label: "conn 2")

    case config["benchmark.core.multiplier"] do
      "0" ->
        case @module.start_link(OraBench.driver_config(config)) do
          {:ok, connection} ->
            Map.new([{1, connection}])
          _ = other_reason ->
            raise(
              "[Error in create_database_objects] #{
                @module
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
            case @module.start_link(OraBench.driver_config(config)) do
              {:ok, connection} -> Map.put(connections, i, connection)
              _ = other_reason ->
                raise(
                  "[Error in create_database_objects] #{
                    @module
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
         connection,
         count,
         _statement,
         transaction_size
       ) do
    Logger.debug("Start ==========> final <==========")

    #    if batch_size > 0 and batch_data.__len__() > 0 do
    #      cursor.executemany(config["sql.insert"], batch_data)

    if transaction_size == 0 or rem(count, transaction_size) != 0 do
      @module.query(connection, "COMMIT;")
    end
  end

  defp insert(
         batch_data,
         0,
         [_key_data_tuple | tail] = _bulk_data_partition,
         config,
         connection,
         count,
         statement,
         transaction_size
       ) do
    #    cursor.execute(config["sql.insert"], [key_data_tuple[0], key_data_tuple[1]])

    if transaction_size == 0 or rem(count, transaction_size) != 0 do
      @module.query(connection, "COMMIT;")
    end

    insert(batch_data, 0, tail, config, connection, count + 1, statement, transaction_size)
  end

  defp insert(
         batch_data,
         batch_size,
         [key_data_tuple | tail] = _bulk_data_partition,
         config,
         connection,
         count,
         statement,
         transaction_size
       ) do
    IO.inspect(key_data_tuple, label: "key_data_tuple")
    batch_data_start = batch_data ++ [statement]
    batch_data_end = case rem(count + 1, batch_size)  do
      0 -> []
      _ -> batch_data_start
      #    if count % config["benchmark.batch.size"] == 0:
      #      cursor.executemany(config["sql.insert"], batch_data)
      #      batch_data = list()
    end

    if transaction_size == 0 or rem(count, transaction_size) != 0 do
      @module.query(connection, "COMMIT;")
    end

    insert(
      batch_data_end,
      batch_size,
      tail,
      config,
      connection,
      count + 1,
      statement,
      transaction_size
    )
  end

  # ----------------------------------------------------------------------------------------------
  # Performing the benchmark run.
  # ----------------------------------------------------------------------------------------------

  def run_benchmark() do
    Logger.debug("Start ==========> <==========")

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

    connections = create_database_objects(config)
    IO.inspect(connections, label: "connections")

    measurement_data_run_trial = run_trial(
      @benchmark_driver,
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
      fn connection ->
        true = Process.exit(connection, :kill)
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
         benchmark_driver,
         bulk_data_partitions,
         config,
         connections,
         measurement_data,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> <=========="
    )

    measurement_data_start = OraBench.create_result_measuring_point_start(
      "query",
      measurement_data
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - partition key: #{partition_key_current}")

    run_insert_partitions(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      String.to_integer(config["benchmark.number.partitions"]),
      1,
      result_file,
      trial_number
    )

    OraBench.create_result_measuring_point_end(
      "query",
      benchmark_driver,
      config,
      measurement_data_start,
      result_file,
      "insert",
      config["sql.insert"],
      trial_number
    )
  end

  defp run_insert_partitions(
         _benchmark_driver,
         _bulk_data_partitions,
         _config,
         _connections,
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
         partition_key,
         partition_key_current,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key_current} <=========="
    )

    case config["benchmark.core.multiplier"] do
      "0" ->
        IO.inspect(connections[1], label: "connections[1]")
        key_var = :dpi.conn_newVar(
          connections[1],
          :DPI_ORACLE_TYPE_VARCHAR,
          :DPI_NATIVE_TYPE_BYTES,
          String.to_integer(config["benchmark.batch.size"]),
          String.to_integer(config["file.bulk.length"]),
          false,
          false,
          :null
        )
        IO.inspect(key_var, label: "key_var")
        data_var = :dpi.conn_newVar(
          connections[1],
          :DPI_ORACLE_TYPE_VARCHAR,
          :DPI_NATIVE_TYPE_BYTES,
          String.to_integer(config["benchmark.batch.size"]),
          String.to_integer(config["file.bulk.length"]),
          false,
          false,
          :null
        )
        IO.inspect(data_var, label: "data_var")
        sql_insert = :dpi.conn_prepareStmt(connections[1], false, :erlang.iolist_to_binary(config["sql.insert"]), <<>>)
        IO.inspect(sql_insert, label: "sql_insert")
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
          [],
          String.to_integer(config["benchmark.batch.size"]),
          bulk_data_partitions[partition_key - 1],
          config,
          connections[1],
          0,
          sql_insert,
          String.to_integer(config["benchmark.transaction.size"])
        )
        :ok = :dpi.stmt_close(sql_insert, <<>>)
      _ ->
        key_var = :dpi.conn_newVar(
          connections[partition_key],
          :DPI_ORACLE_TYPE_VARCHAR,
          :DPI_NATIVE_TYPE_BYTES,
          String.to_integer(config["benchmark.batch.size"]),
          String.to_integer(config["file.bulk.length"]),
          false,
          false,
          :null
        )
        data_var = :dpi.conn_newVar(
          connections[partition_key],
          :DPI_ORACLE_TYPE_VARCHAR,
          :DPI_NATIVE_TYPE_BYTES,
          String.to_integer(config["benchmark.batch.size"]),
          String.to_integer(config["file.bulk.length"]),
          false,
          false,
          :null
        )
        sql_insert = :dpi.conn_prepareStmt(connections[partition_key], false, :erlang.iolist_to_binary(config["sql.insert"]), <<>>)
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
          [],
          String.to_integer(config["benchmark.batch.size"]),
          bulk_data_partitions[partition_key - 1],
          config,
          connections[partition_key],
          0,
          sql_insert,
          String.to_integer(config["benchmark.transaction.size"])
        )
        :ok = :dpi.stmt_close(sql_insert, <<>>)
    end

    run_insert_partitions(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
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
         measurement_data,
         result_file,
         trial_number
       ) do
    Logger.debug("Start ==========> <==========")

    measurement_data_start = OraBench.create_result_measuring_point_start(
      "query",
      measurement_data
    )
    #    IO.inspect(measurement_data_start, label: "measurement_data_start - partition key: #{partition_key_current}")

    run_select_partitions(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
      String.to_integer(config["benchmark.number.partitions"]),
      1,
      result_file,
      trial_number
    )

    OraBench.create_result_measuring_point_end(
      "query",
      benchmark_driver,
      config,
      measurement_data_start,
      result_file,
      "select",
      config["sql.select"],
      trial_number
    )
  end

  defp run_select_partitions(
         _benchmark_driver,
         _bulk_data_partitions,
         _config,
         _connections,
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
         partition_key,
         partition_key_current,
         result_file,
         trial_number
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key_current} <=========="
    )

    case config["benchmark.core.multiplier"] do
      "0" ->
        sql_select = :dpi.conn_prepareStmt(
          connections[1],
          false,
          :erlang.iolist_to_binary(config["sql.select"] <> " where partition_key = " <> Integer.to_string(partition_key)),
          <<>>
        )
        select(
          bulk_data_partitions[partition_key - 1],
          config,
          connections[1],
          partition_key,
          sql_select
        )
        :ok = :dpi.stmt_close(sql_select, <<>>)
      _ ->
        sql_select = :dpi.conn_prepareStmt(
          connections[partition_key],
          false,
          :erlang.iolist_to_binary(config["sql.select"] <> " where partition_key = " <> Integer.to_string(partition_key)),
          <<>>
        )
        select(
          bulk_data_partitions[partition_key - 1],
          config,
          connections[partition_key],
          partition_key,
          sql_select
        )
        :ok = :dpi.stmt_close(sql_select, <<>>)
    end

    run_select_partitions(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
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

    sql_create = %@module.Query{statement: config["sql.create"]}
    IO.inspect(sql_create, label: "sql_create")
    sql_create = DBConnection.prepare!(connections[1], sql_create)
    sql_drop = %@module.Query{statement: config["sql.drop"]}
    sql_drop = DBConnection.prepare!(connections[1], sql_drop)
    IO.inspect(sql_drop, label: "sql_drop")

    try do
      DBConnection.execute!(connections[1], sql_create, [])
      Logger.debug(~s(Last DDL statement=#{config["sql.create"]}))
    rescue
      _ -> DBConnection.execute!(connections[1], sql_drop, [])
           DBConnection.execute!(connections[1], sql_create, [])
           Logger.debug(~s(Last DDL statement after DROP=#{config["sql.create"]}))
    end

    DBConnection.close(connections[1], sql_create)

    measurement_data_insert = run_insert(
      benchmark_driver,
      bulk_data_partitions,
      config,
      connections,
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
      measurement_data_insert,
      result_file,
      trial_number_current
    )
    #   IO.inspect(measurement_data_select, label: "measurement_data_select - trial no.: #{trial_number_current}")

    DBConnection.execute!(connections[1], sql_drop, [])
    DBConnection.close(connections[1], sql_drop)
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
    #   IO.inspect(measurement_data_end, label: "measurement_data_end - trial no.: #{trial_number_current}")

    run_trial(
      benchmark_driver,
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
         bulk_data_partition,
         config,
         _connection,
         partition_key,
         statement
       ) do
    Logger.debug(
      "Start ==========> partition key: #{partition_key} <=========="
    )

    2 = :dpi.stmt_execute(statement, [])
    :ok = :dpi.stmt_setFetchArraySize(statement, String.to_integer(config["connection.fetch.size"]))

    count = select_fetch(statement, 0)

    if count != length(bulk_data_partition) do
      Logger.error(
        "Number rows: expected=#{
          length(bulk_data_partition)
          |> Integer.to_string
        } - found=#{
          count
          |> Integer.to_string
        }"
      )
      Process.exit(self(), "fatal error: program abort")
    end
  end

  defp select_fetch(statement, count) do
    result = :dpi.stmt_fetch(statement)
    case result[:found] do
      false -> count
      true -> IO.inspect(result, label: "result")
              select_fetch(statement, count + 1)
    end
  end
end
