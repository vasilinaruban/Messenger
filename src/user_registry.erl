-module(user_registry).
-export([init/0, add_user/2, remove_user/1, get_user_pid/1]).

-define(CONNECTED_USERS, connected_users).

init() ->
    ets:new(?CONNECTED_USERS, [set, named_table, public]).

add_user(Username, Pid) ->
    ets:insert(?CONNECTED_USERS, {Username, Pid}).

remove_user(Username) ->
    ets:delete(?CONNECTED_USERS, Username).

get_user_pid(Username) ->
    case ets:lookup(?CONNECTED_USERS, Username) of
        [{Username, Pid}] -> {ok, Pid};
        [] -> {error, not_found}
    end.