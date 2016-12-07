#!/bin/sh

#
# Obter lista de arquivos dentro de um ficheiro compactado
#

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"


    abort(){
		echo
		echoc -c yellow -l " DEZIP ERROR" 2>/dev/null || echo " ABORTADO"
		echoc -B -c red -l " $@" 2>/dev/null || echo " $@"
		echo
		exit 1
   	}

   	# Parametro
	_ziplist_file="$1"
	_ziplist_izip="$1"
	_ziplist_filename=$(basename $_ziplist_file)

	# Critica basica
	# - arquivo informado?
	if [ "x$_ziplist_file" = "x" ]; then abort "Informe o arquivo compactado."; fi
	
	# - existe?		
	if [ ! -f "$_ziplist_file" ]; then abort "Arquivo '$_ziplist_file' nao encontrado."; fi

	_ziplist_file=$(readlink -f "$_ziplist_file")

	# obter extensao do arquivo
	_ziplist_ext=$(fileextension $_ziplist_filename)

	# Obter contagem de arquivos e comando de Ziplist
	case "$_ziplist_ext" in
		'xz')
			_ziplist_lister="tar -Jvtf $_ziplist_file"
			;;

		'txz')
			_ziplist_lister="tar -Jvtf $_ziplist_file"
			;;

		'zip')
			_ziplist_lister="unzip -l $_ziplist_file | egrep '.*[0-9]{2}-[0-9]{2}-[0-9]{4}'"
			;;

		'tgz')
			_ziplist_lister="tar -tvf $_ziplist_file"
			;;

		'bz2')
			_ziplist_lister="tar -tvf $_ziplist_file"
			;;

		'gz')
			_ziplist_lister="tar -tvf $_ziplist_file"
			_ziplist_deziper="tar -xvzf $_ziplist_file"
			;;

		# Arquivo de tipo desconhecido
		*)
			abort "Extensao desconhecida: '$_ziplist_ext'"
	esac

	# obter numero de arquivos
	eval "$_ziplist_lister"


