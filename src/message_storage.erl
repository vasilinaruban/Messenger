-module(message_storage).
-export([init/0, save_message/3, get_messages/1]).

-record(message, {
    sender :: binary(),
    receiver :: binary(),
    text :: binary(),
    timestamp :: integer()
}).

init() ->
    case mnesia:create_table(message, [
        {attributes, record_info(fields, message)},
        {disc_copies, [node()]},
        {type, bag}
    ]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, message}} -> ok;
        {aborted, Reason} -> {error, Reason}
    end.

save_message(Sender, Receiver, Text) when is_list(Sender) ->
    save_message(list_to_binary(Sender), Receiver, Text);
save_message(Sender, Receiver, Text) when is_list(Receiver) ->
    save_message(Sender, list_to_binary(Receiver), Text);
save_message(Sender, Receiver, Text) when is_list(Text) ->
    save_message(Sender, Receiver, list_to_binary(Text));
save_message(Sender, Receiver, Text) ->
    Timestamp = erlang:system_time(millisecond),
    Message = #message{
        sender = Sender,
        receiver = Receiver, 
        text = Text, 
        timestamp = Timestamp
    },
    case mnesia:transaction(fun() -> mnesia:write(Message) end) of
        {atomic, ok} -> {ok, Message};
        {aborted, Reason} -> {error, Reason}
    end.

get_messages(Username) when is_list(Username) ->
    get_messages(list_to_binary(Username));
get_messages(Username) ->
    MatchHead = #message{receiver=Username, _='_'},
    Guard = [],
    Result = ['$_'],
    case mnesia:transaction(fun() -> mnesia:select(message, [{MatchHead, Guard, Result}]) end) of
        {atomic, Messages} -> {ok, Messages};
        {aborted, Reason} -> {error, Reason}
    end.