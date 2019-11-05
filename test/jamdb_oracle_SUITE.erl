-module(jamdb_oracle_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0, test/1]).

-define(DPI_MAJOR_VERSION, 3).
-define(DPI_MINOR_VERSION, 0).
-define(MAX_NUMBERS, 100000).

all() -> [test].

test(_) ->
  {ok, IoDev} = file:open(ct:get_config(report), [append, raw]),
  Opts = [
    {host, ct:get_config(host)},
    {port, 1521},
    {user, ct:get_config(user)},
    {password, ct:get_config(password)},
    {service_name, ct:get_config(service_name)},
    {app_name, "test"}
  ],
  try
    {InsertTime, Inserted} = timer:tc(fun insert/1, [Opts]),
    InsertSec = InsertTime / 1000000,
    InsertRate = Inserted / InsertSec,
    ct:pal(
      "JAMDB inserted ~p rows in ~p seconds (~p rows / sec)",
      [Inserted, InsertSec, InsertRate]
    ),
    ok = file:write(
      IoDev, list_to_binary(
        io_lib:format(
          "JAMDBO\tINSERT\t~p rows in ~p seconds (~p rows/sec)~n",
          [Inserted, InsertSec, InsertRate]
        )
      )
    ),
    {SelectTime, Selected} = timer:tc(fun select/1, [Opts]),
    SelectSec = SelectTime / 1000000,
    SelectRate = Selected / SelectSec,
    ct:pal(
      "JAMDB selected ~p rows in ~p seconds (~p rows / sec)",
      [Selected, SelectSec, SelectRate]
    ),
    ok = file:write(
      IoDev, list_to_binary(
        io_lib:format(
          "JAMDBO\tSELECT\t~p rows in ~p seconds (~p rows/sec)~n",
          [Selected, SelectSec, SelectRate]
        )
      )
    )
  catch
    Class:Error ->
      ct:pal("ERROR: ~p:~p~n~p", [Class, Error, erlang:get_stacktrace()])
  end,
  ok = file:close(IoDev).

insert([{_,_} | _] = Opts) ->
  try setup(Opts) of
    {ok, ConnRef} -> 
      insert(ConnRef, ct:get_config(insert_jamdb), 0)
  catch
    Class:Exception ->
      ct:pal(
        "=[ERROR]=> ~p:~p:~p ~p:~p~n~p",
        [
            ?MODULE, ?FUNCTION_NAME, ?LINE, Class, Exception,
            erlang:get_stacktrace()
        ]
      ),
      0
  end.

insert(ConnRef, SqlFmt, Count) ->
  SQL = lists:flatten(io_lib:format(SqlFmt, [Count])),
  case catch jamdb_oracle:sql_query(ConnRef, SQL) of
    {ok, [{affected_rows, 1}]} ->
      if Count rem 1000 == 0 ->
        io:format(user, " ~p", [Count]);
        true -> ok
      end,
      insert(ConnRef, SqlFmt, Count + 1);
    {ok, [{proc_result, _, Error}]} ->
      io:format(user, " ~p~n", [Count]),
      ct:pal("===> Abort reason ~s", [Error]),
      Count;
    Error ->
      io:format(user, " ~p~n", [Count]),
      ct:pal("===> Abort reason ~p", [Error]),
      Count
  end.

select([{_,_} | _] = Opts) ->
  try setup(Opts) of
    {ok, ConnRef} -> 
      select(ConnRef, ct:get_config(insert_jamdb), 0)
  catch
    Class:Exception ->
      ct:pal(
        "=[ERROR]=> ~p:~p:~p ~p:~p~n~p",
        [
            ?MODULE, ?FUNCTION_NAME, ?LINE, Class, Exception,
            erlang:get_stacktrace()
        ]
      ),
      0
  end.

select(ConnRef, SqlFmt, Count) ->
  SQL = lists:flatten(io_lib:format(SqlFmt, [Count])),
  case catch jamdb_oracle:sql_query(ConnRef, SQL) of
    {ok, [{affected_rows, 1}]} ->
      if Count rem 1000 == 0 ->
          io:format(user, " ~p", [Count]);
          true -> ok
      end,
      select(ConnRef, SqlFmt, Count + 1);
    {ok, [{proc_result, _, Error}]} ->
      io:format(user, " ~p~n", [Count]),
      ct:pal("===> Abort reason ~s", [Error]),
      Count;
    Error ->
      ct:pal("===> Abort reason ~p", [Error]),
      io:format(user, " ~p~n", [Count]),
      Count
  end.

setup(Opts) ->
  {ok, ConnRef} = jamdb_oracle:start_link(Opts),
  {ok, []} = jamdb_oracle:sql_query(ConnRef, "COMON;"),
  case jamdb_oracle:sql_query(ConnRef, "drop table test") of
    {ok,[{proc_result, 942, _}]} -> ok;
    {ok,[{affected_rows,0}]} -> ok
  end,
  {ok,[{affected_rows,0}]} = jamdb_oracle:sql_query(
    ConnRef, "create table test (item varchar(1000))"
  ),
  {ok, ConnRef}.
