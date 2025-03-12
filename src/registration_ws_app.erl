-module(registration_ws_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
    io:format("Starting registration_ws application...~n"),
    application:ensure_all_started(cowboy),
    application:ensure_all_started(sasl),
    user_storage:init(),
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/register", registration_handler, []},
            {"/auth", auth_handler, []},
            {"/ws", ws_handler, []}
        ]}
    ]),
    io:format("Dispatch table created. Starting Cowboy server...~n"),
    {ok, _} = cowboy:start_clear(http, [{port, 8080}], #{
        env => #{dispatch => Dispatch}
    }),
    io:format("Cowboy server started on port 8080.~n"),
    {ok, self()}.

stop(_State) ->
    ok.
