-module(contact_storage).
-export([init/0, add_contact/2, remove_contact/2, get_contacts/1, is_contact/2]).

-record(contact, {
    owner :: binary(),    
    username :: binary()  
}).

init() ->
    case mnesia:create_table(contact, [
        {attributes, record_info(fields, contact)},
        {disc_copies, [node()]},
        {type, bag}, 
        {index, [username]}  
    ]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, contact}} -> ok;
        {aborted, Reason} -> 
            io:format("Failed to create contact table: ~p~n", [Reason]),
            {error, Reason}
    end.

add_contact(Owner, Contact) when is_list(Owner) ->
    add_contact(list_to_binary(Owner), Contact);
add_contact(Owner, Contact) when is_list(Contact) ->
    add_contact(Owner, list_to_binary(Contact));
add_contact(Owner, Contact) ->
    case {user_storage:find_user(Owner), user_storage:find_user(Contact)} of
        {{ok, _}, {ok, _}} ->
            case is_contact(Owner, Contact) of
                true -> 
                    {error, already_exists};
                false ->
                    Rec = #contact{owner = Owner, username = Contact},
                    case mnesia:transaction(fun() -> mnesia:write(Rec) end) of
                        {atomic, ok} -> ok;
                        {aborted, Reason} -> {error, Reason}
                    end
            end;
        {{error, not_found}, _} -> {error, owner_not_found};
        {_, {error, not_found}} -> {error, contact_not_found}
    end.

remove_contact(Owner, Contact) when is_list(Owner) ->
    remove_contact(list_to_binary(Owner), Contact);
remove_contact(Owner, Contact) when is_list(Contact) ->
    remove_contact(Owner, list_to_binary(Contact));
remove_contact(Owner, Contact) ->
    case mnesia:transaction(fun() ->
        Pattern = #contact{owner = Owner, username = Contact, _ = '_'},
        mnesia:match_object(Pattern)
    end) of
        {atomic, []} -> {error, not_found};
        {atomic, Records} ->
            DeleteFun = fun() -> 
                lists:foreach(fun(Rec) -> mnesia:delete_object(Rec) end, Records)
            end,
            case mnesia:transaction(DeleteFun) of
                {atomic, ok} -> ok;
                {aborted, Reason} -> {error, Reason}
            end;
        {aborted, Reason} -> {error, Reason}
    end.

get_contacts(Owner) when is_list(Owner) ->
    get_contacts(list_to_binary(Owner));
get_contacts(Owner) ->
    case mnesia:dirty_match_object(#contact{owner = Owner, _ = '_'}) of
        Contacts when is_list(Contacts) ->
            {ok, lists:map(fun(#contact{username = U}) -> U end, Contacts)};
        _ -> {error, not_found}
    end.

is_contact(Owner, Contact) when is_list(Owner) ->
    is_contact(list_to_binary(Owner), Contact);
is_contact(Owner, Contact) when is_list(Contact) ->
    is_contact(Owner, list_to_binary(Contact));
is_contact(Owner, Contact) ->
    case mnesia:dirty_read(contact, Owner) of
        [] -> false;
        Contacts -> 
            lists:any(fun(#contact{username = C}) -> C =:= Contact end, Contacts)
    end.