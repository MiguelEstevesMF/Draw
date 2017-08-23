#!"C:\strawberry\perl\bin\perl.exe \-w"
use strict;
use warnings;
use Data::Dumper;
use Parse::RecDescent;

require "gram.pl";

my %G;
my %Paginas;
my $grafo_mapa="";

# Retorna uma instância da gramática (ver gram.pl).
my $parser = &get_parser();

$\ = ';';
# Lê o ficheiro escrito na linguagem DRAW e preenche a hash com os dados das arestas.
while (<>) {
       	my @v = parse_draw($_);
	my @aresta = parse_aresta($v[0]);
	if ($aresta[0] eq "" ) {next;}
	my $dest = $aresta[2] . $aresta[3] . $aresta[4] . $aresta[5];
	&preencher_Hash($aresta[0],$dest);

	# Gerar relações entre nodos para o mapa do site.
	chomp $_; $_ =~ s/{.*}//; $_ =~ s/\s*//g; $_ =~ s/=>/ /; $_ =~ s/;//;
	if ($grafo_mapa =~ $_) {} else { $grafo_mapa .= "$_,"; }
}

# Remove o último caracter que neste caso é uma vírgula.
chop $grafo_mapa;

print "fim";

my $f = 1;

# Percorre todos os nodos do grafo
for my $estado (keys %Paginas){

	my $nodo = $estado;
	$nodo =~ s/{.*}//;
	
	# Cria a CGI com o nome do nodo.
	open CGI, ">$nodo.cgi" or die "Can't create $nodo.cgi\n";
	# Imprime na CGI os headers necessários.
	print CGI &header_cgi;
	# Imprime na CGI código javacript.
	print CGI &java_script($nodo);
	
	# Imprime na CGI os imports de scripts CSS E JavaScript do javascript.
	print CGI "print start_html( -title => '$nodo',
	-style => [ {'src' => 'files/style/ploneStyles0435.css'},
		    {'src' => 'files/style/estilo.css'} ],
        -script => [ { -language => 'JavaScript',-src=> 'files/popup_tipo.js'},
       		    { -language => 'JavaScript',-src=> 'files/Validar.js'},
		    { -language => 'JavaScript',-src=> 'files/pwd_meter.js'}, 
		    { -language => 'JavaScript',-src=> 'files/pacote_de_bolachas.js'}, 
		    \$JSCRIPT ],
        -class=>'section-ensino', -dir=>'ltr'
      	)";

	# Imprime o cabeçalho da página.
	print CGI &cabecalhoStyle($nodo);

	# Imprime os parâmetros passados a esta CGI.
	print CGI &print_params;

	if ($G{$nodo}) { # Verifica se é um nodo de origem.
		
		# Guarda no array os nodos destino juntamente com os parâmetros a serem passados.
		my @array = @{ $G{$nodo} };

		print CGI "print \"<table border = '0' cellspacing='12'>\",br\n";
		
		my $h = 1;

		# Para cada nodo destino cria uma form que irá conter os parâmetros.
		for ( @array ) {
			my $link = $_;
			$link =~ s/{.*}//;
	
			$_ =~ /{(.*)}/;
			
			# Guarda no array 'atribs' os parametros deste nodo
			my @atribs = parse_argumentos($1);

			print CGI "print \"<tr><td align='right'>\"";
			print CGI "print start_form(-method=>'POST', -action=>'')";
			print CGI "print \"<fieldset><table cellpadding='5'>\"";
			
			my @params;
			my @herdados;
			# Percorre os atributos.
			for (@atribs) {
				if ($_ eq "," || $_ eq ""){next; }
				if (/(.*::.*\(.*\))/){ # Verifica se é uma função.
					# Imprime um campo hidden que será passado como parâmetro à próxima página.
					print CGI "my \$funcao$f = '$1'";
					print CGI "print hidden('função$f',\$funcao$f)";
					$f++;

					my @funcs = &parse_funcao($1);
					my @atrs = &parse_tuplo($funcs[$#funcs-1]);
					
					for(my $j=0; $j<$#atrs+1; $j+=4){
						push @params,$atrs[$j+2];
						&draw_form($atrs[$j],$atrs[$j+2]);
					}
				}
				elsif (/(.*)/)  { # Se não for uma função.
					push @herdados, $1;
				}
			
			}
			for(@herdados){
				print CGI "my \$herdado$h = '$_'";
				print CGI "print hidden('herdado$h',\$herdado$h)";
				if (!grep (\$_,@params)) { print CGI "print hidden('$_')"; }
				$h++;
			}
			# Imprime o botão de submeter e as acçõe necessárias para validação do formulário 
			# (ver Validar.js e a função JS 'changeDest' abaixo).
			print CGI "print \"<tr><td align='right'>\"";
			print CGI "print br,button(-name=>'.submit', -value=>'$link', -onClick=>\"changeDest(validateSubmit(this.parentNode.parentNode), '$link.cgi' ,this)\")";
			print CGI "print \"</td></tr>\"\n";

			print CGI "print \"</table></fieldset>\"";

			print CGI "print end_form";

			print CGI "print \"</td></tr>\"";
		}
		print CGI "print \"</table>\"";
	}

	# Javascript responsável pela limpeza dos formulários.
	#print CGI "print \"<script type='text/javascript'> clearInputs(\$sh); </script>\";";

	# Imprime o rodapé da página.
	print CGI &rodapeStyle;

	print CGI "print end_html";
	close CGI;
}



	########### MAPA DO SITE ###########
	open CGI, ">mapa_do_site.cgi" or die "Can't create mapa_do_site.cgi\n";
	print CGI &header_cgi;
	print CGI &java_script('mapa_do_site');

	print CGI "print start_html( -title => 'Mapa do site',
	-style => [ {'src' => 'files/style/ploneStyles0435.css'},
		    {'src' => 'files/style/estilo.css'} ],
        -script => [ { -language => 'JavaScript',-src=> 'files/popup_tipo.js'},
       		    { -language => 'JavaScript',-src=> 'files/Validar.js'},
		    { -language => 'JavaScript',-src=> 'files/pwd_meter.js'}, 
		    { -language => 'JavaScript',-src=> 'files/pacote_de_bolachas.js'}, 
		    \$JSCRIPT ],
        -class=>'section-ensino', -dir=>'ltr'
      	)";
	print CGI &cabecalhoStyle('Mapa do site');
	print CGI &mapa_do_site($grafo_mapa);
	print CGI &rodapeStyle;
	print CGI "print end_html";
	close CGI;
	########### #### ## #### ###########
	



###### funções #######

sub draw_form{
	# Imprime uma tag a ser usada pelo javascript, de modo a que quando passar o rato em cima do field mostre o seu tipo.
	print CGI "print \"<tr><td align='right' onMouseOver='Show(this)' onMouseOut='Hide(this)'>\"";
	my $n = $_[1];
	my $t = $_[0];
	print CGI "print b('$n: ')\n";
	if ($t eq 'PASSWORD') { # Verifica se o tipo é password.
		print CGI "print password_field(-onkeypress=>'return handleEnter(this, event)',-name=>'$n', -onKeyUp=>\"validate(this,'$t');passwordPower(this)\")"; # password
		print CGI &popup_tipo($t);
		print CGI "print \"<div></div>\"\n";
	} elsif ($t eq 'TEXT') { # Verifica se o tipo é text.
		print CGI "print textarea(-value=>'', -name=>'$n', -onKeyUp=>\"validate(this,'$t')\")";
		print CGI &popup_tipo($t);
	} elsif ($t eq  'STR' || $t eq 'INT' || $t eq 'DATE' || $t eq 'EMAIL' || $t eq 'URL' || $t eq 'FLOAT'){ # Verifica o tipo do parâmetro.
		print CGI "print textfield(-onkeypress=>'return handleEnter(this, event)', -value=>'', -name=>'$n', -onKeyUp=>\"validate(this,'$t')\")";
		print CGI &popup_tipo($t);
	} else { # Tipo é uma expressão regular.
		my $tipo= $t;
		my $nome = $n;
		my $exp = $t;
		$exp =~ s/\$/\\\$/;
		print CGI "print textfield(-onkeypress=>'return handleEnter(this, event)',-value=>'', -name=>'$nome', -onKeyUp=>\"validatePattern( this , $exp )\")";
		print CGI &popup_tipo($exp);
	}
	print CGI "print \"</td></tr>\"";
}

# Devolve uma string com os headers a conter em cada CGI.
sub header_cgi{
qq{#!"C:\\strawberry\\perl\\bin\\perl.exe" 

use strict;
no strict "refs";
use warnings;
use CGI ':standard';
use DO;
use LT;

require 'gram.pl';

print header;

\n\n};


}

# Devolve uma string com código javascript responsável pela submissão de um formulário 
# bem como da contagem de páginas visitadas (ver pacote_de_bolachas.js).
# A função em JS recebe um parâmetro que diz se aquele formulário é válido ou não e recebe o link 
# de submissão. Se for válido muda o atributo action do elemento FORM para o link recebido como parâmetro e o 
# elemento BUTTON é mudado para SUBMIT de modo a submeter o formulário.
sub java_script{
qq{my \$JSCRIPT=<<END;
bolacha(\"$_[0]\");
function changeDest(valid,link,field){
	if(valid) field.type="submit";
	else field.type="button";
	while(field.nodeName!="FORM") field = field.parentNode;
	if(valid) field.action = link;
	else field.action = "";
}
END
}
}

# Devolve uma string com os parâmetros passados pela CGI anterior bem como as funções e o seu resultado
sub print_params{
qq{
my \$cgi = new CGI;
my \$key;
my \@funcoes;

# verifica se foram passados parâmetros à página
if (defined(\$cgi->param())){
	print br,b(u("PARÂMETROS")),br,br;
	print "<table border='1'>";
}

my \$n = 1;

my \@hs;

# Imprime os parâmetros passados pela CGI anterior.
for \$key ( \$cgi->param() ) {
	if (\$cgi->param(\$key)) {
		my \$value = param(\$key);
		
		if(\$key !~ m/herdado/ )  {
			param(\$key,"");
			
	        }
		else {
			push \@hs, \$value; 
		}

		\$value =~ s/\\n/<br\\/>/g;
		if (\$key =~ /função\\d+/){ # Se um parâmetro for uma função então guarda no array 'funcoes'.
			push \@funcoes,\$cgi->param(\$key);
			my \$k = \$key;
			\$k =~ s/\\d+//;
			print "<tr><td valign='top'>",b("\$k\$n"),"</td><td>",\$value,"</td></tr>";
			\$n++;			
		} else {
			print "<tr><td valign='top'>",b("\$key"),"</td><td>",\$value,"</td></tr>";
		}
	}
}

for(\@hs){
	param(\$_,\$cgi->param(\$_));
}


if (defined(\$cgi->param())){
	print "</table>";
}

# Percorre o array 'funcoes' e imprime o resultado da execução de cada função.
for (\@funcoes){
	my (\$f,\@fs,\@p,\@ps,\@t);

	# Recebe uma função e retorna um array com os campos todos da função (ver gram.pl).
	\@fs = parse_funcao(\$_);

	# Calcula o indíce do último elemento do array.
	my (\$index) = \$#fs;
	\$f = \$fs[\$index-3];
	
	# Guarda no array 'p' os parametros utilizados pela função.
	\@p = split /,/,\$fs[\$index-1];

	# Guarda no array 'ps' os valores dos parâmetros utilizados pela função.
	for (\@p){
		\$_ =~ /.*::(.*)/;
		push \@ps, \$cgi->param(\$1);
	}

	
	if (defined &\$f) { # Verifica se a função devolve algum resultado.

		print br,b(u("RESULTADO DAS FUNÇÕES"));

		if (\$fs[0] eq "(") { # Verifica se a função devolve um tuplo.
			
			# Guarda o resultado da função.
			my \@r = &\$f(\@ps);
			
			print h3(\$f,":");

			# Recebe uma string contendo o tuplo a ser devolvido e retorna um array com os campos desse tuplo (ver gram.pl).
			\@t = parse_tuplo(\$fs[1]);
			my \$s = join ",", \@t;
			

			# Imprime a tabela com os resultados presentes no 'array'.
			print "<table bgcolor='#E8E8E8' border='1' ><tr align=center>";
			my \$cols=0;
			
			for(my \$i=2; \$i<\$#t+1; \$i+=4) {
				print "<th>";
				print \$t[\$i];
				print "</th>";
				\$cols++;
			}
			print "</tr>";

			for(my \$i=0; \$i<\$#r+1; \$i++) {
				print "<tr align=left>";
				for(my \$j=0; \$j<\$cols; \$j++) {
					print "<td>";
					print "<table>".\$r[\$i][\$j]."</table>";
					print "</td>";			
				}
				print "</tr>";
			}
			print "</table>",br,hr;


		} elsif (\$fs[1] eq "+" || \$fs[1] eq "*"){ # Verifica se a função devolve uma lista.

			# Guarda o resultado da função.
			my \@r = &\$f(\@ps);

			print h3(\$f,":");

			# Imprime a tabela com os resultados presentes no array.
			print "<table bgcolor='#E8E8E8' border='1' >",br,"<tr align=center>";
			print "<th>",\$fs[0],"</th>","</tr>";

			for(\@r) {
				print "<tr align=left>";
				print "<td><table>",\$_,"</table></td>";			
				print "</tr>";
			}
			print "</table>",br,hr;

		} else { # Se a função devolver um tipo básico então é mostrado o resultado da função.
			if (\$fs[0] eq "VARS") { 
				my \%map=&\$f(\@ps);
				print br;
				for my \$k (keys %map){
					print br,b("chave: "),\$k,br;
					print b("valor:"),\$map{\$k},br;
					param(\$k,\$map{\$k});
				}
			} else{
				print h3(\$f,":"),"<table>".&\$f(\@ps)."</table>",br,hr;
			}
		}
	} else { # Se a função devolve erros, então são mostrados na página esses erros.
		print h4("A função '\$f' devolveu erros:");
       		print "ERRO: ",\$@,br;
		print br,hr;
	}	
       	
}

}
}


# Preenche uma hash em que a chave é o nodo de origem e o valor é um array de nodos de destino e os seus atributos a submeter.
sub preencher_Hash{
	my ($l,$r);
	$l=$_[0];
	$r=$_[1];
	my $contains=1;
	
	if ($G{$l}) {
		for ( @{ $G{$l} }){
			if ($_ eq $r) { $contains=0; next;}
		}
		if ($contains==1) {
			push @{ $G{$l} }, $r;
		}
	        $contains=1;	
	} else {
		push @{ $G{$l} }, $r;
	}
	
	# Insere na hash Paginas todos os nodos de forma a que sejam criados pelo parser.
	$Paginas{$l}++;
	$Paginas{$r}++;

}

# Imprime um elemento DIV na página para mostrar o tipo do valor que é suposto introduzir naquele campo. 
# Ver detalhes e progressão da implementação deste comportamento em popup_tipo.js.
sub popup_tipo{
qq{
print qq[<div class="popup_tipo">$_[0]</div>];\n}
}

# Constrói o cabeçalho comum a todas as páginas CGI geradas.
sub cabecalhoStyle{
qq{ print qq[
<div id="visual-portal-wrapper-shadow">
  <div id="visual-portal-wrapper">
    <div id="portal-top">
      <div id="portal-header"> <a class="hiddenStructure" accesskey="2" href="">Ir para o conteúdo.</a> 
        <h1 id="portal-logo"> <a title="" href="http://www.di.uminho.pt/" accesskey="1">Departamento de Informática</a> </h1>
        <div id="disite_title">
        <p style="font-size:10px"></p>
          <table border="0">
       	  <tr><td>
          <div class="disite_title_um">Universidade do Minho</div>
          <div class="disite_title_di">Departamento de Informática</div>
          </td></tr>
          </table>
        </div>
      </div>
      <div >
        <div id="di-header-title">
          <br/><br/><br/>
          <div class="header-bullet">&gt;</div>          
          <div class="header-title" id="header-title">$_[0]</div>
        </div>

          <div class="visualClear"></div>
          <div id="portal-globalnav-bottom"></div>

        
      </div>
      <div id="portal-breadcrumbs"> <span id="breadcrumbs-you-are-here">Você está aqui:</span>
	<script type='text/javascript'> lerLinksDaBolacha();</script>$_[0]



       </div>
    </div>

    <table id="portal-columns">
        <tr>
          <td>
          	<div id="content">
		

	];\n}

}

# Constrói o rodapé comum às páginas CGI.
sub rodapeStyle{
qq{ print qq[
</div>
          </td>
        </tr>
    </table>

  </div>
	<div align="center"> <div id="visual-portal-wrapper-bottom"></div>   </div>
</div>
<hr class="netscape4">
<div id="portal-footer">
Todos os direitos reservados
<h5 class="hiddenStructure">Ferramentas Pessoais</h5>
<ul id="portal-personaltools">
<li> <span class="separator">|</span> <a href="http://www.di.uminho.pt/login_form"> Autenticação </a> </li>
<span class="separator">|</span> <a href="mailto:webmaster\\\@di.uminho.pt">webmaster\\\@di.uminho.pt</a>
<li> <span class="separator">|</span> <a href="mapa_do_site.cgi"> Mapa do site </a>
</li></ul>
</div></hr>
];\n}
}

# Função responsável pela utilização da applet na página "mapa_do_site.cgi" que permite mostrar o grafo correspondente às páginas.
# Recebe as relações entre as páginas onde cada relação é separada por ',' e separa 2 nodos com um espaço. Submete à applet ainda 
# o endereço actual em JavaScript.
sub mapa_do_site{
"print qq[

<fieldset><table align='center'><tr><td><br/>
	<APPLET name=myApplet code='appletgraphview/AppletGraphView.class' archive='files/prefuse.jar' width=710 height=600>
		<PARAM NAME='XmlTags' VALUE='$_[0]'/>
		<PARAM NAME='Endereco' VALUE=''/>
	</APPLET>
	<br/></td></tr></table></fieldset>
	<script language='javascript'>
		document.getElementsByName('Endereco')[0].value = document.location.toString();
	</SCRIPT>

];
"}

