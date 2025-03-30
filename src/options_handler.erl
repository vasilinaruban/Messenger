-module(options_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    Req1 = cowboy_req:set_resp_header(<<"access-control-allow-methods">>, 
                                     <<"GET, POST, OPTIONS">>, Req0),
    Req2 = cowboy_req:set_resp_header(<<"access-control-allow-headers">>, 
                                     <<"content-type">>, Req1),
    Req3 = cowboy_req:set_resp_header(<<"access-control-allow-origin">>, 
                                     <<"*">>, Req2),
    cowboy_req:reply(200, Req3, State).