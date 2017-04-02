#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"


    abort(){
		echo
		echoc -c yellow -l " DEZIP ERROR" 2>/dev/null || echo " ABORTADO"
		echoc -B -c red -l " $@" 2>/dev/null || echo " $@"
		echo
		exit 1
   	}

	_dezip_file="$1"
	_dezip_izip="$1"
	_dezip_outdir="$2"


	if [ "$_dezip_outdir" = "" ]; then _dezip_outdir=$(pwd); fi
	_dezip_filename=$(basename $_dezip_file)

	# Critica basica
	# - arquivo informado?
	if [ "x$_dezip_file" = "x" ]; then abort "Informe o arquivo compactado."; fi
	
	# - existe?		
	if [ ! -f "$_dezip_file" ]; then abort "Arquivo '$_dezip_file' nao encontrado."; fi

	_dezip_file=$(readlink -f "$_dezip_file")
	logit2 "Dezip arquivo" "$_dezip_file"

	cd "$_dezip_outdir" || abort "Erro ao entrar na pasta '$_dezip_outdir'"

	# obter extensao do arquivo
	_dezip_ext=$(fileextension $_dezip_filename)

	logit3 -n "dezip: Preparando" "$_dezip_filename" "(aguarde)"

	# Obter contagem de arquivos e comando de dezip
	case "$_dezip_ext" in
		'xz')
			_dezip_filecounter="tar -Jvtf $_dezip_file | wc -l"
			_dezip_deziper="tar -xvf $_dezip_file"
			;;

		'txz')
			_dezip_filecounter="tar -Jvtf $_dezip_file | wc -l"
			_dezip_deziper="tar -xvf $_dezip_file"
			;;

		'lz')
			_dezip_filecounter="tar -vtf $_dezip_file | wc -l"
			_dezip_deziper="tar -xvf $_dezip_file"
			;;

		'zip')
			_dezip_filecounter="unzip -l $_dezip_file | egrep '.*[0-9]{2}-[0-9]{2}-[0-9]{4}' | wc -l"
			_dezip_deziper="unzip -o $_dezip_file"
			;;

		'tgz')
			_dezip_filecounter="tar -tvf $_dezip_file | wc -l"
			_dezip_deziper="tar -xvzf $_dezip_file"
			;;

		'bz2')
			_dezip_filecounter="tar -tvf $_dezip_file | wc -l"
			_dezip_deziper="tar -xjvf $_dezip_file || tar -xvf $_dezip_file"
			;;

		'gz')
			_dezip_filecounter="tar -tvf $_dezip_file | wc -l"
			_dezip_deziper="tar -xvzf $_dezip_file || tar -xvf $_dezip_file"
			;;

		# Arquivo de tipo desconhecido
		*)
			abort "Extensao desconhecida: '$_dezip_ext'"
	esac

	# obter numero de arquivos
	_dezip_file_count=$(eval "$_dezip_filecounter")
	#logit2 -n "dezip: Arquivos no pacote" "$_dezip_file_count"

	eval "$_dezip_deziper" 2>&1  | shloading -l "dezip" -t "$_dezip_filename" -m "$_dezip_file_count" -c -n || abort "Erro ao descompactar '$_dezip_filename' com '$_dezip_deziper'"
	logit3 "dezip: Arquivo descompactado:" "$_dezip_filename" "$_dezip_outdir"






