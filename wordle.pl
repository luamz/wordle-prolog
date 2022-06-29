% WordlUFF
% Desenvolvido por Lucas Fauster e Luam Souza
% SWI-Prolog(8.4.2)

le_arquivo(Stream,[]) :-
    at_end_of_stream(Stream).

le_arquivo(Stream,[X|L]) :-
    \+ at_end_of_stream(Stream),
    read_line_to_codes(Stream,Codes),
    atom_chars(X, Codes),
    le_arquivo(Stream,L), !.

% Verifica se um elemento pertence a uma lista
pertence(X,[X|_]).
pertence(X, [_|Y]) :- pertence(X, Y).

% Adiciona palavra tentada na lista de palavras tentadas
junta_lista(L, [ ], L).
junta_lista([ ], L, L).
junta_lista([X|L1], L2, [X|L3]) :-
    junta_lista(L1,L2,L3).

verifica_tamanho(TamPalavra) :-
	4 =< TamPalavra, 7 >= TamPalavra ; 
    ansi_format([bold, fg(red)],'ERRO: O número de letras deve estar entre 4 e 7!\n',[]),
    fail.

define_tamanho(TamPalavra) :-
    write('Digite o número de letras da palavra:\n'), 
    read(TamPalavra), integer(TamPalavra)-> verifica_tamanho(TamPalavra);
    ansi_format([bold, fg(red)],'ERRO: Somente números são aceitos!\n',[]),
    fail.

seleciona_palavra(TamPalavra, Palavra, Letras) :-
    le_palavras(TamPalavra,Palavras), random(0, 900, Selecionada),
    letra_indice(Selecionada, Palavras, Palavra), atom_chars(Palavra, Letras).

% Lê somente as palvras com a quantidade de dígitos selecionado
le_palavras(TamPalavra, Palavras) :-
    (
        4 = TamPalavra -> open('tamanho-4.txt',read, Stream);
        5 = TamPalavra -> open('tamanho-5.txt',read, Stream);
        6 = TamPalavra -> open('tamanho-6.txt',read, Stream);
        7 = TamPalavra -> open('tamanho-7.txt',read, Stream)
    ) 
    -> le_arquivo(Stream,Palavras), close(Stream).

proxima_tentativa(Tentativa, Proxima_Tentativa) :- Proxima_Tentativa is Tentativa - 1.

igual(X,Y) :- X == Y -> true ; false.

jogar_novamente:-
    write('Deseja jogar novamente? Digite \"sim\" ou \"nao\"\n'), read(Resposta),
    igual(Resposta,"sim") ->  nl, nl, main(); halt(0).

ganhou(Palavra):-
    write('Parabéns!! Você Acertou!!\n'), write('A palavra era \"'), write(Palavra),write('\".'),
    jogar_novamente.

perdeu(Palavra) :- 
    write('\n Você perdeu!\n'), write('A palavra era \"'),write(Palavra),write('\".\n\n'),
    jogar_novamente.

incrementa(X, TamPalavra, Y):-
    X < TamPalavra -> Y is X + 1.

decrementa(X, Y):-
    Y is X - 1.

% Pega a palavra da lista no índice indicado
letra_indice(_Indice, [], _Letra).
letra_indice(0, [X|_], Letra) :- Letra = X.
letra_indice(Indice, [_|Resto], Letra) :- 
    decrementa(Indice, NovoIndice), 
    letra_indice(NovoIndice, Resto, Letra).

% Compara a letra da palavra tentada com a letra da palavra certa de mesmo índice
compara_letras(LetraTentativa, Letra, Letras):-
    igual(Letra, LetraTentativa) ->
        ansi_format([bold, fg(green)],'~w - está na palavra e na posição certa\n',[LetraTentativa]);
    pertence(LetraTentativa, Letras) ->
        ansi_format([bold, fg(yellow)],'~w - está na palavra mas não está posição certa\n',[LetraTentativa]);
    ansi_format([bold, fg(red)],'~w - não está na palavra\n',[LetraTentativa]).

% Verifica se letra está presente na palavra e se está na posição certa
verifica_letra(_LetraTentativa, _Index, []).
verifica_letra(LetraTentativa, IndexTentativa, Letras):-
    letra_indice(IndexTentativa, Letras, Letra),
    compara_letras(LetraTentativa, Letra, Letras).

% Verifica cada letra da palavra
processa_palavra([], _Letras, _IndexTentativa, _TamPalavra).
processa_palavra([LetraTentativa|RestoTentativa], Letras, Index, TamPalavra):-
    verifica_letra(LetraTentativa, Index, Letras),
    incrementa(Index, TamPalavra, NovoIndex),
    processa_palavra(RestoTentativa, Letras, NovoIndex, TamPalavra).

% Verifica se a palavra válida é igual a reposta, senão processa palavra
verfifica_palavra(Letras, LetrasTentadas, TamPalavra, PalavraTentada):-
    igual(Letras, LetrasTentadas) -> ganhou(PalavraTentada);
    processa_palavra(LetrasTentadas, Letras, 0, TamPalavra).


% Verifica se a palavra recebida é válida
verifica_tentativa(PalavrasTentadasAnterior, PalavrasTentadas, Letras, TamPalavra) :-
    write('Digite uma palavra para tentar:\n'),nl,
    read(Palavra), downcase_atom(Palavra, PalavraTentada),
    atom_chars(PalavraTentada, LetrasTentadas), 
    length(LetrasTentadas, NumLetrasTentadas), igual(NumLetrasTentadas, TamPalavra) ->
        junta_lista([PalavraTentada], PalavrasTentadasAnterior, PalavrasTentadas),
        verfifica_palavra(Letras, LetrasTentadas, TamPalavra, PalavraTentada);
        ansi_format([bold, fg(red)], 'ERRO: A palavra deve ter ~w letras!\n',[TamPalavra]),
        false.

% Recebe uma tentativa e chama verificação da palavra recebida
executar_tentativa(TamPalavra, NumTentativas, Palavra, Letras, PalavrasTentadas) :-
    NumTentativas is 0 -> perdeu(Palavra) ;
    write('\n\nChances restantes: '),write(NumTentativas),nl,
    write('Palavras Tentadas: '),write(PalavrasTentadas),nl,nl,

    verifica_tentativa(PalavrasTentadas, X, Letras, TamPalavra) ->
        proxima_tentativa(NumTentativas, ProximaTentativa),
        executar_tentativa(TamPalavra, ProximaTentativa, Palavra, Letras,X);
        executar_tentativa(TamPalavra, NumTentativas, Palavra, Letras, PalavrasTentadas).


% Inicia o jogo com 6 tentativas
inicia_jogo(TamPalavra) :-
  	seleciona_palavra(TamPalavra, Palavra, Letras),
    %write('DEBUG: A palavra selecionada é: '),write(Palavra),
    executar_tentativa(TamPalavra, 6, Palavra, Letras, []).

main :-
    write('\n---- WordlUFF ---- \n'),
    define_tamanho(TamPalavra) ->  inicia_jogo(TamPalavra) ; main().

