#!"C:\strawberry\perl\bin\perl.exe \-w"
use strict;
use warnings;
use Data::Dumper;
use Parse::RecDescent;


####################################################
#            Gramática da linguagem DRAW           #
#                                                  #
# Como a linguagem é minimamente complexa, não foi #
# possível reconhecê-la apenas com expressões re-  #
# gulares. Por isso usou-se o parser recursivo     #
# descendente escricto em perl RecDescent.         #
#                                                  #
####################################################

my $grammar = q {

    draw : aresta ';' draw {shift @item; 
	    		    pop @{$item[0]};
			    $item[0] = join "", @{$item[0]};
			    $item[2] = \@{$item[2]}; 
			    \@item }
		    
	 | /.*|\n/	{  shift @item;
		   $item[0] = "";
		   \@item }

    aresta : vertice '=>' vertice '{' argumentos '}'  { shift @item; 
	    						$item[4] = join "", main::drainLista(2,@{$item[4]}); 
							\@item }
	| /.*|\n/	{  shift @item;
		   $item[0] = "";
		   \@item }

    vertice : STR {$item [1]}

    argumentos : argumentos1 { shift @item; \@item }
	       | { shift @item; 
		   @{$item[0]}[0]="";
	           \@item }

    argumentos1 : funcao ',' argumentos1  { shift @item; 
				    	    pop @{$item[0]};
	    				    $item[0] = join "", @{$item[0]};
	    				    $item[2] = \@{$item[2]};
					    \@item }
		| parametro ',' argumentos1 { shift @item; 
	    				      $item[2] = \@{$item[2]};
					      \@item }
	        | funcao  { shift @item; 
		    	    pop @{$item[0]};
			    $item[0] = join "", @{$item[0]};
			    \@item }
		| parametro { shift @item; 
		    	      \@item }
	        
    funcao : tipo SIMBOLO '::' STR '(' parametros ')' { shift @item; $item[5] = join "", main::drainLista(2,$item[5]); \@item }
	   | '(' tuplo ')' SIMBOLO '::' STR '(' parametros ')'{ shift @item; 
								$item[7] = join "", main::drainLista(2,$item[7]);
		   						$item[1] = join "", main::drainLista(4,$item[1]);
		   						\@item }

    parametros : parametros1 { $item{parametros1}}
    	       | { }
	
    parametros1 : tipo '::' parametro ',' parametros1 { shift @item; 
							my $param = $item[0] . $item[1] . $item[2];
							shift @item; shift @item;
							$item[0] = $param;
	    						$item{parametros1} = \@{$item{parametros1}};
						       	\@item }
    		| tipo '::' parametro { shift @item;
					my $param = $item[0] . $item[1] . $item[2];
					shift @item; shift @item;
					$item[0] = $param;
		       			\@item }

    parametro : STR { $item[1]}

    tuplo : tipo '::' parametro ',' tuplo  { shift @item; $item{tuplo} = \@{$item{tuplo}}; \@item }
    	  | tipo '::' parametro { shift @item; \@item}


    tipo : 'STR' | 'INT' | 'PASSWORD' | 'DATE' | 'EMAIL' | 'URL' | 'TEXT' | 'FLOAT' | 'VARS' | REGEX {$item[1]}

    STR : /[a-zA-Z][a-zA-Z0-9]*/  {$item [1]}
    	| '' { "" }

    REGEX : /(.*\/)(.*\/)/ {"/".$2}
    	  | /.*/ {""}

    SIMBOLO : '*' | '+'  {$item[1] }
    	    | {""}

};

# Neste parser, em cada símbolo, é herdada uma referência para cada conjunto de valores. 
# Depois de ter tirado todos os valores das refefências e os ter juntado numa variável, 
# a sua referência é sintetizada para os símbolos pais.

my $parser=Parse::RecDescent->new($grammar);
# Instancia o parser com a gramática escrita acima.

sub get_grammar{
	return $grammar;
}
# Possibilita o acesso à gramática de fora desta script.

sub get_parser{
	return $parser;
}
# Possibilita o acesso ao parser de fora desta script.





#############################################
# Funções de reconhecimento de cada símbolo #
# não terminal desta linguagem.             #
#############################################

# --- draw ---
sub parse_draw{
	my $t = $parser->draw("@_");
	return drainLista(2,$t);
}
# recebe: 
# "A=>B{STR::nome, INT::idade}; A=>C{STR::nome, PASSWORD::pass, /^\$a;a/::verifica(pass,nome)};"
# devolve:
# [ 'A=>B{STR::nome,INT::idade}',';','A=>C{STR::nome,PASSWORD::pass,/^$a;a/::verifica
# (pass,nome)}',';','A=>B{STR::nome,INT::idade}',';' ]

# --- aresta ---
sub parse_aresta{
	my $t = $parser->aresta("@_");
	pop @{$t};
	return @{$t};
}
# recebe: 
# "A=>R{STR::nome, PASSWORD::pass, (INT::nome,PASSWORD::pass)::procuraRegisto(nome)}"
# devolve:
# [ 'A','=>','R','{','STR::nome,PASSWORD::pass,(INT::nome,PASSWORD::pass)::procuraReg
# isto(nome)','}' ]

# --- argumentos --- # --- argumentos1 ---
sub parse_argumentos{
	my $t = $parser->argumentos("@_");
	return drainLista(2,@{$t});
}
sub parse_argumentos1{
	my $t = $parser->argumentos1("@_");
	return drainLista(2,$t);
}
# recebem: 
# "STR::nome2,(INT::nome,PASSWORD::pass)+::procuraRegisto(nome,pass),STR::nome, 
# PASSWORD::pass,INT::verifica(pass,nome),PASSWORD::pass2"
# devolvem:
# [ 'STR::nome2',',','(INT::nome,PASSWORD::pass)+::procuraRegisto(nome,pass)',',','ST
# R::nome',',','PASSWORD::pass',',','INT::verifica(pass,nome)',',','PASSWORD::pass
# 2STR::nome2,(INT::nome,PASSWORD::pass)+::procuraRegisto(nome,pass),STR::nome,PAS
# SWORD::pass,INT::verifica(pass,nome),PASSWORD::pass2' ]

# --- funcao ---
sub parse_funcao{
	my $t = $parser->funcao("@_");
	pop @{$t};
	return @{$t};
}
# recebe: 
# "(INT::nome,PASSWORD::pass)+::procuraRegisto(nome,pass)"
# devolve:
# ['(','INT::nome,PASSWORD::pass',')','+','::','procuraRegisto','(','nome,pass',')']

# --- parametros --- # --- parametros1 ---
sub parse_parametros{
	my $t = $parser->parametros("@_");
	return drainLista(2,$t);
}
sub parse_parametros1{
	my $t = $parser->parametros1("@_");
	return drainLista(2,$t);
}
# recebem: 
# "nome,desc,pass"
# devolvem:
# ['nome',',','desc',',','passnome,desc,pass']

# --- tuplo ---
sub parse_tuplo{
	my $t = $parser->tuplo("@_");
	return drainLista(4,$t);
}
# recebe: 
# "STR::nome,TEXT::desc,PASSWORD::pass"
# devolve:
# ['STR','::','nome',',','TEXT','::','desc',',','PASSWORD','::','passSTR::nome,TEXT:
# :desc,PASSWORD::pass']

# --- REGEX ---
sub parse_REGEX{
	my $t = $parser->REGEX("@_");
	return $t;
}
# recebe: 
# "/^etc...$/"
# devolve:
# "/^etc...$/" ou "" se nao for regex




sub drainLista{
	my $apontador;
	my @params;
	($apontador,@params) = @_;
	my $param = $params[0];
	my (@lista,@tmpl);
	@tmpl = @{$param};
	my $alavanca=1;

	while($alavanca){
		for(my $i=0;$i<$apontador;$i++)	{push @lista, $tmpl[$i];}
		if($tmpl[$apontador]) { 
			@tmpl = @{$tmpl[$apontador]}; 
		} else { $alavanca = 0;}
	}
	pop @lista;
	return @lista;
}

# Esta função recebe um array onde tem um valor e uma referência para o
# o resto do array que por usa vez tem o valor de um elemento mais outra 
# referência para o resto do array. Além disso recebe um inteiro a indicar
# a posição do símbolo que gera recursividade (uma lista na gramática acima).
# Devolve o array de valores sem referências.



#########################################################################
# 			EXEMPLO DE USO DESTE SCRIPT			#
# testar num exemplo.pl:						#
#									#
# require "gram.pl";							#
# my $parser = &get_parser();						#
# 									#
# while (<>) { $parser->draw(\$_);  }					#
#									#
# my @lista = parse_tuplo("STR::nome,TEXT::desc,PASSWORD::pass");	#
# print (join "','" , @lista);						#
# print @lista;								#
# print $#lista;							#
#									#
#########################################################################

1;
