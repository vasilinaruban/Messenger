-module(registration_ws_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
    io:format("Starting registration_ws application...~n"),
    
    {ok, _} = application:ensure_all_started(cowboy),
    {ok, _} = application:ensure_all_started(sasl),
    
    _InitUserStorage = case user_storage:init() of
        {atomic, ok} -> ok;
        UserStorageError -> 
            io:format("Warning: user_storage init returned ~p~n", [UserStorageError]),
            UserStorageError
    end,
    
    _InitMessageStorage = case message_storage:init() of
        {atomic, ok} -> ok;
        MessageStorageError -> 
            io:format("Warning: message_storage init returned ~p~n", [MessageStorageError]),
            MessageStorageError
    end,
    
    user_registry:init(),
    
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/register", registration_handler, []},
            {"/auth", auth_handler, []},
            {"/ws", ws_handler, []},
            {"/static/[...]", cowboy_static, {priv_dir, registration_ws, "static"}},
            {"/[...]", options_handler, []}
        ]}
    ]),
    
    io:format("Dispatch table created. Starting Cowboy server...~n"),
    
    case cowboy:start_clear(http, [{port, 8080}], #{
        env => #{dispatch => Dispatch},
        middlewares => [cowboy_router, cowboy_handler]
    }) of
        {ok, _} -> 
            io:format("Cowboy server started on port 8080.~n"),
            {ok, self()};
        {error, CowboyError} ->
            io:format("Failed to start Cowboy: ~p~n", [CowboyError]),
            {error, CowboyError}
    end.

stop(_State) ->
    cowboy:stop_listener(http),
    ok.