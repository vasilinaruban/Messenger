-module(registration_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    {ok, Body, Req1} = cowboy_req:read_body(Req0),
    Params = jsx:decode(Body, [return_maps]),  % Decode JSON body
    Username = maps:get(<<"username">>, Params, undefined),
    Password = maps:get(<<"password">>, Params, undefined),

    case {Username, Password} of
        {undefined, _} -> respond(Req1, 400, <<"Missing username">>);
        {_, undefined} -> respond(Req1, 400, <<"Missing password">>);
        _ ->
            case user_storage:add_user(binary_to_list(Username), binary_to_list(Password)) of
                true -> respond(Req1, 201, <<"User registered">>);
                false -> respond(Req1, 500, <<"Registration failed">>)
            end
    end.

respond(Req, Code, Message) ->
    cowboy_req:reply(Code, #{}, Message, Req).



