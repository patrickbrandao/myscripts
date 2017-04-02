#!/bin/sh

#
# Utilitario para configurar rede no linux
#

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

	# Funcoes
	_delfile(){ rm -f "$1" 2>/dev/null; }
	_abort(){ echo "$@"; exit 1; }

	# codigo de retorno
	STDNO=0

	# interface selecionada
	DEVSEL=""

	NAMES="google.com facebook.com registro.br slackmini.com.br"
	SITES="www.google.com.br www.registro.br www.uol.com.br"


	# SOmente root
	ipcuid=$(id -u)
	[ "$ipcuid" = "0" ] || _abort "IP-Config requer permissoes de root."

#----------------------------------------------------- detectar eths

	ETHS=$(lseth)
	VLANS=$(lsvlan)
	DEVS="$ETHS $VLANS"
	[ "x$ETHS" = "x" ] && _abort "Erro ao executar IP-Config: nenhuma interface de rede encontrada."

	# UP em todo mundo
	for dev in $DEVS; do ifconfig $dev up; ip link set up dev $dev; done 2>/dev/null

	# SELECIONAR INTERFACE DE REDE
	_select_device(){
		DEVSEL=""

		sdevprefix="/tmp/ipconfig-seldev"
		_delfile "$sdevprefix-choice"

		dreport=""
		h=9
		s=1
		for dev in $DEVS; do h=$(($h+1)); s=$(($s+1)); done

		# criar menu
		(
			echo '#!/bin/sh'
			echo
			echo -n 'dialog --title "IP-Config" '
			echo -n "--menu \"Seleciona a interface de rede\" $h 76 $s "
			for dev in $DEVS; do
				c=$(head -1 /sys/class/net/$dev/carrier)
				m=$(head -1 /sys/class/net/$dev/address)
				v4=$(ip addr show dev $dev | grep 'inet ' | awk '{print $2}')
				ipv4=""
				[ "x$v4" = "x" ] || ipv4=", IPv4 $v4"
				if [ "$c" = "0" ]; then
					echo -n "'$dev' 'SEM CABO, mac $m$ipv4' "
				else
					echo -n "'$dev' 'CABO OK, mac $m$ipv4' "
				fi
			done
			echo -n '"SAIR" "Sair" '
			echo -n "2> $sdevprefix-choice;"
			echo -n 'exit $?'
 		) > $sdevprefix-menu
		sh $sdevprefix-menu

		DEVSEL=$(head -1 $sdevprefix-choice 2>/dev/null)
		[ "$DEVSEL" = "SAIR" ] && exit 1
		[ "x$DEVSEL" = "x" ] && exit 2
		return 0
	}

	# CONFIGURAR IP FIXO
	IPV4SEL=""
	MASKSEL=""
	GWSEL=""
	DNSSEL=""
	_config_ip(){
		cipprefix="/tmp/ipconfig-config-ip"
		_delfile "$cipprefix-choice"

		dialog --ok-label "Definir" \
			  --title "IP-Config" \
			  --form "IP-Config - IP Fixo em $DEVSEL\nUse as teclas CIMA e BAIXO para alternar os campos." \
		11 60 0 \
			"Endereco IP:" 1 1	"$IPV4SEL" 	1 10 15 0 \
			"Mascara:"     2 1	"$MASKSEL"  2 10 15 0 \
			"Gateway:"     3 1	"$GWSEL"  	3 10 15 0 \
			"DNS:"         4 1	"$DNSSEL" 	4 10 15 0 \
		2>$cipprefix-choice

		# Coletar
		IPV4SEL=$(head -1 $cipprefix-choice)
		MASKSEL=$(head -2 $cipprefix-choice | tail -1)
		GWSEL=$(head -3 $cipprefix-choice | tail -1)
		DNSSEL=$(head -4 $cipprefix-choice | tail -1)

		# apagar ips sintaticamente incorretos
		is_ipv4 "$IPV4SEL" || IPV4SEL=""
		is_ipv4 "$MASKSEL" || MASKSEL=""
		is_ipv4 "$GWSEL" || GWSEL=""
		is_ipv4 "$DNSSEL" || DNSSEL=""
	}

	# Obter servidores DNS
	_get_dns_servers(){
		# obter lista de servidores DNS no resolv
		dnslist=""
		list=$(cat /etc/resolv.conf  | grep nameserver | sed 's/nameserver//g')
		n=0
		for x in $list; do
			x=$(echo $x)
			is_ipv4 "$x" || continue
			dnslist="$dnslist $x"
			n=$(($n+1))
		done
		echo $dnslist
	}

	# DEFINIR UM DNS COMO PREFERENCIAL
	# sem remover outros, 3 dns na fila
	_set_dns_master(){
		newdns="$1"

		# obter lista de servidores DNS no resolv
		dnslist=""
		list=$(cat /etc/resolv.conf  | grep nameserver | sed 's/nameserver//g')
		n=0
		for x in $list; do
			x=$(echo $x)
			[ "$x" = "$newdns" ] && continue
			is_ipv4 "$x" || continue
			dnslist="$dnslist $x"
			n=$(($n+1))
		done

		# usar novo dns como principal
		dnslist="$newdns $dnslist"
		# usar apenas 3 servidores dns
		c=0
		usedns=""
		for x in $dnslist; do
			usedns="$usedns $x"
			c=$(($c+1))
			[ "$c" = "3" ] && break
		done

		# gravar
		(for x in $usedns; do echo "nameserver $x"; done) > /etc/resolv.conf
	}

	# Teste de ping
	_ping_test(){
		pip="$1"
		echoc -c cyan -n " - Testando ping para $pip"

		xping=$(ping "$pip" -c 1 -q | grep 'min/avg/max' | cut -f2 -d '='); pret="$?"
		#echo "PRET: $pret / [$xping]"
		if [ "$pret" = "0" ]; then
			echoc -c green ", OK - Latencia: $xping"
			return 0
		else
			echoc -c red ", PROBLEMA, sem resposta."
			return 1
		fi
	}

	# Teste de site
	_http_test(){
		hsite="http://$1"
		echoc -c cyan -n " - Testando site '$hsite'"

		(timeout -t 2 wget -s -O /dev/null "$hsite" || timeout 2s wget -4 -O /dev/null "$hsite") 2>/dev/null 1>/dev/null
		rt="$?"
		if [ "$rt" = "0" ]; then
			echoc -c green " OK"
			return 0
		else
			echoc -c red " FALHOU"
			return 1
		fi
	}

	# Testar INTERNET
	_network_test(){
		# 1 - testar gateway padrao
		# descobrir gateway
		gw=$(ip -o ro get 1.2.3.4 | sed 's/via/:/g' |cut -f2 -d: | awk '{print $1}')
		if [ "x$gw" = "x" ]; then
			echoc -c red " - Problema: SEM GATEWAY PADRAO"
		else

			# ip local
			locip=$(ip -o ro get 1.2.3.4 | sed 's/src/:/g' |cut -f2 -d: | awk '{print $1}')
			echoc -c cyan -n " - IP local.: "; echoc -c green "$locip"
			echoc -c cyan -n " - Gateway..: "; echoc -c green "$gw"

			# 1-gw-ping
			_ping_test "$gw"; pr="$?"
			if [ "$pr" = "0" ]; then
				echoc -c cyan " - Gateway responde a PING"
			else
				echoc -c red " - Problema: gateway nao responde a PING"
			fi

			# 1-gw-mac
			mac=""
			x=$(cat /proc/net/arp | egrep "^$gw[^0-9]" | awk '{print $4}')
			for mac in $x; do break; done
			[ "$mac" = "00:00:00:00:00:00" ] && mac=""
			if [ "x$mac" = "x" ]; then
				echoc -c red " - Problema: incapaz de determinar o MAC-ADDRESS do gateway"
			else
				echoc -c cyan -n " - MAC-ADDRESS do gateway: "; echoc -c green "$mac"
			fi
		fi

		# 2 - testar DNS
		nameservers=$(_get_dns_servers)
		if [ "x$nameservers" = "x" ]; then
			echoc -c red " - Problema: nenhum servidor DNS configurado. Ativando: 127.0.0.1 8.8.8.8 4.2.2.2"
			_set_dns_master 4.2.2.2
			_set_dns_master 127.0.0.1
			_set_dns_master 8.8.8.8
			nameservers="8.8.8.8 127.0.0.1 4.2.2.2"
		fi
		echoc -c cyan -n " - Testando servidores DNS: "; echoc -c green "$nameservers"
		okdns=""
		ok=0
		for dns in $nameservers; do
			echoc -c cyan -n " - Testando...............: "; echoc -c green "$dns"
			for name in $NAMES; do
				(
					timeout -t 3 nslookup "$name" "$dns" || \
					timeout 3 nslookup "$name" "$dns"
				) 2>/dev/null 1>/dev/null
				ret="$?"
				# deu certo, parar de testar nomes
				if [ "$ret" = "0" ]; then ok=1; break; fi
			done
			# deu certo, parar de testar servidores
			if [ "$ok" = "1" ]; then
				okdns="$dns"
				break
			fi
		done
		if [ "x$okdns" = "x" ]; then
			echoc -c red " - Problema: NENHUM SERVIDOR DNS FUNCIONOU"
		else
			echoc -c cyan -n " - DNS Funcionando: "; echoc -c green "$okdns"
		fi

		# 3 - testar pings na internet
		a0=0; a1=0; a2=0; a3=0
		_ping_test "200.160.2.3"; a0="$?"
		_ping_test "8.8.8.8"; a1="$?"
		_ping_test "4.2.2.2"; a2="$?"
		_ping_test "31.13.76.68"; a3="$?"
		if [ "$a0$a1$a2$a3" = "1111" ]; then
			# PESSIMO
			echoc -c cyan -n " - Ping para internet perfeito - "; echoc -c green "OK"
		elif [ "$a0$a1$a2$a3" = "1111" ]; then
			# OTIMO
			echoc -c red " - Problema: ping para internet falhou"
		else
			# MAIS OU MENOS
			echoc -c cyan -n " - Ping para internet funcionando - "; echoc -c green "OK"
		fi

		# 4 - sites
		siteok=0
		for site in $SITES; do
			_http_test "$site"
			if [ "$?" = "0" ]; then
				siteok=1
				#break
			fi
		done
		if [ "$siteok" = "1" ]; then
			echoc -c cyan -n " - Teste de acesso HTTP - "; echoc -c green "OK"
		else
			echoc -c red " - Teste de acesso HTTP - FALHOU"
		fi

		exit
	}

#----------------------------------------------------- DIRETO

	# Testar
	if [ "$1" = "test" -o "$1" = "teste" -o "$1" = "t" ]; then _network_test; fi

	# DHCP GERAL
	if [ "$1" = "auto" -o "$1" = "aut" -o "$1" = "a" ]; then
		echo -n "- Ativando DHCP geral "
		for i in 1 2 3 4; do killall dhcpcd 2>/dev/null; done
		for dev in $DEVS; do
			(/sbin/dhcpcd -t 35 -L $dev) 2>/dev/null 1>/dev/null &
			echo -n " [$dev]"
		done
		echo " OK"
		exit
	fi

#----------------------------------------------------- MENU


	# Menu principal
	while [ 0 ]; do

		mmprefix="/tmp/ipconfig-main"
		_delfile "$mmprefix-choice"

		dreport=""
		h=16
		for dev in $DEVS; do
			c=$(head -1 /sys/class/net/$dev/carrier)
			m=$(head -1 /sys/class/net/$dev/address)
			v4=$(ip addr show dev $dev | grep 'inet ' | awk '{print $2}')
			ipv4=""
			[ "x$v4" = "x" ] || ipv4=", IPv4 $v4"
			if [ "$c" = "0" ]; then
				dreport="$dreport\n$dev = SEM CABO, mac $m$ipv4"
			else
				dreport="$dreport\n$dev = CABO OK, mac $m$ipv4"
			fi
			h=$(($h+1))
		done

		# descobrir gateway
		gw=$(ip -o ro get 1.2.3.4 | sed 's/via/:/g' |cut -f2 -d: | awk '{print $1}')
		gateway=""
		[ "x$gw" = "x" ] || gateway="Gateway padrao: $gw"

		# criar menu
		(
			echo '#!/bin/sh'
			echo
			echo -n 'dialog --title "IP-Config" '
			echo -n "--menu \"Configurar acess a rede IP / Internet.\n\nInterfaces: $dreport \n$gateway\n\" $h 76 5 "
			echo -n '"Atualizar" "Atualizar status das interfaces de rede" '
			echo -n '"Testar" "Testar acesso a internet" '
			echo -n '"DHCP" "Automatico - Obter IP/Mascara/Gateway/DNS via DHCP" '
			echo -n '"IP Fixo" "Manual - Configurar IP/Mascara/Gateway/DNS manualmente" '
			echo -n '"SAIR" "Sair do ipconfig" '
			echo -n "2> $mmprefix-choice;"
			echo -n 'exit $?'
 		) > $mmprefix-menu
		sh $mmprefix-menu

		#--	"REPARAR"			"Reparar uma instalacao danificada neste servidor" \

		if [ ! $RET = 0 ]; then echo "Falha no menu. Tente novamente"; sleep 1; continue; fi
		MAINSELECT=$(head -1 $mmprefix-choice 2>/dev/null)

		# Executar script de acordo com a escolha
		#
		# INSTALAR
		#
		if [ "$MAINSELECT" = "DHCP" ]; then

			STDNO=0

			# selecionar a interface
			_select_device

			# matar processo corrente se existir
			# rodar novo processo
			echo -n "- Executando cliente dhcp na interface $DEVSEL, aguarde."
			(
				apid=$(ps ax | grep dhcp | grep $DEVSEL | awk '{print $1}')
				[ "x$apid" = "x" ] || kill -9 "$apid" 2>/dev/null
				/sbin/dhcpcd -t 35 -L $DEVSEL
			) 2>/dev/null 1>/dev/null &

			# aguardar
			for i in 1 2 3 4 5; do echo -n "."; sleep 1; done

			# voltar para o menu principal, permitir visualizacao do resultado
			continue
		fi

		# REPARAR
		if [ "$MAINSELECT" = "IP Fixo" ]; then
			
			# selecionar a interface
			_select_device

			# obter configuracao IP
			_config_ip

			# apagar ips invalidos
			is_ipv4 "$IPV4SEL" || IPV4SEL=""
			is_ipv4 "$MASKSEL" || MASKSEL=""
			is_ipv4 "$GWSEL" || GWSEL=""
			is_ipv4 "$DNSSEL" || DNSSEL=""
			# Caso ip ou mascara sejam omitidos, pular
			[ "x$IPV4SEL" = "x" ] && continue
			[ "x$MASKSEL" = "x" ] && continue

			#echo "IPV4SEL[$IPV4SEL] MASKSEL[$MASKSEL] GWSEL[$GWSEL] DNSSEL[$DNSSEL]"; sleep 2

			# configurar interface
			echo -n "- Configurando interface $DEVSEL com ip '$IPV4SEL' / '$MASKSEL'"
			(
				ifconfig $DEVSEL up
				ifconfig $DEVSEL "$IPV4SEL" netmask "$MASKSEL"
				ip addr add "$IPV4SEL/$MASKSEL" dev eth0.20
				ifconfig $DEVSEL up
				sleep 1
			) 2>/dev/null 1>/dev/null
			echo " OK"

			# configurar gateway
			if [ "x$GWSEL" != "x" ]; then
				echo -n "- Definindo gateway padrao: '$GWSEL'"
				(
					ip route del default metric 1
					ip route add default via "$GWSEL" metric 1
					# gateway redundante caso o usuario faca coisa errada (ou nao)
					ip route add default via "$GWSEL" metric 2
					sleep 1
				) 2>/dev/null 1>/dev/null
				echo " OK"
			fi

			# definir DNS
			if [ "x$DNSSEL" != "x" ]; then
				echo -n "- Definindo servidor DNS: '$DNSSEL'"
				_set_dns_master "$DNSSEL"
				sleep 1
				echo " OK"
			fi

			# apagar variaveis
			IPV4SEL=""
			MASKSEL=""
			GWSEL=""
			DNSSEL=""

			# voltar para o menu principal
			continue
		fi

		# Testar
		if [ "$MAINSELECT" = "Testar" ]; then
			clear
			_network_test
		fi


		# Atualizar apenas
		if [ "$MAINSELECT" = "Atualizar" ]; then
			clear
			sleep 1
			continue
		fi


		# SAIR para o shell
		if [ "$MAINSELECT" = "SAIR" ]; then
			break
		fi
		break

	done
	# fim menu principal


#----------------------------------------------------- encerrar

	exit $STDNO




			for dev in $DEVS; do
				echo -n '"$dev" "Instalar o Slackmini neste servidor" '
			done








