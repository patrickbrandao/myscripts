#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

#
# Matar processo cuidando de excessoes
#

# Pidfile do processo
	PIDFILE="$1"

# Nome do processo, para nao matar o pid do pidfile velho
#	qua aponta para um processo diferente
	PNAME="$2"

# Nao matar o pid de um script com o mesmo nome do programa
	NOTKILLPID="$3"

# Matar com -9 ou apenas enviar sinal de kill
	FORCE9="$4"

# matar pelo nome
	KILLBYNAME="$5"

# Ajuda
	_print_help(){
		echo
		echoc -c gray " Matar processo sem equivocos"
		echoc -c gray " Use:"
		echoc -c gray "    killscript (PIDFILE) (PNAME) (NO-KILL-PID) [-9]"
		echo
		exit
	}
	[ "$1" = "-h" -o "x$2" = "x" ] && _print_help

# Obter pid do pidfile, se o nome do processo bater podemos matar sem medo
	PID=""
	if [ "x$PIDFILE" != "x" -a -f "$PIDFILE" ]; then
		PID=$(head -1 "$PIDFILE" 2>/dev/null)
		pidfilecheck "$PIDFILE" "$PNAME" && kill -QUIT "$PID" 2>/dev/null
	fi

# Matar processo pelo nome, caso haja processos ainda rodando ou sem registro em PIDFILE
# cuidando para nao matar a excessao

	# matar processo pelo nome, desde que nao seja esse script
	onlinepids=$(pidof $PNAME)
	if [ "x$NOTKILLPID" = "x" ]; then
		# sem execessao, matar todo mundo
		for xpid in $onlinepids; do kill $FORCE9 $xpid 2>/dev/null; done
	else
		# execcao, esquivar
		for xpid in $onlinepids; do
			[ "$xpid" = "$NOTKILLPID" ] && continue
			kill $FORCE9 $xpid 2>/dev/null
		done
	fi



