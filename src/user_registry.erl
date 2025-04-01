-module(user_registry).
-export([init/0, add_user/2, remove_user/1, get_user_pid/1, get_all_users/0, handle_down/2, is_online/1]).

-define(CONNECTED_USERS, connected_users).

init() ->
    ets:new(?CONNECTED_USERS, [set, named_table, public, {keypos, 1}]).

add_user(Username, Pid) ->
    MonitorRef = erlang:monitor(process, Pid),
    ets:insert(?CONNECTED_USERS, {Username, Pid, MonitorRef}).

remove_user(Pid) when is_pid(Pid) ->
    case ets:match_object(?CONNECTED_USERS, {'_', Pid, '_'}) of
        [{Username, _, MonitorRef}] ->
            erlang:demonitor(MonitorRef, [flush]),
            ets:delete(?CONNECTED_USERS, Username);
        [] -> ok
    end;

remove_user(Username) ->
    case ets:lookup(?CONNECTED_USERS, Username) of
        [{Username, _Pid, MonitorRef}] ->
            erlang:demonitor(MonitorRef, [flush]),
            ets:delete(?CONNECTED_USERS, Username);
        [] -> ok
    end.

get_user_pid(Username) ->
    case ets:lookup(?CONNECTED_USERS, Username) of
        [{Username, Pid, _}] -> {ok, Pid};
        [] -> {error, not_found}
    end.

is_online(Username) ->
    case get_user_pid(Username) of
        {ok, _} -> online;
        _ -> offline
    end.

get_all_users() ->
    ets:match_object(?CONNECTED_USERS, {'$1', '$2', '_'}).

handle_down(Pid, Reason) ->
    case ets:match_object(?CONNECTED_USERS, {'_', Pid, '_'}) of
        [{Username, _, _}] ->
            io:format("User ~p process ~p died: ~p~n", [Username, Pid, Reason]),
            remove_user(Username);
        [] -> ok
    end.