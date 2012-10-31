-module(client).
-export([start/0,randomSleepTime/1]).
-author("Aleksandr Nosov, Raimund Wege").

%% public function start
start()->
    {Clients, Lifetime, Servername, Intervall} = tools:getClientConfigData(),
	start({Servername, Lifetime, Intervall, Clients}).
start({Servername, Lifetime, Intervall, 1}) ->
	{ok, Hostname}=inet:gethostname(),
    start(1,{Hostname,Servername, Lifetime, Intervall});
start({Servername, Lifetime, Intervall, Clients}) ->
	{ok, Hostname}=inet:gethostname(),
    start(Clients,{Hostname,Servername, Lifetime, Intervall}),
    start({Servername, Lifetime, Intervall, Clients-1}).

%% Public start function
%% Server - Server name wie z.B. myserver in server:start(myserver).
%% Lifetime -> Lifetime des Clients in Sek.
%% SleepTime -> SleepTime zwischen dem Senden in Sek.
start(ClientID,{Hostname,Server, Lifetime, SleepTime}) ->
	log("starte client "++integer_to_list(ClientID)++"\n",ClientID,Hostname),
	Client=spawn(fun() -> loop({ClientID,Hostname,Server,0,SleepTime*1000}) end),
	spawn(fun() -> timer(Client,Lifetime*1000) end).
	
%% If counter < 5 then send messages	
loop({ClientID,Hostname,Server,Counter,SleepTime}) when Counter < 5 ->
	Server ! {getmsgid, self()}, 
	receive
		timeout -> log("client timeout\n",ClientID,Hostname);
		Number -> 
			Server ! {dropmessage,{message(Number,Hostname), Number}},
			NewSleepTime=randomSleepTime(SleepTime),
			sleep(NewSleepTime),
			loop({ClientID,Hostname,Server,Counter+1,NewSleepTime})
	end;
%% Wenn counter >= 5 dann lese messages	
loop({ClientID,Hostname,Server,Counter,SleepTime}) -> 
	Server ! {getmessages, self()}, 
	receive
		timeout -> log("client timeout\n",ClientID,Hostname);
		{Message,Terminated} -> 
			gotmessage({ClientID,Hostname,Server,Counter,SleepTime,Message,Terminated})
	end.
timer(Client,T) ->
	receive
	after
		T -> Client ! timeout 
	end.
gotmessage({ClientID,Hostname,Server,Counter,SleepTime,Message,false}) ->
	log("client "++integer_to_list(ClientID)++" gotmessage: "++Message++"; Terminated: false\n",ClientID,Hostname),
	loop({ClientID,Hostname,Server,Counter,SleepTime});
gotmessage({ClientID,Hostname,Server,_,SleepTime,Message,_}) ->
	log("client "++integer_to_list(ClientID)++" getmessage:"++Message++":; Terminated: true\n",ClientID,Hostname),
	loop({ClientID,Hostname,Server,0,SleepTime}).
	%%loop({Server,0}).
%% Erstellt eine neue Nachricht mit der Number
message(Number,Hostname)->
	Hostname++"-"++pid_to_list(self())++"-3-11:"++integer_to_list(Number)++"te_Nachricht. Sendezeit: "++werkzeug:timeMilliSecond().
randomSleepTime(SleepTime) ->
	N=random:uniform(2), %% 2 oder 1
	Time=SleepTime*(1.5-(N-1)),
	case Time < 1000 of
		true-> 1000;
		_ -> round(Time)
	end.
log(Message,ClientID,Hostname) ->
	werkzeug:logging("client_"++integer_to_list(ClientID)++Hostname++".log",Message).
	
%% Ist fur die Zeit T blockiert.	
sleep(T) ->
	receive
	after
		T -> 
			true
	end.