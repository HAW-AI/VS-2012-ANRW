-module(werkzeug).
-export([get_config_value/2,logging/2,logstop/0,timeMilliSecond/0,delete_last/1,shuffle/1,reset_timer/3]).
-define(ZERO, integer_to_list(0)).

%% -------------------------------------------
% Werkzeug
%%
%% Sucht aus einer Config-Liste die gewünschten Einträge
% Beispielaufruf: 	{ok, ConfigListe} = file:consult("server.cfg"),
%                  	{ok, Lifetime} = get_config_value(lifetime, ConfigListe),
%
get_config_value(Key, []) ->
	{nok, Key};
get_config_value(Key, [{Key, Value} | _ConfigT]) ->
	{ok, Value};
get_config_value(Key, [{_OKey, _Value} | ConfigT]) ->
	get_config_value(Key, ConfigT).

% Schreibt auf den Bildschirm und in eine Datei
% nebenläufig zur Beschleunigung
% Beispielaufruf: logging("FileName.log","Textinhalt"),
%
logging(Datei,Inhalt) -> Known = erlang:whereis(logklc),
						case Known of
						undefined -> PIDlogklc = spawn(fun() -> logloop(0) end),
								 erlang:register(logklc,PIDlogklc);
								_NotUndef -> ok
						end,
						logklc ! {Datei,Inhalt},
						ok.

logstop( ) -> 	Known = erlang:whereis(logklc),
				case Known of
					undefined -> false;
					_NotUndef -> logklc ! kill, true
				end.
					
logloop(Y) -> 	receive
					{Datei,Inhalt} -> io:format(Inhalt),
									  file:write_file(Datei,Inhalt,[append]),
									  logloop(Y+1);
					kill -> true
				end.

%% Löscht das letzte Element einer Liste
% Beispielaufruf: Erg = delete_last([a,b,c]),
%
delete_last([]) -> [];
delete_last([_Head]) -> [ ];
delete_last([Head|Tail]) -> [Head|delete_last(Tail)].

% schneller:
% delete_last(List) ->
%   [_|B] = lists:reverse(List),
%   lists:reverse(B).

%% Mischt eine Liste
% Beispielaufruf: NeueListe = shuffle([a,b,c]),
%
shuffle(List) -> shuffle(List, []).
shuffle([], Acc) -> Acc;
shuffle(List, Acc) ->
    {Leading, [H | T]} = lists:split(random:uniform(length(List)) - 1, List),
    shuffle(Leading ++ T, [H | Acc]).

%%
% Unterbricht den aktuellen Timer
% und erstellt einen neuen und gibt ihn zurück
%%
reset_timer(Timer,Sekunden,Message) ->
	{ok, cancel} = timer:cancel(Timer),
	{ok,TimerNeu} = timer:send_after(Sekunden*1000,Message),
	TimerNeu.
	
%% Zeitstempel: 'MM.DD HH:MM:SS,SSS'
% Beispielaufruf: Text = lists:concat([Clientname," Startzeit: ",timeMilliSecond()]),
%
timeMilliSecond() ->
	{_Year, Month, Day} = date(),
	{Hour, Minute, Second} = time(),
	Tag = lists:concat([klebe(Day,""),".",klebe(Month,"")," ",klebe(Hour,""),":"]),
	{_, _, MicroSecs} = now(),
	Tag ++ concat([Minute,Second],":") ++ "," ++ toMilliSeconds(MicroSecs)++"|".
toMilliSeconds(MicroSecs) ->
	Seconds = MicroSecs / 1000000,
	string:substr( float_to_list(Seconds), 3, 3).
concat(List, Between) -> concat(List, Between, "").
concat([], _, Text) -> Text;
concat([First|[]], _, Text) ->
	concat([],"",klebe(First,Text));
concat([First|List], Between, Text) ->
	concat(List, Between, string:concat(klebe(First,Text), Between)).
klebe(First,Text) -> 	
	NumberList = integer_to_list(First),
	string:concat(Text,minTwo(NumberList)).	
minTwo(List) ->
	case {length(List)} of
		{0} -> ?ZERO ++ ?ZERO;
		{1} -> ?ZERO ++ List;
		_ -> List
	end.