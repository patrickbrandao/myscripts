#!/bin/sh

_getts(){ date "+%s"; }

# parametros
ip="$1"
port="$2"
path="$3"
[ "x$ip" = "x" ] && ip="172.20.0.49"
[ "x$port" = "x" ] && port=1822
[ "x$path" = "x" ] && path="/admin"

# cruzar relatividade
here=$(pwd)

alias echo=/bin/echo
lastts=$(_getts)
echo "Inicio"
while read x; do
	# nao upar temporarios
	echo $x | egrep '\.tmp$' >/dev/null && echo "SKIP: $x" && continue

	# sempre dar pause entre updates
	xts=$(_getts)
	difts=$(($xts-$lastts))
	if [ "$difts" -ge "3" ]; then echo "(PAUSE)"; sleep 1; fi

	# retirar o caminho base
	x1=$(echo $x | sed "s#^$here/##")

	# ignorar a primeira parte do caminho, que e'
	# do diretorio do projeto
	rf=$(echo $x1 | cut -f2,3,4,5,6,7,8 -d'/')

	# nome do projeto que foi alterado
	rp=$(echo $x1 | cut -f1 -d'/')

	# se for diretorio, sincronizar projeto inteiro para
	# evitar que arquivos sejam criados em diretorios
	# locais que nao existem remotamente
	if [ -d "$x" ]; then
		# diretorio
		echo -n "Sincronizando projeto: [$rp -> $ip:$path/] "
		rsync -rap -e "ssh -p$port" $rp/* root@$ip:$path/
		echo " OK"
	else
		# arquivo
		echo -n "Sincronizando arquivo: [$rf -> $path/$rf] "
		chmod +x $rp/$rf
		rsync -rap -e "ssh -p$port" $rp/$rf root@$ip:$path/$rf
		echo " OK"
	fi
done
echo "Fim"

