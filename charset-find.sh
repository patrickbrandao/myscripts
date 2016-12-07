#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

FOLDER=$1
CS=$2

do_help(){
	echo "Erro: $1"
	echo
	echo "$0 (pasta) (charset)"
	echo "	Procura arquivos na pasta que usem o charset especificado"
	echo "  Caso queira listar todos os charsets, use a palavra 'all'"
	echo
	exit 1
}

# Criticar
	[ -d "$FOLDER" ] || do_help "Informe a pasta (parametro 1)"
	[ "$CS" = "" ] && do_help "Informe o charset procurado (parametro 2)"


	cd "$FOLDER" || do_help "Erro ao entrar na pasta $FOLDER"


# iniciar procura
find | while read filename; do
	[ -f "$filename" ] || continue
	cs=$(file -bi $filename 2>/dev/null)
	if [ "$cs" = "" ]; then continue; fi

	if [ "$CS" = "all" ]; then
		echo "$filename;$cs"
	else
		echo "$filename;$cs" | grep -i "$CS"
	fi
done

