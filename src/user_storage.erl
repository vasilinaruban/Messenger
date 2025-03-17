-module(user_storage).
-export([add_user/2, authenticate/2, find_user/1, init/0]).

-record(user, {
    username,
    password
}).

% -define(USER_DB, user_db).

% add_user(Username, Password) ->
%     ets:insert(?USER_DB, {Username, Password}).

% authenticate(Username, Password) ->
%     case ets:lookup(?USER_DB, Username) of
%         [{Username, Password}] -> true;
%         _ -> false
%     end.

% find_user(Username) ->
%     case ets:lookup(?USER_DB, Username) of
%         [{Username, _Password}] -> {ok, Username};
%         _ -> not_found
%     end.

% init() ->
%     ets:new(?USER_DB, [set, named_table, public]).

add_user(Username, Password) ->
	io:format("Saving message...~n"),
    User = #user{
        username = Username,
        password = Password
    },
    Fun = fun() -> mnesia:write(User) end,
    case mnesia:transaction(Fun) of
        {atomic, ok} -> true;
        {aborted, _Reason} -> false
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