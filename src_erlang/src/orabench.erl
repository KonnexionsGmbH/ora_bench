-module(orabench).

%% API exports
-export([main/1, insert_partition/5, select_partition/4]).

-define(DPI_MAJOR_VERSION, 3).
-define(DPI_MINOR_VERSION, 0).

%%====================================================================
%% API functions
%%====================================================================

%% escript Entry point
main([ConfigFile, Driver]) ->
  io:format(
    "~n[~p:~p] Start ~p (~s)~n", [?FUNCTION_NAME, ?LINE, ?MODULE, Driver]
  ),
  process_flag(trap_exit, true),
  {ok, [Config0]} = file:consult(ConfigFile),
  Config = Config0#{benchmark_driver => Driver},
  #{
    benchmark_trials := Trials,

    file_bulk_name := BulkFile,
    file_bulk_header := Header,
    file_bulk_delimiter := BulkDelimiter,
    benchmark_number_partitions := Partitions,

    file_result_delimiter := ResultDelim,
    file_result_header := ResultHeader,
    file_result_name := ResultFile,

    benchmark_id := BMId,
    benchmark_comment := BMComment,
    benchmark_host_name := BMHost,
    benchmark_number_cores := BMCores,
    benchmark_os := BMOs,
    benchmark_release := BMRelease,
    benchmark_user_name := BMUser,
    benchmark_database := BMDB,
    benchmark_core_multiplier := BMCoreMul,
    connection_fetch_size := ConnFetchSz,
    benchmark_transaction_size := BMTransSz,
    file_bulk_length := FBulkLen,
    file_bulk_size := FBulkSz,
    benchmark_batch_size := BMBatchSz,
  
    sql_insert := SqlInsert,
    sql_select := SqlSelect
  } = Config,
  {ok, Fd} = file:open(BulkFile, [read, raw, binary, {read_ahead, 1024 * 1024}]),
  Rows = load_data(
    Driver, Fd, list_to_binary(Header), BulkDelimiter, Partitions, #{}
  ),
  put(rows, Rows),
  put(conf, Config),
  RowCount = length(lists:merge(maps:values(Rows))),
  if RowCount /= FBulkSz ->
      io:format("First = ~p~nLast = ~p~n", [hd(Rows), lists:last(Rows)]),
      error({loaded_rows, length(Rows), 'of', FBulkSz});
    true -> ok
  end,
  ok = file:close(Fd),
  _ = maps:map(
    fun(Partition, PartitionRows) ->
      io:format(
        "[~p:~p:~p] Partition ~p contains ~p rows~n",
      [?MODULE, ?FUNCTION_NAME, ?LINE, Partition, length(PartitionRows)]
      ),
      PartitionRows
    end,
    Rows
  ),
  #{
    startTime := StartTs,
    endTime := EndTs
  } = Results = run_trials(Trials),
  BMDrv = case Driver of
    "oranif" ->
      ok = application:load(oranif),
      {ok, OranifVsn} = application:get_key(oranif, vsn),
      lists:flatten(io_lib:format("oranif (Version ~s)", [OranifVsn]))
  end,
  BMMod = lists:flatten(
    io_lib:format(
      "OTP ~s, erts-~s",
      [erlang:system_info(otp_release), erlang:system_info(version)]
    )
  ),
  RowFmt = string:join(
    [
      BMRelease, BMId, BMComment, BMHost, integer_to_list(BMCores), BMOs,
      BMUser, BMDB, BMMod, BMDrv,
      "~p", %trial_no
      "~s", % sql
      integer_to_list(BMCoreMul), integer_to_list(ConnFetchSz),
      integer_to_list(BMTransSz), integer_to_list(FBulkLen),
      integer_to_list(FBulkSz), integer_to_list(BMBatchSz),
      "~p", % action
      "~s", % start day time (yyyy-mm-dd hh24:mi:ss.fffffffff)
      "~s", % end day time (yyyy-mm-dd hh24:mi:ss.fffffffff)
      "~p", % duration second
      "~p~n" % duration nano second
    ],
    ResultDelim
  ),
  case filelib:is_regular(ResultFile) of
    false -> ok = file:write_file(ResultFile, ResultHeader ++ "\n");
    _ -> ok
  end,
  {ok, RFd} = file:open(ResultFile, [append, binary]),
  DurationMicros = timer:now_diff(EndTs, StartTs),
  maps:map(
    fun(
      Trial,
      #{startTime := STs, endTime := ETs, insert := Insrts, select := Slcts}
    ) ->
      {InsSTs, InsETs, TotalInserted} = maps:fold(
        fun(
          _Pid,
          #{start := ISTs, 'end' := IETs, rows := Inserted},
          {IISTs, IIETs, Count}
        ) ->
          {[ISTs | IISTs], [IETs | IIETs], Count + Inserted}
        end,
        {[], [], 0}, maps:without([startTime, endTime], Insrts)
      ),
      InsMaxET = lists:max(InsETs),
      InsMinST = lists:min(InsSTs),
      InsDur = timer:now_diff(InsMaxET, InsMinST),
      ok = io:format(
        RFd, RowFmt,
        [Trial, SqlInsert, 'query', ts_str(InsMinST), ts_str(InsMaxET),
        round(InsDur / 1000000), InsDur * 1000]
      ),
      {SelSTs, SelETs, TotalSelected} = maps:fold(
        fun(
          _Pid,
          #{start := ISTs, 'end' := IETs, rows := Selected},
          {IISTs, IIETs, Count}
        ) ->
          {[ISTs | IISTs], [IETs | IIETs], Count + Selected}
        end,
        {[], [], 0}, maps:without([startTime, endTime], Slcts)
      ),
      SelMaxET = lists:max(SelETs),
      SelMinST = lists:min(SelSTs),
      SelDur = timer:now_diff(SelMaxET, SelMinST),
      ok = io:format(
        RFd, RowFmt,
        [Trial, SqlSelect, 'query', ts_str(SelMinST), ts_str(SelMaxET),
        round(SelDur / 1000000), SelDur * 1000]
      ),
      DMs = timer:now_diff(ETs, STs),
      ok = io:format(
        RFd, RowFmt,
        [Trial, "", trial, ts_str(STs), ts_str(ETs),
        round(DMs / 1000000), DMs * 1000]
      ),
      if TotalInserted /= TotalSelected orelse FBulkSz /= TotalInserted ->
        io:format(
          "Trial ~p, Inserted ~p, Selected ~p, Missed ~p, Total ~p~n",
          [
            Trial, TotalInserted, TotalSelected, TotalInserted - TotalSelected,
            FBulkSz
          ]
        );
      true -> ok end
    end,
    maps:without([startTime, endTime], Results)
  ),
    ok = io:format(
    RFd, RowFmt,
    [0, "", benchmark, ts_str(StartTs), ts_str(EndTs),
    round(DurationMicros / 1000000), DurationMicros * 1000]
  ),
  ok = file:close(RFd),
  io:format("[~p:~p] End ~p (~s)~n", [?FUNCTION_NAME, ?LINE, ?MODULE, Driver]),
  halt(0).

%%====================================================================
%% Internal functions
%%====================================================================
ts_str({_, _, Micro} = Timestamp) ->
  {{Y, M , D}, {H, Mi, S}} = calendar:now_to_local_time(Timestamp),
  list_to_binary(
    io_lib:format(
      "~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B.~-9..0B",
      [Y,M,D,H,Mi,S,Micro])
  ).

run_trials(Trials) ->
  #{
    connection_host := Host,
    connection_port := Port,
    connection_service := Service,
    connection_user := UserStr,
    connection_password := PasswordStr,

    benchmark_driver := Driver
  } = Config = get(conf),

  Ctx = case Driver of
    "oranif" ->
      ok = dpi:load_unsafe(),
      dpi:context_create(?DPI_MAJOR_VERSION, ?DPI_MINOR_VERSION)
  end,
  case Driver of
    "oranif" ->
      put(
        conf,
        Config#{
          connection_user => list_to_binary(UserStr),
          connection_password => list_to_binary(PasswordStr),
          connection_string => list_to_binary(
            io_lib:format("~s:~p/~s", [Host, Port, Service])
          )
        }
      )
  end,
  run_trials(1, Trials, Ctx, #{startTime => os:timestamp()}).
run_trials(Trial, Trials, Ctx, Stats) when Trial > Trials ->
  #{benchmark_driver := Driver} = get(conf),
  if Driver == "oranif" -> ok = dpi:context_destroy(Ctx); true -> nop end,
  Stats#{endTime => os:timestamp()};
run_trials(Trial, Trials, Ctx, Stats) ->
  #{
    benchmark_driver := Driver,

    connection_user := User,
    connection_password := Password,

    connection_host := Host,
    connection_port := Port,
    connection_service := Service,

    sql_create := Create,
    sql_drop := Drop
  } = Conf = get(conf),
  io:format(
    "[~p:~p:~p] Start trial no ~p... ", [?MODULE, ?FUNCTION_NAME, ?LINE, Trial]
  ),
  StartTime = os:timestamp(),
  case Driver of
    "oranif" ->
      #{connection_string := ConnectString} = Conf,
      Conn = dpi:conn_create(Ctx, User, Password, ConnectString, #{}, #{}),
      CreateStmt = dpi:conn_prepareStmt(Conn, false, list_to_binary(Create), <<>>),
      DropStmt = dpi:conn_prepareStmt(Conn, false, list_to_binary(Drop), <<>>),
      case catch dpi:stmt_execute(CreateStmt, ['DPI_MODE_EXEC_COMMIT_ON_SUCCESS']) of
        0 -> ok;
        {'EXIT', {{error, _, _, #{code := 955}}, _}} ->
          case dpi:stmt_execute(DropStmt, ['DPI_MODE_EXEC_COMMIT_ON_SUCCESS']) of
            0 ->
              case dpi:stmt_execute(CreateStmt, ['DPI_MODE_EXEC_COMMIT_ON_SUCCESS']) of
                0 -> ok;
                Error -> error({?LINE, Error})
              end;
            Error -> error({?LINE, Error})
          end;
        Error -> error({?LINE, Error})
      end,
      ok = dpi:stmt_close(CreateStmt, <<>>),
      ok = dpi:stmt_close(DropStmt, <<>>),
      ok = dpi:conn_close(Conn, [], <<>>)
  end,
  InsertStat = run_insert(Ctx),
  SelectStat = run_select(Ctx),
  InsertPR = maps:fold(
    fun(_Pid, #{partition := P, rows := R}, Map) -> Map#{P => R} end,
    #{},
    InsertStat
  ),
  SelectPR = maps:fold(
    fun(_Pid, #{partition := P, rows := R}, Map) -> Map#{P => R} end,
    #{},
    SelectStat
  ),
  if SelectPR /= InsertPR ->
      io:format(
        "[~p:~p:~p] ERROR insert/select by partition missmatch"
        "~nInsert : ~p~nSelect : ~p~n",
        [?MODULE, ?FUNCTION_NAME, ?LINE, InsertPR, SelectPR]
      ),
      exit(bad_partitioncount);
    true -> ok
  end,
  EndTime = os:timestamp(),
  io:format(
    "~p seconds~n", [round(timer:now_diff(EndTime, StartTime) / 1000000)]
  ),
  run_trials(
    Trial + 1, Trials, Ctx,
    Stats#{Trial => #{
      startTime => StartTime,
      endTime => EndTime,
      insert => InsertStat,
      select => SelectStat
    }}
  ).

run_insert(Ctx) ->  
  Rows = get(rows),
  #{benchmark_number_partitions := Partitions} = Config = get(conf),
  Master = self(),
  Threads = [
    spawn_link(
      ?MODULE, insert_partition,
      [Partition, maps:get(Partition, Rows), Ctx, Master, Config]
    ) || Partition <- lists:seq(0, Partitions - 1)
  ],
  thread_join(Threads).

run_select(Ctx) ->
  #{benchmark_number_partitions := Partitions} = Config = get(conf),
  Master = self(),
  Threads = [
    spawn_link(      
      ?MODULE, select_partition, [Partition, Ctx, Master, Config]
    ) || Partition <- lists:seq(0, Partitions - 1)
  ],
  thread_join(Threads).

insert_partition(
  Partition, Rows, Ctx, Master,
  #{
    connection_user := User,
    connection_password := Password,
    sql_insert := Insert,

    benchmark_batch_size := NumItersExec,
    benchmark_transaction_size := NumItersCommit,
    file_bulk_size := FBulkSz,
    file_bulk_length := Size,

    benchmark_driver := Driver
  } = Config
) ->
  Conn = case Driver of
    "oranif" ->
      #{connection_string := ConnectString} = Config,
      dpi:conn_create(Ctx, User, Password, ConnectString, #{}, #{})
  end,
  Start = os:timestamp(),
  Params = case Driver of
    "oranif" ->
      #{var := KeyVar} = dpi:conn_newVar(
        Conn, 'DPI_ORACLE_TYPE_VARCHAR', 'DPI_NATIVE_TYPE_BYTES',
        if NumItersExec > 0 -> NumItersExec; true -> FBulkSz end,
        32, false, false, null
      ),
      #{var := DataVar} = dpi:conn_newVar(
        Conn, 'DPI_ORACLE_TYPE_VARCHAR', 'DPI_NATIVE_TYPE_BYTES',
        if NumItersExec > 0 -> NumItersExec; true -> FBulkSz end,
        Size, false, false, null
      ),
      InsertStmt = dpi:conn_prepareStmt(
        Conn, false, list_to_binary(Insert), <<>>
      ),
      ok = dpi:stmt_bindByName(InsertStmt, <<"key">>, KeyVar),
      ok = dpi:stmt_bindByName(InsertStmt, <<"data">>, DataVar),
      #{
        conn => Conn, insertStmt => InsertStmt, keyVar => KeyVar,
        dataVar => DataVar
      }
  end,
  case Driver of
    "oranif" ->
      #{insertStmt := InsStmt, keyVar := KV, dataVar := DV} = Params,
      {NIE, _} = lists:foldl(
        fun({Key, Data}, {NIE, RowCount}) ->
          NewNIE = if
            NumItersExec == 0 orelse NIE < NumItersExec ->
              ok = dpi:var_setFromBytes(KV, NIE, Key),
              ok = dpi:var_setFromBytes(DV, NIE, Data),
              NIE + 1;
            true ->
              ok = dpi:stmt_executeMany(
                InsStmt, [],
                if NumItersExec > 0 -> NumItersExec; true -> FBulkSz end
              ),
              ok = dpi:var_setFromBytes(KV, 0, Key),
              ok = dpi:var_setFromBytes(DV, 0, Data),
              1
          end,
          if NumItersCommit > 0 andalso RowCount rem NumItersCommit == 0 ->
              ok = dpi:conn_commit(Conn);
            true -> ok
          end,
          {NewNIE, RowCount + 1}
        end,
        {0, 0}, Rows
      ),
      if NIE > 0 -> ok = dpi:stmt_executeMany(InsStmt, [], NIE);
      true -> ok end,
      ok = dpi:conn_commit(Conn),
      ok = dpi:var_release(maps:get(keyVar, Params)),
      ok = dpi:var_release(maps:get(dataVar, Params)),
      ok = dpi:stmt_close(InsStmt, <<>>),
      ok = dpi:conn_close(Conn, [], <<>>)
  end,
  Master ! {
    result, self(),
    #{
      start => Start, 'end' => os:timestamp(), rows => length(Rows),
      partition => Partition
    }
  }.

select_partition(
  Partition, Ctx, Master,
  #{
    connection_user := User,
    connection_password := Password,
    sql_select := Select,
    connection_fetch_size := FetchSize,
    file_bulk_size := FileBulkSize,
    benchmark_driver := Driver
  } = Config
) -> 
  Conn = case Driver of
    "oranif" ->
      #{connection_string := ConnectString} = Config,
      dpi:conn_create(Ctx, User, Password, ConnectString, #{}, #{})
  end,
  SelectSql = list_to_binary(
    io_lib:format("~s WHERE partition_key = ~p", [Select, Partition])
  ),
  Start = os:timestamp(),
  Params = case Driver of
    "oranif" ->
      SelectStmt = dpi:conn_prepareStmt(Conn, false, SelectSql, <<>>),
      2 = dpi:stmt_execute(SelectStmt, []),
      ok = dpi:stmt_setFetchArraySize(SelectStmt, FetchSize),
      #{selectStmt => SelectStmt}
  end,
  Selected = select_fetch_all(Driver, Params),
  case Driver of
    "oranif" ->
      #{selectStmt := SelStmt} = Params,
      ok = dpi:stmt_close(SelStmt, <<>>),
      ok = dpi:conn_close(Conn, [], <<>>)
  end,
  Master ! {
    result, self(),
    #{
      start => Start,
      'end' => os:timestamp(),
      rows => Selected,
      partition => Partition
    }
  }.

load_data(Driver, Fd, Header, BulkDelimiter, Partitions, Rows) ->
  case file:read_line(Fd) of
    eof -> Rows;
    {ok, Line0} ->
      case string:trim(Line0, both, "\r\n") of
        Header ->
          load_data(Driver, Fd, Header, BulkDelimiter, Partitions, Rows);
        Line ->
          [<<KeyByte1:8, KeyByte2:8, _/binary>> = Key, Data] = string:split(
            Line, BulkDelimiter, all
          ),
          Partition = (KeyByte1 * 256 + KeyByte2) rem Partitions,
          OldData = maps:get(Partition, Rows, []),
          load_data(
            Driver, Fd, Header, BulkDelimiter, Partitions,
            Rows#{
              Partition => case Driver of
                "oranif" -> [{Key, Data} | OldData]
              end
            }
          )
      end
  end.

thread_join(Threads) -> thread_join(Threads, #{}).
thread_join([], Results) -> Results;
thread_join(Threads, Results) ->
  receive
    {result, Pid, Result} ->
      thread_join(Threads, Results#{Pid => Result});
    {'EXIT', Thread, _Reason} ->
      thread_join(Threads -- [Thread], Results)
  after 60000 ->
    io:format(
      "[~p:~p:~p] waiting ~p~n",
      [?MODULE, ?FUNCTION_NAME, ?LINE, length(Threads)]
    ),
    thread_join(Threads, Results)
  end.

select_fetch_all("oranif", #{selectStmt := SelectStmt}) ->
  select_fetch_all_oranif(SelectStmt, 0);

select_fetch_all_oranif(SelectStmt, Count) ->
  case dpi:stmt_fetch(SelectStmt) of
    #{found := true} ->
      %#{data := Key} = dpi:stmt_getQueryValue(SelectStmt, 1),
      %#{data := Data} = dpi:stmt_getQueryValue(SelectStmt, 2),
      %true = byte_size(dpi:data_getBytes(Key)) > 0,
      %true = byte_size(dpi:data_getBytes(Data)) > 0,
      select_fetch_all_oranif(SelectStmt, Count+1);
    #{found := false} -> Count
  end.
