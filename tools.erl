-module(tools).
-export([minKey/1,maxKey/1,localtime/0,nextKey/2]).
-author("Aleksandr Nosov").

minKey([]) -> 0;
minKey([X,Y|Tail])-> minKey(X,Y,Tail);
minKey([X|[]])-> X.
minKey(X,Y,[Head|Tail]) when X < Y -> minKey(X,Head,Tail);
minKey(X,Y,[Head|Tail]) when X > Y -> minKey(Y,Head,Tail);
minKey(X,Y,[]) when X >= Y -> Y;
minKey(X,Y,[]) when X < Y -> X.

maxKey([]) -> 0;
maxKey([X,Y|Tail])-> maxKey(X,Y,Tail);
maxKey([X|[]])-> X.
maxKey(X,Y,[Head|Tail]) when X > Y -> maxKey(X,Head,Tail);
maxKey(X,Y,[Head|Tail]) when X < Y -> maxKey(Y,Head,Tail);
maxKey(X,Y,[]) when X < Y -> Y;
maxKey(X,Y,[]) when X >= Y -> X.


nextKey(X,Y,_,[Head|Tail]) when X < Y -> nextKey(X,Y,Head,Tail);
nextKey(X,Y,Z,[Head|Tail]) when X > Y -> nextKey(X,Z,Head,Tail);
nextKey(X,Y,Z,List) when X >= Y, X >= Z -> nextKey(X,List);
nextKey(_,Y,Z,[]) when Y > Z -> Z;
nextKey(_,Y,Z,[]) when Y < Z -> Y.
nextKey(X,[Y,Z|Tail]) -> nextKey(X,Y,Z,Tail);
nextKey(_,[]) -> 0;
nextKey(X,[Y|[]]) when X < Y -> Y;
nextKey(_,_) -> 0.


%%Localtime in Sek.
localtime()->
	{_, Secs, _} = now(),
	Secs.