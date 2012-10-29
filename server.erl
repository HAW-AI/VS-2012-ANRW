-module(server).
-export([start/1]).
-author("Aleksandr Nosov, Raimund Wege").

%% public function start
start(Name) ->
	ServerPID = spawn(fun() -> loop() end),
	register(Name,ServerPID).
	
loop() ->
	%%erlang:start_timer(Timeout, self(), sendTimeout),
	receive
		{getmsgid, ClientID} -> 
			ClientID ! 12
	end.