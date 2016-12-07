#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

#
# Script para montar RAM-FS em pasta
#

# Variaveis
	# Acao: help, start, stop
	ACTION=help

	# - Diretorio
	MOUNTPOINT=""

	# - Tamanho em kbytes
	MOUNTSIZE=""

# Funcoes
	# Abortar com erro
	_error(){
		echo "Erro: $@"
		exit 9
	}
	# Ajuda
	_print_help(){
		echo
		echo "Use: mount.ramfs -d (directory) -s (size-kbytes) (stop/start)"
		echo
		exit 1
	}
	# Listar montagens RAM-FS
	_print_list(){
		echo
		echoc -B -c white "  Directory           Size"
		_list=$(mount -t ramfs | awk '{print $1}')
		if [ "x$_list" = "x" ]; then
			echoc -c white "  (nenhuma montagem encontrada)"
		else
			# listar
			for _dir in $_list; do
				echo -n "  "
				echoc -n -c "white" -R 20 "$_dir"
				_size=$(mount -t ramfs | egrep "^/ram[^a-z0-9/._]" | sed 's#maxsize=#:#g' | cut -f2 -d: | cut -f1 -d')')
				echoc -n -c "green" "$_size"
				echo
			done
		fi
		echo
		exit 0
	}
	# Verificar se esta montado
	_ismounted(){
		# verificar se ja esta montado
		[ "x$MOUNTPOINT" = "x" ] && return 1
		t=$(mount -t ramfs | egrep "^$MOUNTPOINT[^a-z0-9/._]")
		[ "x$t" = "x" ] && return 2
		return 0
	}
	# Obter diretorio
	_get_directory(){
		# parametro correto?
		(strlike "-d" "$1" >/dev/null || strlike "directory" "$1" >/dev/null || strlike "path" "$1" >/dev/null) || return 2
		# caracteres permitidos:
		str_onlychars "$2" -D -q || _error "Diretorio sintaticamente incorreto"

		# nao pode ser arquivo ou link
		[ -e "$2" -a ! -d "$2" ] && _error "Apenas diretorios podem ser informados"

		# diretorio OK e existe
		[ -d "$2" ] && MOUNTPOINT="$2" && return 0

		# criar diretorio que nao existe
		mkdir -p "$2" || _error "Erro ao criar diretorio '$2'"
		MOUNTPOINT="$2"
		return 0
	}
	# Obter tamanho
	_get_size(){
		# parametro correto?
		(strlike "-s" "$1" >/dev/null || strlike "size" "$1" >/dev/null || strlike "lenght" "$1" >/dev/null) || return 2
		MOUNTSIZE="$2"
		return 0
	}
	# Acao
	_is_action(){
		(strlike "start" "$1" >/dev/null)  && ACTION="start" && return 0
		(strlike "stop" "$1" >/dev/null)  && ACTION="stop" && return 0
		(strlike "list" "$1" >/dev/null || [ "$1" = "-l" ])  && ACTION="list" && return 0
		(strlike "help" "$1" >/dev/null || [ "$1" = "-h" ])  && ACTION="help" && return 0
		return 1
	}

# Processar argumentos
	while [ 0 ]; do

		# acabou
		[ "x$1" = "x" ] && break

		# Ajuda
		# Modo help
		hlike=$(strlike help "$1")
		if [ "$hlike" -ge "1" -o "$1" = "-h" ]; then _print_help; fi

		#-------------------------- parametros separados por igual (=)
		in_str "=" "$1"
		if [ "$?" = "0" ]; then
			_var=$(strcut -c = -n1 -s "$1")
			_value=$(strcut -c = -n2 -s "$1")
			_get_directory "$_var" "$_value" && shift && continue
			_get_size "$_var" "$_value" && shift && continue
			# pares var=value sao todos processados aqui, se nao achou -> ignorar
			shift
			continue
		fi
		#-------------------------- parametros separados por espaco
		_get_directory "$1" "$2" && shift 2 && continue
		_get_size "$1" "$2" && shift 2 && continue

		#-------------------------- parametros avulcos
		_is_action "$1" && shift && continue

		# parametro desconhecido, abortar
		_error "Parametro desconhecido: '$1'"

	done

#--------------------------------------------------

	# Ajuda
	[ "$ACTION" = "help" ] && _print_help

	# Listar
	[ "$ACTION" = "list" ] && _print_list

	# Daqui em dianta o ponto de montagem e' obrigatorio
	[ "x$MOUNTPOINT" = "x" ] && _error "Informe o diretorio de montagem."

	# PARAR
	if [ "$ACTION" = "stop" ]; then
		umount "$MOUNTPOINT" 2>/dev/null
		umount -f "$MOUNTPOINT" 2>/dev/null
		exit 0
	fi

# INICIAR MONTAGEM ----------------------------------------------------------------- START

	# Ja esta montado
	_ismounted "$MOUNTPOINT" && exit 0
	#- _error "O diretorio '$MOUNTPOINT' ja esta montado."

	# ****** RAM-SIZE

	# Tamanho da montagem (TAMANHO EM kilobytes)
	# - tamanho padrao: 5 megas
	_stdramsize=5000
	# - tamanho sugerido pelo sistema
	_sys_ramsize=$_stdramsize
	[ -f /etc/sysconfig/ramfs.size ] && _sys_ramsize=$(head -1 /etc/sysconfig/ramfs.size)
	# validar
	# - numerico
	is_int "$_sys_ramsize" || _sys_ramsize=$_stdramsize
	# - tamanho minimo: 5 mb
	# - tamanho maximo: 40 gb
	in_numrange "$_sys_ramsize" "5000" "40192152" || _sys_ramsize=$_stdramsize
	# Se o tamanho for omitido, usar valor do sistema
	[ "x$MOUNTSIZE" = "x" ] && MOUNTSIZE="$_sys_ramsize"


	# ****** DIRECTORY

	# garantir existencia
	mkdir -p $MOUNTPOINT 2>/dev/null 1>/dev/null

	# Se nao existir, bugou
	[ -d "$MOUNTPOINT" ] || _error "Diretorio '$MOUNTPOINT' nao existe."

	# Montar
	_err=$(mount -t ramfs $MOUNTPOINT $MOUNTPOINT -o maxsize=$MOUNTSIZE 2>&1)
	ret="$?"
	if [ "$ret" = "0" ]; then

		# Criar RID
		ts=$(date "+%s")
		_rid=$(dechex "$ts")
		echo "$_rid" > "$MOUNTPOINT/.ram-id"

		# Criar pasta temporaria
		mkdir "$MOUNTPOINT/cache" 2>/dev/null
		mkdir "$MOUNTPOINT/conf" 2>/dev/null
		mkdir "$MOUNTPOINT/log" 2>/dev/null
		mkdir "$MOUNTPOINT/run" 2>/dev/null
		mkdir "$MOUNTPOINT/tmp" 2>/dev/null

		mkdir "$MOUNTPOINT/.tmp" 2>/dev/null
		mkdir "$MOUNTPOINT/.cache" 2>/dev/null

		exit 0
	else
		# Erro na montagem
		_error "Mount error '$ret': '$_err'"
		exit 4
	fi


	#-	echo "ACTION...........: [$ACTION]"
	#-	echo "RID..............: [$RID]"
	#-	echo "MOUNTPOINT.......: [$MOUNTPOINT]"
	#-	echo "MOUNTSIZE........: [$MOUNTSIZE]"




