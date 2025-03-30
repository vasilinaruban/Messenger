-module(user_storage).
-export([add_user/2, authenticate/2, find_user/1, init/0]).

-record(user, {
    username :: binary(),
    password :: binary()
}).

init() ->
    case mnesia:create_table(user, [
        {attributes, record_info(fields, user)},
        {disc_copies, [node()]},
        {type, set}
    ]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, user}} -> ok;
        {aborted, Reason} -> 
            io:format("Failed to create user table: ~p~n", [Reason]),
            {error, Reason}
    end.

add_user(Username, Password) when is_list(Username) ->
    add_user(list_to_binary(Username), Password);
add_user(Username, Password) when is_list(Password) ->
    add_user(Username, list_to_binary(Password));
add_user(Username, Password) ->
    case mnesia:dirty_read(user, Username) of
        [] ->
            User = #user{username = Username, password = Password},
            case mnesia:transaction(fun() -> mnesia:write(User) end) of
                {atomic, ok} -> {ok, Username};
                {aborted, Reason} -> {error, Reason}
            end;
        [_] -> {error, user_exists}
    end.

authenticate(Username, Password) when is_list(Username) ->
    authenticate(list_to_binary(Username), Password);
authenticate(Username, Password) when is_list(Password) ->
    authenticate(Username, list_to_binary(Password));
authenticate(Username, Password) ->
    case mnesia:dirty_read(user, Username) of
        [#user{password = StoredPassword}] -> 
            Password =:= StoredPassword;
        _ -> false
    end.

find_user(Username) when is_list(Username) ->
    find_user(list_to_binary(Username));
find_user(Username) ->
    case mnesia:dirty_read(user, Username) of
        [#user{}] -> {ok, Username};
        [] -> {error, not_found}
    end.