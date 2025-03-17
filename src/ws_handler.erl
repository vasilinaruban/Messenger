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
                    io:format("WebSocket connected for user: ~p~n", [Username]),
                    {cowboy_websocket, Req0, #{username => Username}};
                {error, Reason} ->
                    % If the token is invalid, reject the connection
                    Msg = io_lib:format("Invalid token: ~p", [Reason]),
                    Req1 = cowboy_req:reply(401, #{}, list_to_binary(Msg), Req0),
                    {shutdown, Req1, State}
            end
    end.

websocket_init(Req, _Opts, State) ->
    % Initialize the WebSocket connection
    {ok, Req, State}.

websocket_handle({text, Msg}, State = #{username := Sender}) ->
    message_storage:save_message(Sender, "receiver", Msg),
    Response = << "Echo: ", Msg/binary >>,
    {reply, {text, Response}, State};

websocket_handle(_Data, State) ->
    {ok, State}.

websocket_info(_Info, State) ->
    {ok, State}.

terminate(_Reason, _Req, #{username := Username}) ->
    io:format("WebSocket terminated for user: ~p~n", [Username]),
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


