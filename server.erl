-module(server).
-export([start/0,start/1,checkclient/1,dropmessage/5]).
-author("Aleksandr Nosov, Raimund Wege").

start() ->
    start(tools:getServerConfigData()).
%% public function start
start({Name,MaxCountDQ,Timeout,ReTime}) ->
	ServerPID = spawn(fun() -> loop(1,dict:new(),dict:new(),dict:new(),Timeout*1000,MaxCountDQ,ReTime) end),
	register(Name,ServerPID).
	
loop(MsgId,ClientDict,HQ,DQ,Timeout,MaxCountDQ,ReTime) ->
	receive
		{getmsgid, ClientID} -> 
			ClientID ! MsgId,
			werkzeug:logging("NServer.log","getmsgid: "++integer_to_list(MsgId)++" \n"),
			loop(MsgId+1,ClientDict,HQ,DQ,Timeout,MaxCountDQ,ReTime);
		{dropmessage, {Message, Number}} ->
			{NewHQ,NewDQ}=dropmessage(Number,Message,HQ,DQ,MaxCountDQ),
			werkzeug:logging("NServer.log","dropmessage "++integer_to_list(Number)++":"++Message++".\n"),
			loop(MsgId,ClientDict,NewHQ,NewDQ,Timeout,MaxCountDQ,ReTime);
		{getmessages, ClientID} ->
			{NewClientDict,{LastMsgid,ClientTimer}}=checkclient({ClientDict,ClientID},ReTime),
			{MessageId,Message,Terminated} = getmessage(LastMsgid,DQ),
			ClientID ! {Message,Terminated},
			NewClientDict2=dict:store(ClientID,{MessageId,ClientTimer},NewClientDict),
			loop(MsgId,NewClientDict2,HQ,DQ,Timeout,MaxCountDQ,ReTime)
	after
		Timeout -> werkzeug:logging("NServer.log","server timeout.\n")
	end.

%%Nachricht speichern	
dropmessage(Number,Message,HQ,DQ,MaxCountDQ) ->
	NewHQ=dict:append(Number,Message,HQ),
	MinKey=tools:minKey(dict:fetch_keys(NewHQ)),
	MaxKey=tools:maxKey(dict:fetch_keys(DQ)),
	put_in_dq(MinKey,MaxKey,NewHQ,DQ,MaxCountDQ,dict:size(NewHQ),dict:size(DQ)).

%% Erst DQ anpassen. =< weil minKey bzw. maxKey = 0, wenn HQ bzw. DQ leer sind.
put_in_dq(MinKeyHQ,MaxKeyDQ,HQ,DQ,MaxCountDQ,HQSize,DQSize) when MaxCountDQ =:= DQSize ->
	NewDQ=dict:erase(tools:minKey(dict:fetch_keys(DQ)),DQ),
	put_in_dq(MinKeyHQ,MaxKeyDQ,HQ,NewDQ,MaxCountDQ,HQSize,DQSize-1);
%%Nachricht in DQ ubertragen. 
put_in_dq(MinKeyHQ,MaxKeyDQ,HQ,DQ,MaxCountDQ,HQSize,DQSize) when MaxKeyDQ+1 =:= MinKeyHQ, MaxCountDQ > DQSize ->
	%%werkzeug:logging("NServer.log","Nachricht"++integer_to_list(MinKeyHQ)++" in DQ wird uebertragen\n"),
	{ok, Value} = dict:find(MinKeyHQ,HQ),
	NewDQ=dict:append(MinKeyHQ,Value,DQ),
	NewHQ=dict:erase(MinKeyHQ,HQ),
	MinKey=tools:minKey(dict:fetch_keys(NewHQ)),
	MaxKey=tools:maxKey(dict:fetch_keys(NewDQ)),
	put_in_dq(MinKey,MaxKey,NewHQ,NewDQ,MaxCountDQ,HQSize-1,DQSize+1);
%%Lucke schliessen. Danach mit naechster ID weiter machen.
put_in_dq(MinKeyHQ,MaxKeyDQ,HQ,DQ,MaxCountDQ,HQSize,DQSize) when HQSize > MaxCountDQ/2, MaxCountDQ > DQSize ->
	werkzeug:logging("NServer.log","Nachricht "++integer_to_list(MinKeyHQ-1)++"  fehlt\n"),
	Value=errorMessage(MinKeyHQ-1,MaxKeyDQ+1),
	NewDQ=dict:append(MinKeyHQ-1,Value,DQ),
	MaxKey=tools:maxKey(dict:fetch_keys(NewDQ)),
	put_in_dq(MinKeyHQ,MaxKey,HQ,NewDQ,MaxCountDQ,HQSize,DQSize+1);
%%sonst nichts machen.
put_in_dq(_,_,HQ,DQ,_,_,_) -> 
	{HQ,DQ}.

errorMessage(KeyHQ,KeyDQ) ->
	"***Fehlernachricht fuer Nachrichtennummern "++integer_to_list(KeyDQ)++" bis "++integer_to_list(KeyHQ)++" um "++werkzeug:timeMilliSecond()++";".

%%Naechste Nachricht aus DQ
getmessage(LastMsgid,DQ)->
	Key=tools:nextKey(LastMsgid,dict:fetch_keys(DQ)),
	Message=getmessage(dict:find(Key,DQ)),
	{Key,Message,not dict:is_key(Key+1,DQ)}.
	
getmessage({ok,Message}) -> Message;
getmessage(error) -> "undefined".

%%Client in ClientDict prufen und ggf. eintragen mit LastTime und Msgid
checkclient({ClientDict,ClientID},ReTime) ->
	NewCDict=eraseold(ClientDict,ReTime),
	checkclient({dict:find(ClientID,NewCDict),NewCDict,ClientID}).
checkclient({error,ClientDict,ClientID}) ->
	checkclient({{ok,{0,tools:localtime()}},ClientDict,ClientID});
%%Zugrifszeit aktualisieren.
checkclient({{ok,ClientValue},ClientDict,ClientID}) ->
	{Msgid,_} = ClientValue,
	Value={Msgid,tools:localtime()},
	NewDict=dict:store(ClientID,Value,ClientDict),
	{NewDict,ClientValue}.
eraseold(ClientDict,ReTime) ->
	{_, Secs , _} = now(),
	dict:filter(fun(_,{_,Time}) ->Secs-Time < ReTime  end, ClientDict).
