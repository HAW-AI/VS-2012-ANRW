-module(client).
-export([start/1]).
-author("Aleksandr Nosov, Raimund Wege").

%% public function start
%% Server - Server name wie z.B. myserver in server:start(myserver).
start(Server) ->
	spawn(fun() -> loop({Server,0}) end).
	
%% If counter < 5 then send messages	
loop({Server,Counter}) when Counter < 5 ->
	Server ! {getmsgid, self()}, 
	receive
		timeout -> done;
		Number -> 
			Server ! {dropmessage,{message(Number), Number}},
			sleep(200),
			loop({Server,Counter+1})
	end;
%% Wenn counter >= 5 dann lese messages	
loop({Server,Counter}) -> 
	Server ! {getmessages, self()}, 
	receive
		timeout -> done;
		{Message,Terminated} -> 
			werkzeug:logging("client.log","getmessages:"++Message++":"++atom_to_list(Terminated)++"\n")
			%%if not Terminated ->
			%%	loop({Server,Counter});
			%%	true ->  loop({Server,0})
			%%end	
	end.

%% Erstellt eine neue Nachricht mit der Number
message(Number)->
	"host-"++"-3-11:"++integer_to_list(Number)++"te_Nachricht. Sendezeit: "++werkzeug:timeMilliSecond().

%% Ist fur die Zeit T blockiert.	
sleep(T) ->
	receive
	after
		T ->
			true
	end.