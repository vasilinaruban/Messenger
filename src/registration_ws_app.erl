-module(registration_ws_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _Args) ->
    io:format("Starting registration_ws application...~n"),
    
    case application:ensure_all_started(cowboy) of
        {ok, _} ->
            case application:ensure_all_started(sasl) of
                {ok, _} ->
                    start_mnesia();
                {error, SASLReason} ->
                    {error, {sasl_start_failed, SASLReason}}
            end;
        {error, CowboyReason} ->
            {error, {cowboy_start_failed, CowboyReason}}
    end.

start_mnesia() ->
    case mnesia:system_info(is_running) of
        no -> 
            io:format("Starting Mnesia...~n"),
            case mnesia:create_schema([node()]) of
                ok -> ok;
                {error, {_, {already_exists, _}}} -> ok;
                Error -> Error
            end,
            case mnesia:start() of
                ok -> init_tables();
                {error, {already_started, _}} -> init_tables();
                {error, MnesiaReason} ->
                    {error, {mnesia_start_failed, MnesiaReason}}
            end;
        _ -> init_tables()
    end.

init_tables() ->
    case mnesia:wait_for_tables([user, message], 5000) of
        ok -> 
            io:format("Tables are ready~n"),
            init_storages();
        {timeout, MissingTables} ->
            io:format("Warning: timeout waiting for tables: ~p~n", [MissingTables]),
            case recreate_tables(MissingTables) of
                ok -> init_storages();
                Error -> Error
            end;
        {error, Reason} ->
            io:format("Error waiting for tables: ~p~n", [Reason]),
            {error, {tables_wait_failed, Reason}}
    end.

recreate_tables(Tables) ->
    lists:foreach(fun(Table) ->
        mnesia:delete_table(Table),
        case Table of
            user -> user_storage:init();
            message -> message_storage:init()
        end
    end, Tables),
    ok.

init_storages() ->
    case user_storage:init() of
        ok -> 
            io:format("User storage initialized successfully~n"),
            case message_storage:init() of
                ok -> 
                    case contact_storage:init() of 
                        ok ->
                            io:format("Message storage initialized~n"),
                            start_cowboy();
                        {error, Reason} ->
                            io:format("Contact storage init failed: ~p~n", [Reason]),
                            {error, {contact_storage_failed, Reason}}  
                    end;
                {error, Reason} ->
                    io:format("Message storage init failed: ~p~n", [Reason]),
                    {error, {message_storage_failed, Reason}}
            end;
        {error, Reason} ->
            io:format("User storage init failed: ~p~n", [Reason]),
            {error, {user_storage_failed, Reason}}
    end.


start_cowboy() ->
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
    
    case cowboy:start_clear(http, [{port, 8080}], #{
        env => #{dispatch => Dispatch},
        middlewares => [cowboy_router, cowboy_handler]
    }) of
        {ok, _} -> 
            io:format("Cowboy server started on port 8080~n"),
            {ok, self()};
        {error, CowboyError} ->
            io:format("Cowboy start failed: ~p~n", [CowboyError]),
            {error, {cowboy_start_failed, CowboyError}}
    end.

stop(_State) ->
    cowboy:stop_listener(http),
    ok.