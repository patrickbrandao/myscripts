#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

#
# Script para testar duplicacao de arquivos entre varios
# pacotes e diretorios para evitar problemas de duplicacoes ao uni-los no destino, onde se tornaria
# imprevisivel saber qual arquivo sera' usado, impactando updates e correcoes futuras.
#

# Pacotes
PACKAGES=""

# Diretorios abertos
DIRECTORIES=""

# Variaveis
	RET=0

	DUPDIR=/tmp/duptester-dir
	DUPIDX=/tmp/duptester-idx
	DUPCOUNT=0

    # Funcoes de seguranca
    abort(){
		echo
		echoc -c yellow -l " ABORTADO" 2>/dev/null || echo " ABORTADO"
		echoc -B -c red -l " $@" 2>/dev/null || echo " $@"
		echo
		exit 1
   	}
   	_lsfiles(){
		dir="$1"
		cd "$dir" || return
		find . | sed 's#^\./#/#g' | \
		while read x; do
			if [ -f "$dir/$x" ]; then
				echo $x
			fi
		done
   	}

# Coletar argumentos
	for arg in $@; do
		item=$(readlink -f "$arg")

		# diretorio?
		if [ -d "$item" ]; then DIRECTORIES="$DIRECTORIES $item"; continue; fi

		# arquivo?
		if [ -f "$item" ]; then
			_ext=$(fileextension $item)
			PACKAGES="$PACKAGES $item"

			if [ "$_ext" = "txz" ]; then continue; fi
			if [ "$_ext" = "tgz" ]; then continue; fi
			if [ "$_ext" = "gz" ]; then continue; fi
			if [ "$_ext" = "zip" ]; then continue; fi
			if [ "$_ext" = "gz2" ]; then continue; fi
			abort "Erro ao processar '$item', extensao '$_ext' nao reconhecida."
			continue
		fi

		logitr "$0: ERRO, argumento desconhecido: '$arg'"
		exit 2
	done
	# Criticas
	if [ "x$PACKAGES" = "x" -a "x$DIRECTORIES" = "x" ]; then echo "Informe pacotes ou diretorios como parametros"; exit 3; fi

	#-logit2 "DUP Tester z: $PACKAGES"
	#-logit2 "DUP Tester d: $DIRECTORIES"
	#@ echo
	#@ echo "PACKAGES.......: $PACKAGES"
	#@ echo "DIRECTORIES....: $DIRECTORIES"
	#@ echo

# DIRETORIO
	logit "Criando diretorio: $DUPDIR"
	rm -rf "$DUPDIR" 2>/dev/null
	mkdir -p "$DUPDIR"


# Descompactar pacotes em diretorios individuais
	COMPDIRS=""
	IDXLIST=""

	# Extrair
	if [ "x$PACKAGES" != "x" ]; then
		for pkg in $PACKAGES; do

			_file=$(basename "$pkg")
			_ext=$(fileextension $_file)
			_name=$(basename $_file .$_ext)

			dirname="/tmp/duptester-item-$_name"
			idxfile="/tmp/duptester-idx-$_name"

			# descompactar
			COMPDIRS="$COMPDIRS $dirname"
			IDXLIST="$IDXLIST $idxfile"

			#logit2 $dirname $pkg
			#continue

			rm -rf "$dirname" 2>/dev/null
			mkdir -p "$dirname"
			dezip "$pkg" "$dirname"

			# Gerar lista de arquivos nos projetos
			rm -rf $idxfile 2>/dev/null
			fcount=$(find "$dirname" | wc -l)
			logit2 "Gerando indice em" "$idxfile"
			#lsfiles "$dirname" > $idxfile
			_lsfiles "$dirname" | while read x; do
				echo "."
				echo "$x" >> $idxfile
			done | shloading -n -l "Gerando indice" -t "$_name" -m $fcount -s 3
			lineclear -n -r
		done
	fi

	# Adicionar diretorios a lista de comparacoes
	if [ "x$DIRECTORIES" != "x" ]; then
		for xdir in $DIRECTORIES; do
			COMPDIRS="$COMPDIRS $xdir"
		done
	fi

	logitp "Percorrento pacotes e processando arquivos"
	compdone=""
	echo -n > $DUPIDX
	for idx1 in $IDXLIST; do

		for idx2 in $IDXLIST; do
			# listas iguais
			[ "$idx1" = "$idx2" ] && continue

			# verificar se combinacao ja foi testada (armazenar a md5 da comparacao em ordem alfabetica)
			kc=$( (echo $idx1; echo $idx2 ) | sort -u | md5sum | awk '{print $1}')
			fd=0; for x in $compdone; do if [ "$kc" = "$x" ]; then fd=1; break; fi; done
			[ "$fd" = "1" ] && continue
			compdone="$compdone $kc"

			bn1=$(basename $idx1 | sed 's/duptester-idx-//g')
			bn2=$(basename $idx2 | sed 's/duptester-idx-//g')
			#logit3 -n "Comparando:" "$bn1" "$bn2"

			# juntar arquivos
			tmpf="/tmp/duptester-tmp"
			tmpd="/tmp/duptester-dups"
			cat "$idx1" "$idx2" | sort > $tmpf
			tc=$(cat $tmpf | wc -l)

			# obter duplicacoes
			fstrdup "$tmpf" > $tmpd
			dupc=$(cat "$tmpd" | wc -l)

			# ignorar duplicacoes em arquivos de declaracoes do pacote
			cat "$tmpd" | while read act_item; do
				if [ "$act_item" = "/.done" ]; then continue; fi
				if [ "$act_item" = "/.scripts" ]; then continue; fi
				if [ "$act_item" = "/install/doinst.sh" ]; then continue; fi
				if [ "$act_item" = "/install/sets" ]; then continue; fi
				if [ "$act_item" = "/install/news" ]; then continue; fi
				if [ "$act_item" = "/install/deletes" ]; then continue; fi
				echo "$idx1:$idx2:$act_item" >> $DUPIDX
			done

		done

	done


	DUPCOUNT=$(cat $DUPIDX | wc -l)
	logit3 "Arquivos duplicados:" "$DUPCOUNT" "$DUPIDX"


	# Verificando
	if [ "$DUPCOUNT" -gt "0" ]; then
		cat $DUPIDX | while read xx; do
			actdir=$(echo "$xx" | cut -f1 -d':')
			lstdir=$(echo "$xx" | cut -f2 -d':')
			filitm=$(echo "$xx" | cut -f3 -d':')
			echoc -c red -l "[DUPLICADO]"
			echoc -c gray -l -n "    Projeto 1..........: "; echoc -c green -l "$actdir"
			echoc -c gray -l -n "    Projeto 2..........: "; echoc -c yellow   -l "$lstdir"
			echoc -c gray -l -n "    Arquiv conflitante.: "; echoc -c white -l "$filitm"
		done
		RET=7
	else
		logit "Nenhuma duplicacao encontrada"
	fi

	exit $RET



			# verificar linhas repetidas
			lineclear -r -n
			for i in $(seq 1 1 $tc); do
				n=$(($i+1))

				# fora de indice
				[ "$i" -ge "$tc" ] && continue

				# linha atual
				act_item=$(awk "NR==$i" $tmpf)



