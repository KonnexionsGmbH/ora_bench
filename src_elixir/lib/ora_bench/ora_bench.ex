defmodule OraBench do
  require Logger

  @benchmark_module "OraBench (Elixir #{System.version()})"

  @file_configuration_name  "priv/properties/ora_bench.properties"

  @moduledoc false

  # ----------------------------------------------------------------------------------------------
  # Writing the results.
  # ----------------------------------------------------------------------------------------------

  def create_result(
        action,
        benchmark_driver,
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

  def create_result_file(config) do
    Logger.debug("Start ==========> <==========")

    result_file_name = Path.expand(
                         ~s(../#{config["file.result.name"]})
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

  def create_result_measuring_point_end(
        action,
        benchmark_driver,
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
          benchmark_driver,
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
          benchmark_driver,
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
          benchmark_driver,
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

  def create_result_measuring_point_start(action, measurement_data) do
    Logger.debug("Start ==========> action: #{action} <==========")

    case action do
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
  end

  # ----------------------------------------------------------------------------------------------
  # Database driver configuration.
  # ----------------------------------------------------------------------------------------------

  def driver_config(config)  do
    Logger.debug("Start ==========> <==========")

    [
      database: config["connection.service"],
      hostname: config["connection.host"],
#      parameters: [
#        autocommit: false,
#        fetch: String.to_integer(config["connection.fetch.size"])
#      ],
      password: config["connection.password"],
#      pool_size: case config["benchmark.core.multiplier"] do
#        "0" -> String.to_integer(config["benchmark.number.partitions"])
#        _ -> 1
#      end,
      port: String.to_integer(config["connection.port"]),
      timeout: :infinity,
      username: config["connection.user"]
    ]
  end

  # ----------------------------------------------------------------------------------------------
  # Loading the bulk file into memory.
  # ----------------------------------------------------------------------------------------------

  def get_bulk_data_partitions(config) do
    Logger.debug("Start ==========> <==========")

    bulk_data_partitions = Path.expand(~s(../#{config["file.bulk.name"]}))
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

  def get_config do
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
end
