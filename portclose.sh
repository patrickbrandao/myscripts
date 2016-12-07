#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Fechar porta matando o software responsavel por abri-la
	_help(){
		echo
		echo "Use: portclose (port) (proto)"
		echo "       port: numero da porta"
		echo "       proto: udp, tcp, tcp6"
		echo
		exit
	}

	tport="$1"
	tproto="$2"

	# ajuda
	if [ "x$tport" = "x" ]; then _help; fi
	if [ "x$tproto" = "x" ]; then _help; fi
	if [ "$tproto" != "udp" -a "$tproto" != "tcp" -a "$tproto" != "tcp6" ]; then _help; fi

	# pegar via fuser
	pids=$(fuser "$tport/$tproto" 2>&1 | grep "$tport/$tproto" 2>&1 | cut -f2 -d: 2>/dev/null)

	# fuser pode falhar, pegar via netstat
	npids=$(netstat -tulpn | grep LISTEN | awk '{print $1"|"$4"|"$7}' | egrep ":$tport\|" | grep -i "$tproto" | cut -f3 -d'|' | cut -f1 -d'/')

	lpids=$(echo $npids $pids)
	if [ "$lpids" != "" ]; then
		for pid in $lpids; do
			kill -9 $pid 2>/dev/null 1>/dev/null
		done
	fi
