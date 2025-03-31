-module(registration_handler).
-behaviour(cowboy_handler).

-export([init/2]).


init(Req0, State) ->
    {ok, Data, Req1} = cowboy_req:read_body(Req0),
    try jsx:decode(Data, [return_maps]) of
        #{<<"username">> := Username, <<"password">> := Password} ->
            case user_storage:add_user(Username, Password) of
                {ok, _} ->
                    Response = jsx:encode(#{<<"status">> => <<"success">>}),
                    Req = cowboy_req:reply(200, #{
                        <<"content-type">> => <<"application/json">>
                    }, Response, Req1),
                    {ok, Req, State};
                {error, Reason} ->
                    Response = jsx:encode(#{
                        <<"error">> => Reason,
                        <<"details">> => <<"Registration failed">>
                    }),
                    Req = cowboy_req:reply(500, #{
                        <<"content-type">> => <<"application/json">>
                    }, Response, Req1),
                    {ok, Req, State}
            end;
        _ ->
            Response = jsx:encode(#{
                <<"error">> => <<"invalid_format">>,
                <<"details">> => <<"Username and password required">>
            }),
            Req = cowboy_req:reply(400, #{
                <<"content-type">> => <<"application/json">>
            }, Response, Req1),
            {ok, Req, State}
    catch
        _:_ ->
            Response = jsx:encode(#{
                <<"error">> => <<"invalid_json">>,
                <<"details">> => <<"Invalid JSON format">>
            }),
            Req = cowboy_req:reply(400, #{
                <<"content-type">> => <<"application/json">>
            }, Response, Req1),
            {ok, Req, State}
    end.