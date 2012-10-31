-module(client).
-export([start/1]).
-author("Aleksandr Nosov, Raimund Wege").

%% public function start
%% Server - Server name wie z.B. myserver in server:start(myserver).
start(Server) ->
	Timer = 20*1000,
	SleepTime = 2000,
	Client=spawn(fun() -> loop({Server,0,SleepTime}) end),
	spawn(fun() -> timer(Client,Timer) end).
%% If counter < 5 then send messages	
loop({Server,Counter,SleepTime}) when Counter < 5 ->
	Server ! {getmsgid, self()}, 
	receive
		timeout -> werkzeug:logging("client.log","client timeout\n");
		Number -> 
			Server ! {dropmessage,{message(Number), Number}},
			NewSleepTime=randomSleepTime(SleepTime),
			sleep(NewSleepTime),
			loop({Server,Counter+1,NewSleepTime})
	end;
%% Wenn counter >= 5 dann lese messages	
loop({Server,Counter,SleepTime}) -> 
	Server ! {getmessages, self()}, 
	receive
		timeout -> werkzeug:logging("client.log","client timeout\n");
		{Message,Terminated} -> 
			gotmessage({Server,Counter,SleepTime,Message,Terminated})
	end.
timer(Client,T) ->
	receive
	after
		T -> Client ! timeout 
	end.
gotmessage({Server,Counter,SleepTime,Message,false}) ->
	werkzeug:logging("client.log","gotmessage: "++Message++"; Terminated: false\n"),
	loop({Server,Counter,SleepTime});
gotmessage({Server,_,SleepTime,Message,_}) ->
	werkzeug:logging("client.log","getmessages:"++Message++":; Terminated: true\n"),
	loop({Server,0,SleepTime}).
	%%loop({Server,0}).
%% Erstellt eine neue Nachricht mit der Number
message(Number)->
	"host-"++pid_to_list(self())++"-3-11:"++integer_to_list(Number)++"te_Nachricht. Sendezeit: "++werkzeug:timeMilliSecond().
randomSleepTime(SleepTime) ->
	N=random:uniform(2), %% 2 oder 1
	Time=SleepTime*(1.5+(N-1)),
	case Time < 1000 of
		true->randomSleepTime(Time);
		_ -> round(Time)
	end.
%% Ist fur die Zeit T blockiert.	
sleep(T) ->
	receive
	after
		T ->
			true
	end.