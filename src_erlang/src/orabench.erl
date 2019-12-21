-module(orabench).

%% API exports
-export([main/1, insert_partition/5, select_partition/4]).

-define(DPI_MAJOR_VERSION, 3).
-define(DPI_MINOR_VERSION, 0).

%%====================================================================
%% API functions
%%====================================================================

%% escript Entry point
main([ConfigFile]) ->
  process_flag(trap_exit, true),
  {ok, [Config]} = file:consult(ConfigFile),
  #{
    benchmark_trials := Trials,

    file_bulk_name := BulkFile,
    file_bulk_header := Header,
    file_bulk_delimiter := BulkDelimiter,
    benchmark_number_partitions := Partitions
  } = Config,
  {ok, Fd} = file:open(BulkFile, [read, raw, binary, {read_ahead, 1024 * 1024}]),
  Rows = load_data(Fd, Header, BulkDelimiter, Partitions, []),
  R = run_trials(Trials, Rows, Config),
  io:format("run_trials(Trials, Config) ~p~n", [R]),
  ok = file:close(Fd),
  halt(0).

%%====================================================================
%% Internal functions
%%====================================================================

run_trials(
  Trials, Rows,
  #{
    connection_host := Host,
    connection_port := Port,
    connection_service := Service,
    connection_user := UserStr,
    connection_password := PasswordStr
  } = Config
) ->
  ok = dpi:load_unsafe(),
  Ctx = dpi:context_create(?DPI_MAJOR_VERSION, ?DPI_MINOR_VERSION),
  run_trials(
    Trials, Rows, Ctx,
    Config#{
      connection_user => list_to_binary(UserStr),
      connection_password =>  list_to_binary(PasswordStr),
      connection_string => list_to_binary(
        io_lib:format("~s:~p/~s", [Host, Port, Service])
      )
    },
    #{total_duration => os:timestamp()}
  ).
run_trials(0, _, Ctx, _, #{total_duration := Start} = Stats) ->
  ok = dpi:context_destroy(Ctx),
  Stats#{total_duration => timer:now_diff(os:timestamp(), Start)};
run_trials(
  Trial, Rows, Ctx,
  #{
    connection_string := ConnectString,
    connection_user := User,
    connection_password := Password,

    sql_create := Create,
    sql_drop := Drop
  } = Config,
  Stats
) ->
  StartTime = os:timestamp(),
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
  ok = dpi:conn_close(Conn, [], <<>>),
  InsertStat = run_insert(Ctx, Rows, Config),
  SelectStat = run_select(Ctx, Config),
  run_trials(
    Trial - 1, Rows, Ctx, Config,
    Stats#{Trial => #{
      duration => timer:now_diff(os:timestamp(), StartTime),
      insert => InsertStat,
      select => SelectStat
    }}
  ).

run_select(Ctx, #{benchmark_number_partitions := Partitions} = Config) ->
  Master = self(),
  Threads = [
    spawn_link(
      ?MODULE, select_partition, [Partition, Ctx, Master, Config]
    ) || Partition <- lists:seq(0, Partitions - 1)
  ],
  thread_join(Threads).

select_partition(
  Partition, Ctx, Master,
  #{
    connection_string := ConnectString,
    connection_user := User,
    connection_password := Password,
    sql_select := Select,
    connection_fetch_size := FetchSize
  }
) ->
  Conn = dpi:conn_create(Ctx, User, Password, ConnectString, #{}, #{}),
  SelectSql = list_to_binary(
    io_lib:format("~s WHERE partition_key = ~p", [Select, Partition])
  ),
  SelectStmt = dpi:conn_prepareStmt(Conn, false, SelectSql, <<>>),
  2 = dpi:stmt_execute(SelectStmt, []),
  ok = dpi:stmt_setFetchArraySize(SelectStmt, FetchSize),
  Start = os:timestamp(),
  (fun Fetch() ->
    case dpi:stmt_fetch(SelectStmt) of
      #{found := true} ->
        #{data := Key} = dpi:stmt_getQueryValue(SelectStmt, 1),
        #{data := Data} = dpi:stmt_getQueryValue(SelectStmt, 2),
        true = byte_size(dpi:data_getBytes(Key)) > 0,
        true = byte_size(dpi:data_getBytes(Data)) > 0,
        Fetch();
      #{found := false} -> done
    end
  end)(),
  Duration = timer:now_diff(os:timestamp(), Start),
  ok = dpi:stmt_close(SelectStmt, <<>>),
  ok = dpi:conn_close(Conn, [], <<>>),
  Master ! {result, self(), Duration}.

run_insert(Ctx, Rows, #{benchmark_number_partitions := Partitions} = Config) ->
  Master = self(),
  Threads = [
    spawn_link(
      ?MODULE, insert_partition, [Partition, Rows, Ctx, Master, Config]
    ) || Partition <- lists:seq(0, Partitions - 1)
  ],
  thread_join(Threads).

insert_partition(
  Partition, Rows, Ctx, Master,
  #{
    connection_string := ConnectString,
    connection_user := User,
    connection_password := Password,
    sql_insert := Insert,

    benchmark_batch_size := NumItersExec,
    benchmark_transaction_size := NumItersCommit,
    file_bulk_length := Size
  }
) ->
  Conn = dpi:conn_create(Ctx, User, Password, ConnectString, #{}, #{}),
  #{var := KeyVar} = dpi:conn_newVar(
    Conn, 'DPI_ORACLE_TYPE_VARCHAR', 'DPI_NATIVE_TYPE_BYTES', NumItersExec,
    Size, false, false, null
  ),
  #{var := DataVar} = dpi:conn_newVar(
    Conn, 'DPI_ORACLE_TYPE_VARCHAR', 'DPI_NATIVE_TYPE_BYTES', NumItersExec,
    Size, false, false, null
  ),
  InsertStmt = dpi:conn_prepareStmt(Conn, false, list_to_binary(Insert), <<>>),
  ok = dpi:stmt_bindByName(InsertStmt, <<"key">>, KeyVar),
  ok = dpi:stmt_bindByName(InsertStmt, <<"data">>, DataVar),
  Start = os:timestamp(),
  exec(
    Partition, Rows,
    fun(Key, Data, {NIE, NIC}) ->
      NewNIE = if NIE == NumItersExec ->
          ok = dpi:stmt_executeMany(InsertStmt, [], NumItersExec),
          ok = dpi:var_setFromBytes(KeyVar, 0, Key),
          ok = dpi:var_setFromBytes(DataVar, 0, Data),
          1;
        true ->
          ok = dpi:var_setFromBytes(KeyVar, NIE, Key),
          ok = dpi:var_setFromBytes(DataVar, NIE, Data),
          NIE + 1
      end,
      if NIC == NumItersCommit ->
          ok = dpi:conn_commit(Conn),
          {NewNIE, 0};
        true -> {NewNIE, NIC + 1}
      end
    end,
    {0, 0}
  ),
  Duration = timer:now_diff(os:timestamp(), Start),
  ok = dpi:var_release(KeyVar),
  ok = dpi:var_release(DataVar),
  ok = dpi:stmt_close(InsertStmt, <<>>),
  ok = dpi:conn_close(Conn, [], <<>>),
  Master ! {result, self(), Duration}.

load_data(Fd, Header, BulkDelimiter, Partitions, Rows) ->
  case file:read_line(Fd) of
    eof -> lists:reverse(Rows);
    {ok, Line0} ->
      case string:trim(Line0, both, "\r\n") of
        Header ->
          load_data(Fd, Header, BulkDelimiter, Partitions, Rows);
        Line ->
          [<<KeyByte1:8, KeyByte2:8, _/binary>> = Key, Data] = string:split(
            Line, BulkDelimiter, all
          ),
          Partition = (KeyByte1 * 256 + KeyByte2) rem Partitions,
          load_data(
            Fd, Header, BulkDelimiter, Partitions,
            [{Partition, Key, Data} | Rows]
          )
      end
  end.

exec(Partition, Rows, Fun, Acc) -> exec(Partition, Rows, Fun, Acc, 0).
exec(_Partition, [], _Fun, _Acc, Count) -> Count;
exec(Partition, [{Partition, Key, Data} | Rows], Fun, Acc, Count) ->
  NewAcc = Fun(Key, Data, Acc),
  exec(Partition, Rows, Fun, NewAcc, Count + 1);
exec(Partition, [_ | Rows], Fun, Acc, Count) ->
  exec(Partition, Rows, Fun, Acc, Count).

thread_join(Threads) -> thread_join(Threads, #{}).
thread_join([], Results) -> Results;
thread_join(Threads, Results) ->
  receive
    {result, Pid, Result} -> thread_join(Threads, Results#{Pid => Result});
    {'EXIT', Thread, _Reason} ->
      thread_join(Threads -- [Thread], Results)
  after
    5000 ->
      io:format("waiting ~p~n", [length(Threads)]),
      thread_join(Threads, Results)
  end.
