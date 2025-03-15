-module(options_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    Headers = #{
        <<"access-control-allow-origin">> => <<"*">>,
        <<"access-control-allow-methods">> => <<"POST, GET, OPTIONS">>,
        <<"access-control-allow-headers">> => <<"Content-Type">>,
        <<"access-control-max-age">> => <<"86400">>
    },
    Req1 = cowboy_req:reply(204, Headers, <<>>, Req0),
    {ok, Req1, State}.
