#!/bin/sh

#
# Verificar se binarios de um projeto ou do sistema estao acompanhado de suas bibliotecas
#
	# Pastas comuns de binarios executaveis
	xDEFAULTBINPATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

	# Pastas comuns de bibliotecas
	xDEFAULTLIBPATH="/lib:/lib64:/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64"


# Variaveis globais
	xROOT="/"
	xPATH="$xDEFAULTBINPATH"
	xLIBPATH="$xDEFAULTLIBPATH"
	xOUTPUT_ALLLIBS=""
	xOUTPUT_UNUSED=""
	xOUTPUT_FOUND=""
	xOUTPUT_NOTFOUND=""
	xOUTPUT_NOTUSEDS=""
	xCHECKCORE=0
	xLIST_FOUND=0
	xLIST_NOTFOUND=0

# Variaveis preservadas sem caminho do diretorio root do pacote
	xORIGBINPATH=""
	xORIGLIBPATH=""

# Prefixo de arquivos temporarios
	xPREFIX="/tmp/depcheck-lab"
	xDEBUG="/tmp/depcheck-debug"
	echo -n > $xDEBUG

# Me instalar
	mypath=$(readlink -f "$0")
	mybin="/bin/depcheck"
	if [ "$mypath" != "$mybin" ]; then cp $mypath $mybin; chmod +x $mybin; fi

# Funcoes
	_abort(){ echo; logitr "$@"; exit 2; }

	# obter resultado do LDD e sintetizar lista de bibliotecas
	_ldd_unify(){
		_lddu_file="$1"

		# vamos limpar esse arquivo
		# 1 - apenas binarios/objetos ao importantes
		cat $_lddu_file | egrep -v 'not.a.dynamic.executable' > $xPREFIX-lddu-1

		# filtrar por tipo
		# bibliotecas linkadas diretas
		cat $xPREFIX-lddu-1 | awk '/=. \// { print $3 }' | sort -u > $xPREFIX-lddu-a

		# bibliotecas nao encontradas diretamente
		cat $xPREFIX-lddu-1 | egrep 'not.found' | cut -f2 -d: | awk '{print $1}' | sort -u > $xPREFIX-lddu-b

		# a lista de nao encontrados pode estar na pastas $xORIGLIBPATH, procurar
		xrootlen=$(echo "$xROOT" | wc -c)
		cat $xPREFIX-lddu-b | while read _ux; do
			#logity "Biblioteca omissa: $_ux"
			# nome a utilizar no resultado
			_uxresult="$_ux"
			# Procurar biblioteca omissa na lista de libdirs
			for libdir in $xORIGLIBPATH; do
				# gerar nome sem o primeiro '/'
				uxpath="$libdir/$_ux"
				uxpathfull="$xROOT$uxpath"
				uxreal=$(readlink -f "$uxpathfull")
				if [ -f "$uxreal" ]; then
					# existe, usar caminho real
					#_uxresult=$(echo $uxreal | cut -b$xrootlen-)
					_uxresult="$uxpath"
					break
				fi
			done
			# exibir resultado
			echo "$_uxresult"
		done > $xPREFIX-lddu-c

		# as duas listas (diretas e resumidas) foram resolvidas, uni-las
		#logitr "LISTA A"
		#cat $xPREFIX-lddu-a
		#logitr "LISTA C"
		#cat $xPREFIX-lddu-c
		#return
		(
			cat $xPREFIX-lddu-a
			cat $xPREFIX-lddu-c
		)
	}


# TESTE
	#_ldd_unify /tmp/depcheck-libs;  exit 



# Ajuda
	depcheck_help(){
		echo
		echoc -c pink "Use: $0 [opcoes]"
		echo
		echoc -n -c green "  -r  (ROOT DIRECTORY)   "; echoc -c yellow "Diretorio ROOT do sistema de pacotes ou S.O., padrao '/'"
		echoc -n -c green "  -p  (PATCH LIST)       "; echoc -c yellow "Lista de diretorios separados ':', padrao basedo no PATH do sistema"
		echoc -n -c green "  -l  (LIB PATCH LIST)   "; echoc -c yellow "Lista de pastas de bibliotecas"
		echo
		echoc -n -c green "  -a  (ALL BLIS FILE)    "; echoc -c yellow "Arquivo com lista de biliotecas encontradas"
		echoc -n -c green "  -o  (OUTPUT FILE)      "; echoc -c yellow "Arquivo com lista de biliotecas presentes"
		echoc -n -c green "  -x  (OUTPUT ERR)       "; echoc -c yellow "Arquivo com lista de biliotecas ausentes"
		echoc -n -c green "  -u  (OUTPUT UNUSED)    "; echoc -c yellow "Arquivo com lista de biliotecas nao utilizadas"
		echo
		echoc -n -c green "  -F                     "; echoc -c yellow "Listar bibliotecas encontradas"
		echoc -n -c green "  -N                     "; echoc -c yellow "Listar bibliotecas nao encontradas"
		echo
		exit 1
	}

# Processar parametros
	#echo "Parametros: $@"
	argc=0
	while [ 0 ]; do
		# sem mais parametros
		[ "x$1" = "x" ] && break
		# Parametros
		# - diretorio root
		if [ "$1" = "-r" ]; then xROOT="$2"; shift 2; argc=$(($argc+1)); continue; fi
		# - Pastas
		#   > de binarios
		if [ "$1" = "-p" ]; then xPATH="$xPATH $2"; shift 2; argc=$(($argc+1)); continue; fi
		#   > de bibliotecas
		if [ "$1" = "-l" ]; then xLIBPATH="$xLIBPATH $2"; shift 2; argc=$(($argc+1)); continue; fi		
		# - Verificar bibliotecas nativas
		if [ "$1" = "-c" ]; then xCHECKCORE=1; shift; argc=$(($argc+1)); continue; fi
		# - lista de bibliotecas relacionadas
		if [ "$1" = "-a" ]; then xOUTPUT_ALLLIBS="$2"; shift 2; argc=$(($argc+1)); continue; fi
		# - lista de bibliotecas encontradas no diretorio
		if [ "$1" = "-o" ]; then xOUTPUT_FOUND="$2"; shift 2; argc=$(($argc+1)); continue; fi
		# - lista de bibliotecas NAO encontradas no diretorio
		if [ "$1" = "-x" ]; then xOUTPUT_NOTFOUND="$2"; shift 2; argc=$(($argc+1)); continue; fi
		# - lista de bibliotecas NAO utilizadas
		if [ "$1" = "-u" ]; then xOUTPUT_NOTUSEDS="$2"; shift 2; argc=$(($argc+1)); continue; fi

		# - Listar resultados?
		if [ "$1" = "-F" ]; then xLIST_FOUND=1; shift; argc=$(($argc+1)); continue; fi
		if [ "$1" = "-N" ]; then xLIST_NOTFOUND=1; shift; argc=$(($argc+1)); continue; fi

		# - Ajuda
		if [ "$1" = "-h" -o "$1" = "help" -o "$1" = "-help" ]; then depcheck_help; fi
		# proximo...
		shift
	done
	if [ "$argc" = "0" ]; then logity "NENHUM ARGUMENTO INFORMADO: '$@'"; depcheck_help; fi

# Critica
	# Root
	[ -d "$xROOT" ] || _abort "Diretorio nao existe: '$xROOT'"

	# Arquivos de resultados
	if [ "x$xOUTPUT_FOUND" = "x" ]; then xOUTPUT_FOUND="/tmp/depcheck-founds.txt"; fi
	if [ "x$xOUTPUT_NOTFOUND" = "x" ]; then xOUTPUT_NOTFOUND="/tmp/depcheck-not-founds.txt"; fi
	if [ "x$xOUTPUT_NOTUSEDS" = "x" ]; then xOUTPUT_NOTUSEDS="/tmp/depcheck-not-useds.txt"; fi
	if [ "x$xOUTPUT_ALLLIBS" = "x" ]; then xOUTPUT_ALLLIBS="/tmp/depcheck-all-libs.txt"; fi
	touch "$xOUTPUT_FOUND" || _abort "Erro ao criar arquivos com lista de encontrados: '$xOUTPUT_FOUND'"
	touch "$xOUTPUT_NOTFOUND" || _abort "Erro ao criar arquivos com lista de nao encontrados: '$xOUTPUT_NOTFOUND'"
	touch "$xOUTPUT_ALLLIBS" || _abort "Erro ao criar arquivos com lista de todas as bibliotecas: '$xOUTPUT_ALLLIBS'"

	# Pastas
	# - singularizar apenas existentes
	#   > PASTAS COM BINARIOS
		# singularizar
		tmp=$(echo "$xPATH" | sed 's#:# #g')
		tmp=$(for p in $tmp; do echo $p; done | sort -u)
		xORIGBINPATH=$(for p in $tmp; do [ -d "$xROOT/$p" ] && echo "$p"; done | sort -u)
		# gerar caminhos completos
		xPATH=$(for p in $xORIGBINPATH; do echo "$xROOT/$p"; done | sort -u)
		# sem pastas para analisar
		[ "x$xPATH" = "x" ] && _abort "Diretorios de busca nao existem (ou nao foram informado)"

	#   > PASTAS COM BIBLIOTECAS
		# padrao
		if [ "x$xLIBPATH" = "x" ]; then xLIBPATH="$xDEFAULTLIBPATH"; fi
		# singularizar
		tmp=$(echo "$xLIBPATH" | sed 's#:# #g')
		tmp=$(for p in $tmp; do echo $p; done | sort -u)
		xORIGLIBPATH=$(for p in $tmp; do [ -d "$xROOT/$p" ] && echo "$p"; done | sort -u)
		# gerar caminhos completos
		xLIBPATH=$(for p in $xORIGLIBPATH; do echo "$xROOT/$p"; done | sort -u)
		# sem pastas para analisar
		#[ "x$xLIBPATH" = "x" ] && _abort "Diretorios de bibliotecas nao existem (ou nao foram informado)"

# Informacoes:
	#logitp "ROOT............: [$(echo $xROOT | wc -w)]"
	#logitp "BIN-PATH........: [$(echo $xPATH | wc -w)]"
	#logitp "LIB-PATH........: [$(echo $xLIBPATH | wc -w)]"

	logitp "ROOT............: [$(echo $xROOT)]"
	logitp "BIN-PATH........: [$(echo $xORIGBINPATH)]"
	logitp "LIB-PATH........: [$(echo $xORIGLIBPATH)]"
	logitp "out-ALL-LIBS....: [$xOUTPUT_ALLLIBS]"
	logitp "out-UNUSED......: [$xOUTPUT_UNUSED]"
	logitp "out-FOUND.......: [$xOUTPUT_FOUND]"
	logitp "out-NOT-FOUND...: [$xOUTPUT_NOTFOUND]"
	logitp "CHECKCORE.......: [$xCHECKCORE]"

# start debug
#@ if [ "a" = "b" ]; then

# Fazer listagem de arquivos nas pastas
	#binlist="/tmp/depcheck-bins-$RANDOM"
	binlist="/tmp/depcheck-bins"
	liblist="/tmp/depcheck-libs"
	logit2 -n "Procurando binarios" "(aguarde)"

	# - lista de diretorios precisa ser com localizacao do root
	find $xPATH -type f | xargs file | grep ELF | egrep '(executable|shared object|not stripped)' | cut -f1 -d: > $binlist

	# - numero de arquivos
	bincount=$(wc -l $binlist | awk '{print $1}')
	printf "\r"
	logit2    "Arquivos binarios e objetos encontrados:" "$bincount"

	# - encontrou algo?
	if [ "$bincount" -lt "1" ]; then _abort "Nenhum arquivo encontrado"; fi

# Procurar bibliotecas nos binarios (esses binarios existem pois o FIND encontrou)
	echo -n > $liblist
	cat $binlist | while read bin; do
		# exibir para contabilidade do loading
		echo "none"

		# procurar bibliotecas
		ldd "$bin" >> $liblist

		# catalogar para debug
		(echo "[$bin]"; ldd "$bin") >> $xDEBUG

	done | shloading -t "Procurando bibliotecas" -m $bincount -s 3 -c -n

# Processar bibliotecas encontradas
	# - lista de bibliotecas obtidas sem repeticoes
	uniqueliblist="/tmp/depcheck-libs-unique"

	# singularizar, remover repetidas
	tmpunique="/tmp/depcheck-tmpunique"
	logitr "Gerando lista unificada"
	_ldd_unify $liblist > $tmpunique

	#> bibliotecas de binarios: $tmpunique (caminho no /, nao esta com caminho em xROOT)


# Obter bibliotecas das bibliotecas (essas bibliotecas podem nao existir)
	# - arquivos temporarios
	lib4lib1=/tmp/depcheck-lib4lib1
	lib4lib2=/tmp/depcheck-lib4lib2

	# - extrair:
	echo -n > $lib4lib1
	tmpc=$(cat $tmpunique | wc -l)
	for libfile in $(cat $tmpunique); do
		# exibir para contabilidade do loading
		echo "none"
		xlibfile=$(echo "$xROOT/$libfile" | sed 's#//#/#g')

		[ -f "$xlibfile" ] || continue

		ldd "$xlibfile" >> $lib4lib1
		(echo "[$xlibfile]"; ldd "$xlibfile") >> $xDEBUG

	done | shloading -t "Resolvendo lib-4-lib" -m $tmpc -s 3 -c -n -d 2000
	# - singularizar
	_ldd_unify $lib4lib1 > $lib4lib2


# Unir lista de bibliotecas principais e bibliotecas de bibliotecas
	xlibsingular="/tmp/depcheck-libsingular"
	tmpresolved="/tmp/depcheck-libs-resolved"
	(
		cat $tmpunique
		cat $lib4lib2
	) | sort -u > $xlibsingular

	# alguns caminhos contem '..' ou '../..', precisamos do caminho completo
	tmpc=$(cat $xlibsingular | wc -l)
	echo -n > $tmpresolved
	cat $xlibsingular | while read lib; do
		# exibir para contabilidade do loading
		echo "$lib"

		readlink -f "$lib" >> $tmpresolved

	done | shloading -t "Resolvendo caminho" -m $tmpc -s 3 -c -n -d 2000

	# remover repeticoes e colocar na lista de bibliotecas finais diretas
	cat $tmpresolved | sort -u > $xOUTPUT_ALLLIBS

#@ fi
# end debug

	# contar total
	LIBCOUNT=$(cat $xOUTPUT_ALLLIBS | wc -l)
	logit2 "Total de bibliotecas:" "$LIBCOUNT"	

# Procurar bibliotecas
	#logity "Verificando se bibliotecas existem"
	echo -n > $xOUTPUT_FOUND
	echo -n > $xOUTPUT_NOTFOUND
	cat $xOUTPUT_ALLLIBS | while read lib; do
		# exibir para contabilidade do loading
		echo "$lib"

		flib="$xROOT/$lib"
		if [ -f "$flib" ]; then
			echo "$lib" >> $xOUTPUT_FOUND
		else
			echo "$lib" >> $xOUTPUT_NOTFOUND
		fi
	done | shloading -t "Localizando bibliotecas" -m $LIBCOUNT -s 3 -c -n -d 2000




# Procurar bibliotecas NAO UTILIZADAS
	# Teste de busca por bibliotecas nao utilizadas
	# - Listar arquivos das bibliotecas
	LIBDIRS=$(cat $xOUTPUT_FOUND | while read x; do [ -f "$x" -a ! -L "$x" ] && dirname $x; done | sort -u)

	ALLLIBFILES=""
	ACOUNT=0
	logit "Analisando diretorios com biblitecas"
	for ldir in $LIBDIRS; do
		logit "-> $ldir"
		cd "$TMPDST$ldir" || abort "Erro ao entrar em [$TMPDST$ldir]"
		xtmp=""
		for i in *; do
			if [ -f "$i" -a ! -L "$i" ]; then xtmp="$xtmp $ldir/$i"; fi
			ACOUNT=$(($ACOUNT+1))
		done
		ALLLIBFILES="$ALLLIBFILES $xtmp"
	done
	logit2 "Total de arquivos em bibliotecas:" "$ACOUNT"

	# cruzar arquivos
	logit "Cruzando listas, aguarde..."
	xOUTPUT_NOTUSEDS="/tmp/sanatize-libs-unused"
	echo -n > $xOUTPUT_NOTUSEDS
	for xlib in $ALLLIBFILES; do
		f=0
		for ulib in $(cat /tmp/sanatize-libs-found); do
			if [ "$ulib" = "$xlib" ]; then f=1; break; fi
		done
		[ "$f" = "0" ] && echo "$xlib" >> $xOUTPUT_NOTUSEDS
	done
	UCOUNT=$(cat $xOUTPUT_NOTUSEDS | wc -l)
	#logit2 "Total de bibliotecas nao utilizadas:" "$UCOUNT"



# RESUMO
	LIBSOKcount=$(cat $xOUTPUT_FOUND | wc -l)
	LIBSERcount=$(cat $xOUTPUT_NOTFOUND | wc -l)
	logit3 "Bibliotecas encontradas......:" "$LIBSOKcount" "$xOUTPUT_FOUND"
	logit3 "Bibliotecas NAO encontradas..:" "$LIBSERcount" "$xOUTPUT_NOTFOUND"
	logit3 "Bibliotecas NAO utilizadas...:" "$UCOUNT" "$xOUTPUT_NOTUSEDS"


	if [ "$xLIST_FOUND" = "1" ]; then cat "$xOUTPUT_FOUND"; exit; fi
	if [ "$xLIST_NOTFOUND" = "1" ]; then cat "$xOUTPUT_NOTFOUND"; exit; fi

	if [ "$LIBSERcount" -gt "0" ]; then
		logity -n "Sistema incapaz de executar, faltam "; echoc -c pink -n "$LIBSERcount"; echoc -c yellow " bibiliotecas"
		exit 3
	fi

	logitg "Concluido, sistema perfeito :-)"


exit 0











