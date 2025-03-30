-module(registration_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0=#{method := <<"POST">>}, State) ->
    try
        case cowboy_req:read_body(Req0) of
            {ok, Body, Req1} when Body =/= <<>> ->
                process_registration(Body, Req1);
            {ok, _, Req1} ->
                respond(Req1, 400, #{error => <<"Empty request body">>});
            {error, _} ->
                respond(Req0, 400, #{error => <<"Error reading body">>})
        end
    catch
        _:_ -> respond(Req0, 500, #{error => <<"Internal server error">>})
    end;
init(Req0, State) ->
    respond(Req0, 405, #{error => <<"Method not allowed">>}).

process_registration(Body, Req) ->
    try jsx:decode(Body, [return_maps]) of
        #{<<"username">> := Username, <<"password">> := Password} ->
            register_user(Username, Password, Req);
        _ ->
            respond(Req, 400, #{error => <<"Invalid request format">>})
    catch
        _:_ -> respond(Req, 400, #{error => <<"Malformed JSON">>})
    end.

register_user(Username, Password, Req) ->
    case user_storage:add_user(binary_to_list(Username), binary_to_list(Password)) of
        true -> 
            respond(Req, 201, #{status => <<"success">>});
        {error, user_exists} -> 
            respond(Req, 409, #{error => <<"Username already exists">>});
        _ -> 
            respond(Req, 500, #{error => <<"Registration failed">>})
    end.

respond(Req, Status, Body) ->
    Headers = #{
        <<"content-type">> => <<"application/json">>,
        <<"access-control-allow-origin">> => <<"*">>
    },
    cowboy_req:reply(Status, Headers, jsx:encode(Body), Req).