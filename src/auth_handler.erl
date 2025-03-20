-module(auth_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0, _State) ->
    {ok, Body, Req1} = cowboy_req:read_body(Req0),
    Params = jsx:decode(Body, [return_maps]),
    Username = maps:get(<<"username">>, Params, undefined),
    Password = maps:get(<<"password">>, Params, undefined),

    case {Username, Password} of
        {undefined, _} -> respond(Req1, 400, <<"Missing username">>);
        {_, undefined} -> respond(Req1, 400, <<"Missing password">>);
        _ ->
            case user_storage:authenticate(binary_to_list(Username), binary_to_list(Password)) of
                true ->
                    Token = base64:encode(<<Username/binary, ":", Password/binary>>),
                    respond(Req1, 200, jsx:encode(#{token => Token}));
                false ->
                    respond(Req1, 401, <<"Invalid credentials">>)
	        end		
    end.

respond(Req, Code, Message) ->
    % Headers = #{
    %     <<"access-control-allow-origin">> => <<"*">>,
    %     <<"access-control-allow-methods">> => <<"POST, GET, OPTIONS">>,
    %     <<"access-control-allow-headers">> => <<"Content-Type">>
    % },
    Req1 = cowboy_req:set_resp_header(<<"access-control-max-age">>, <<"1728000">>, Req),
    Req2 = cowboy_req:set_resp_header(<<"access-control-allow-methods">>, <<"GET, POST, OPTIONS">>, Req1),
    Req3 = cowboy_req:set_resp_header(<<"access-control-allow-headers">>, <<"content-type, authorization">>, Req2),
    Req4 = cowboy_req:set_resp_header(<<"access-control-allow-origin">>, <<$*>>, Req3),
    cowboy_req:reply(Code, #{}, Message, Req4).