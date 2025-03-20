-module(options_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    % Headers = #{
    %     <<"access-control-allow-origin">> => <<"*">>,
    %     <<"access-control-allow-methods">> => <<"POST, GET, OPTIONS">>,
    %     <<"access-control-allow-headers">> => <<"Content-Type">>,
    %     <<"access-control-max-age">> => <<"86400">>
    % },
    Req1 = cowboy_req:set_resp_header(<<"access-control-max-age">>, <<"1728000">>, Req0),
    Req2 = cowboy_req:set_resp_header(<<"access-control-allow-methods">>, <<"GET, POST, OPTIONS">>, Req1),
    Req3 = cowboy_req:set_resp_header(<<"access-control-allow-headers">>, <<"content-type, authorization">>, Req2),
    Req4 = cowboy_req:set_resp_header(<<"access-control-allow-origin">>, <<$*>>, Req3),
    {ok, Req4, State}.
