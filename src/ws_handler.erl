-module(ws_handler).
-behaviour(cowboy_websocket).

-export([init/2]).
-export([websocket_init/3]).
-export([websocket_handle/2]).
-export([websocket_info/2]).
-export([terminate/3]).

init(Req0, State) ->
    % Parse query string from the request
    Qs = cowboy_req:parse_qs(Req0),
    TokenParam = proplists:get_value(<<"token">>, Qs),

    case TokenParam of
        undefined ->
            % If no token is provided, reject the connection
            Req1 = cowboy_req:reply(401, #{}, <<"Missing or invalid token">>, Req0),
            {shutdown, Req1, State};
        TokenValue ->
            % Verify the token
            case verify_token(binary_to_list(TokenValue)) of
                {ok, Username} ->
                    % If the token is valid, proceed with the WebSocket connection
                    io:format("WebSocket connected for user: ~p Pid: ~p~n", [Username, self()]),
                    user_registry:add_user(Username, self()),
                    io:format("All users: ~p~n", [user_registry:get_all_users()]),
                    {cowboy_websocket, Req0, #{username => Username, pid => self()}};
                {error, Reason} ->
                    % If the token is invalid, reject the connection
                    Msg = io_lib:format("Invalid token: ~p", [Reason]),
                    Req1 = cowboy_req:reply(401, #{}, list_to_binary(Msg), Req0),
                    {shutdown, Req1, State}
            end
    end.

websocket_init(Req, _Opts, State = #{username := _Username}) ->
    MonitorRef = erlang:monitor(process, self()),
    {ok, TRef} = timer:apply_after(60000, self(), idle_timeout),
    {ok, Req, State#{monitor_ref => MonitorRef, idle_timer => TRef}}.


websocket_handle({text, Msg}, State = #{username := Sender}) ->
    try jsx:decode(Msg, [return_maps]) of
        #{<<"type">> := <<"message">>, <<"to">> := Receiver, <<"text">> := Message} ->
            case user_registry:get_user_pid(Receiver) of
                {ok, ReceiverPid} ->
                    case is_process_alive(ReceiverPid) of
                        true ->
                            Response = jsx:encode(#{
                                <<"type">> => <<"message">>,
                                <<"from">> => Sender,
                                <<"text">> => Message,
                                <<"timestamp">> => erlang:system_time(millisecond)
                            }),
                            ReceiverPid ! {send_message, Response},
                            io:format("Message sent to ~p~n", [ReceiverPid]);
                        false ->
                            io:format("User ~p is registered but process is dead~n", [Receiver])
                    end;
                {error, not_found} -> 
                    io:format("User ~p not found~n", [Receiver])
            end,
            {ok, State};
        Other ->
            io:format("Unexpected message format: ~p~n", [Other]),
            {reply, {text, jsx:encode(#{<<"error">> => <<"invalid_message_format">>})}, State}
    catch
        _:Error ->
            io:format("JSON decode error: ~p~n", [Error]),
            {reply, {text, jsx:encode(#{<<"error">> => <<"invalid_json">>})}, State}
    end;

websocket_handle(_Data, State) ->
    {ok, State}.


websocket_info({send_message, Message}, State) ->
    {reply, {text, Message}, State};

websocket_info({'DOWN', _Ref, process, Pid, Reason}, State) ->
    io:format("Process ~p died: ~p~n", [Pid, Reason]),
    user_registry:handle_down(Pid, Reason),
    {shutdown, State};

websocket_info(idle_timeout, #{username := Username} = State) ->
    io:format("Closing idle connection for ~p~n", [Username]),
    {shutdown, State};

websocket_info(_Info, State) ->
    {ok, State}.


terminate(_Reason, _Req, #{monitor_ref := Ref, idle_timer := TRef, username := Username}) ->
    timer:cancel(TRef),
    erlang:demonitor(Ref, [flush]),
    user_registry:remove_user(Username),
    ok;

terminate(_Reason, _Req, _State) ->
    ok.

% Function to verify the custom token
verify_token(Token) ->
    try
        % Decode the base64 token
        Decoded = base64:decode(Token),
        % Split the decoded value into username and password
        [Username, Password] = binary:split(Decoded, <<":">>),
        % Authenticate the user
        case user_storage:authenticate(binary_to_list(Username), binary_to_list(Password)) of
            true ->
                {ok, Username};
            false ->
                {error, invalid_credentials}
        end
    catch
        _:_ ->
            {error, invalid_token}
    end.


