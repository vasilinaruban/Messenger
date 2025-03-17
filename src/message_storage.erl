-module(message_storage).
-export([init/0, save_message/3, get_messages/1]).

-record(message, {
    sender,
    receiver,
    text,
    timestamp
}).

init() ->
    % mnesia:stop(),
    % mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(message, [
        {attributes, record_info(fields, message)},
        {disc_copies, [node()]}
    ]).

save_message(Sender, Receiver, Text) ->
	io:format("Saving message...~n"),
    Timestamp = erlang:system_time(millisecond),
    Message = #message{
        sender = Sender,
        receiver = Receiver, 
        text = Text, 
        timestamp = Timestamp
    },
    Fun = fun() -> mnesia:write(Message) end,
    case mnesia:transaction(Fun) of
    	{atomic, ok} ->
            io:format("Message is saved!"),
            {ok, Message};
    	{aborted, Reason} -> {error, Reason}
    end.

get_messages(Username) ->
    Fun = fun() ->
        mnesia:match_object({message, '_', Username, '_', '_'})
    end,
    case mnesia:transaction(Fun) of
    	{atomic, Messages} -> {ok, Messages};
    	{aborted, Reason} -> {error, Reason}
    end.