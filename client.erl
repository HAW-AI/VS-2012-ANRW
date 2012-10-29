-module(client).
-export([start/2]).
-author("Aleksandr Nosov, Raimund Wege").

%% public function start
%% Server - Server name wie z.B. myserver in server:start(myserver).
start(Server) ->
	spawn(fun() -> loop({Server,0}) end).
	
%% If counter < 5 then send messages	
loop({Server,Counter}) when Counter < 5 ->
	Server ! {getmsgid, self()}, 
	receive
		Number -> 
			Server ! {dropmessage,{message(Number), Number},
			sleep(),
			loop({Server,Counter+1})	
	end.
%% Wenn counter >= 5 dann lese messages	
loop({Server,Counter}) -> done.

%% Erstellt eine neue Nachricht mit der Number
message(Number)->
	"host-"++self()++"-3-11:"++integer_to_list(Number)++"te_Nachricht. Sendezeit: "++localtime()++";\n".

%% Gibt localtime als Zeichenkette zuruck 	
localtime() ->
	{_,{Hour, Minutes, Seconds}} = erlang:localtime(),
    integer_to_list(Hour)++":"++integer_to_list(Minutes)++":"++integer_to_list(Seconds).
	
sleep() -> kommtspaeter.