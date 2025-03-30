-module(user_storage).
-export([add_user/2, authenticate/2, find_user/1, init/0]).

-record(user, {
    username,
    password
}).

add_user(Username, Password) ->
    case mnesia:dirty_read(user, Username) of
        [] ->
            User = #user{username = Username, password = Password},
            case mnesia:transaction(fun() -> mnesia:write(User) end) of
                {atomic, ok} -> true;
                {aborted, {exists, _}} -> {error, user_exists};
                {aborted, _} -> false
            end;
        [_] -> {error, user_exists}
    end.

authenticate(Username, Password) ->
    Fun = fun() -> mnesia:read(user, Username) end,
    case mnesia:transaction(Fun) of
        {atomic, [#user{username = Username, password = Password}]} -> true;
        {atomic, []} -> 
            io:format("User not found"),
            false;
        {aborted, Reason} ->
            io:format("Transaction faild: ~p~n", [Reason]),
            false
    end.

find_user(Username) ->
    Fun = fun() ->
        case mnesia:read(user, Username) of
            [#user{username = Username}] -> {ok, Username};
            _ -> not_found
        end
    end,
    mnesia:transaction(Fun).

init() ->
    % mnesia:stop(),
    % mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(user, [
        {attributes, record_info(fields, user)},
        {disc_copies, [node()]}
    ]).