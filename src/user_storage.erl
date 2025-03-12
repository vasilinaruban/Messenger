-module(user_storage).
-export([add_user/2, authenticate/2, find_user/1, init/0]).

-define(USER_DB, user_db).

add_user(Username, Password) ->
    ets:insert(?USER_DB, {Username, Password}).

authenticate(Username, Password) ->
    case ets:lookup(?USER_DB, Username) of
        [{Username, Password}] -> true;
        _ -> false
    end.

find_user(Username) ->
    case ets:lookup(?USER_DB, Username) of
        [{Username, _Password}] -> {ok, Username};
        _ -> not_found
    end.

init() ->
    ets:new(?USER_DB, [set, named_table, public]).

