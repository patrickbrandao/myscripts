#!/bin/sh

#
#
# Sincronizar arquivo remoto com arquivo local
#
#
export PATH="/usr/bin:/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# 
# Variaveis informadas por parametros
#----------------------------------------------------------------------------
	LABEL="http-sync"

# URL do arquivo
	URL=""

# pasta do arquivo (adicionar a url)
	UPATH=""

# Variaveis a adicionar
	VARS=""
	QSTRING=""

# Dados HTTP, http OU https
	PROTO=http
	PORT=""

# Opcoes TCP
	TIMEOUT=5
	READTIMEOUT=3
	TRIES=3
	RETRIES=300
	LOCALFILE=""
	FILENAME=""

# Suportar dual-stack?
	DUALSTACK=0

# Codigo de retorno
	STDNO=0

# MODO debug
	DEBUG=0

#
# Variaveis geradas
#----------------------------------------------------------------------------

# Variaveis locais
	# url final, URL + variaveis, do ARQUIVO
	FINALURL_FILE=""
	# url final, URL + variaveis, do MD5 (arquivo.md5)
	FINALURL_MD5=""

	# arquivo temporario local
	# - arquivo baixado
	LOCALTMPFILE=""
	# - valor md5 do arquivo baixado
	LOCALTMPFILE_MD5=""
	# - arquivo md5 do arquivo local (extensao .xxx substituida por .md5)
	MD5FILE=""
	# - valor do arquivo md5 local
	MD5VALUE=""

	# - arquivo md5 baixado
	REMOTEMD5FILE=""
	# - valor do arquivo md5
	REMOTEMD5FILE_MD5=""

	# Controle de necessidade de UPDATE, 0=nao, >=1 sim
	# 0 = nao
	# 1 = arquivo local nao existe
	# 2 = md5 do arquivo local nao e' igual ao remoto
	NEEDUPDATE=0


#
# Funcoes
#----------------------------------------------------------------------------

	# limpar arquivos temporarios
	_tmp_clean(){
		[ -f "$LOCALTMPFILE" ] && rm -f "$LOCALTMPFILE" 2>/dev/null
		[ -f "$REMOTEMD5FILE" ] && rm -f "$REMOTEMD5FILE" 2>/dev/null
	}
	# Obter md5 do arquivo, 32 bytes
	_getmd5sum(){
		_gm_file=$1
		if [ -f "$_gm_file" ]; then
			md5sum $_gm_file 2>/dev/null | awk '{print $1}'
		else
			echo ""
		fi
	}
	# finalizar
   	_quit(){
   		_tmp_clean
   		exit $STDNO
   	}
	# Abortar execucao
    abort(){
		logity -n "[$LABEL] Fatal: "
		echoc -c red "$@"
		[ "$STDNO" = "0" ] && STDNO=10
		_quit
   	}
	# ajuda de como usar
	_usage() {
		_uerr="$1"
		if [ "x$_uerr" != "x" ]; then
			echo
			logity "Erro: [$_uerr]"
		fi
		echo
		echoc -c white -l -n 'Use: '; echoc -c green -l -n 'http-sync '; echoc -c cyan -n '[opcoes]'; echoc -c yellow ' <arquivo>'
		echoc -c gray        "  http-sync sincroniza um arquivo remoto com um arquivo local. STDNO"
		echo
		echoc -c cyan -l     '  Opcoes:'
		echoc -c green -l -n '     --url/-u      URL       ';     echoc -c gray ' - URL do arquivo'
		echoc -c green -l -n '     --proto/-P    PROTO     ';     echoc -c gray ' - Protocolo, HTTP ou HTTPS'
		echoc -c green -l -n '     --port/-p     PORT      ';     echoc -c gray ' - Porta, quando nao for padrao (80 ou 433)'
		echoc -c green -l -n '     --path/-a     PATH      ';     echoc -c gray ' - Pasta (adcionar a url) do arquivo'
		echoc -c cyan -l -n  '     --var/-v      VAR=VALUE ';     echoc -c gray ' - Verificar integridade dos arquivos apos instala-los'
		echoc -c cyan -l -n  '     --timeout/-t  TIMEOUT   ';     echoc -c gray ' - Tempo de espera ao iniciar conexao'
		echoc -c cyan -l -n  '     --zumbi/-z    TIMEOUT   ';     echoc -c gray ' - Tempo de espera quando conexao parar de responder'
		echoc -c cyan -l -n  '     --tries/-n    TRIES     ';     echoc -c gray ' - Numero de tentativas para conectar'
		echoc -c cyan -l -n  '     --retries/-r  RETRIES   ';     echoc -c gray ' - Numero de tentativas repetidas quando parar de responder'
		echoc -c cyan -l -n  '     --dual-stack/-d         ';     echoc -c gray ' - Ativar dual-stack, suporte IPv6 e IPv4, padrao: apenas IPv4'
		echoc -c cyan -l -n  '     --debug/-D              ';     echoc -c gray ' - Ativar debug para localizar problemas'
		echoc -c cyan -l -n  '     --label/-l              ';     echoc -c gray ' - Label prefixo do log na tela'
		echoc -c green -l -n '     <arquivo>               ';     echoc -c gray ' - Caminho do arquivo local a ser salvo/atualizado'
		echo
		echoc -c cyan -l      '  Retorno no STDNO:'
		echoc -c white -l -n  '      0';     echoc -c gray ' - Arquivo nao foi alterado'
		echoc -c green -l -n  '      1';     echoc -c gray ' - Arquivo alterado e atualizado'
		echoc -c yellow -l -n '      2';     echoc -c gray ' - Arquivo alterado mas nao foi atualizado'
		echoc -c yellow -l -n '      4';     echoc -c gray ' - Erro HTTP: erro de DNS ou conexao recusada'
		echoc -c yellow -l -n '      8';     echoc -c gray ' - Erro HTTP: not-found'
		echoc -c red -l -n    '     11';     echoc -c gray ' - Arquivo local nao foi informado.'
		echoc -c red -l -n    '     12';     echoc -c gray ' - Incapaz de acessar/criar arquivo local.'
		echoc -c red -l -n    '     20';     echoc -c gray ' - Falha durante execucao.'
		echoc -c red -l -n    '     21';     echoc -c gray ' - Erro ao obter MD5 remoto (conexao).'
		echoc -c red -l -n    '     22';     echoc -c gray ' - Erro ao obter MD5 remoto, conteudo incompativel com hash md5'
		echoc -c red -l -n    '     23';     echoc -c gray ' - Erro ao obter arquivo remoto (conexao).'
		echoc -c red -l -n    '     24';     echoc -c gray ' - Erro ao obter arquivo remoto (tamanho zero).'
		echoc -c red -l -n    '     99';     echoc -c gray ' - Erro desconhecido.'
		echo
		exit 1
	}
	# construir URL
	_build_url(){

		#*** Construir query-string
		QSTRING=""
		# timestamp para nocache via qs
		_bu_tsnow=$(date "+%s")
		# juntar variaveis existentes
		if [ "x$VARS" = "x" ]; then
			# apenas nocache
			QSTRING="nocache=$_bu_tsnow"
		else
			for _v in $VARS; do
				if [ "x$QSTRING" = "x" ]; then QSTRING="$_v"; else QSTRING="$QSTRING&$_v"; fi
			done
			# adicionar nocache
			QSTRING="$QSTRING&nocache=$_bu_tsnow"
		fi		

		#*** Construir URL
		_bu_url=""
		# nome do arquivo desejado
		_bu_file="$FILENAME"
		# extensao do arquivo
		_bu_fext=$(fileextension "$_bu_file")

		# Nome da URL pode conter @ sequenciais,
		# que deve ser substituido por numero (0-9)
		# ex.: @ por 7, @@ por 91, @@@ por 374
		#
		_bu_outurl="$URL"
		_bu_cc=$(countchar "@" "$_bu_outurl")
		if [ "$_bu_cc" -ge "1" ]; then
			# Precisa trocar
			# - obter numero aleatorio com o numero de digitos necessarios
			_bu_num=$(echo $RANDOM | rev | cut -b1-$_bu_cc)
			# - gerar sequencia que aparece na url
			_bu_chrs=$(str_repeat "@" "$_bu_cc")
			_bu_outurl=$(str_replace "$_bu_outurl" "$_bu_chrs" "$_bu_num")
		fi

		# adicionar porta? apenas se a porta foi omitida e nao houv
		in_str ":" "$_bu_outurl"; p1="$?"
		in_str "/" "$_bu_outurl"; p2="$?"
		if [ "$p1$p2" = "11" ]; then
			if [ "$PROTO" = "https" -a "$PORT" != "433" ]; then
				# porta https diferente da 433
				_bu_url="$_bu_outurl:$PORT/"
			fi
			if [ "$PROTO" = "http" -a "$PORT" != "80" ]; then
				# porta http diferente da 80
				_bu_url="$_bu_outurl:$PORT/"
			fi
			[ "x$_bu_url" = "x" ] && _bu_url="$_bu_outurl/"
			#logity "TRUE-IF _bu_url: [$_bu_url] _bu_outurl=[$_bu_outurl] PROTO=$PROTO PORT=$PORT"
		else
			# provavelmente, a porta foi inserida no protocolo
			# ou o usuario ja informou a url montada
			_bu_url="$_bu_outurl"
			#logity "FALSE-ELSE"
		fi
		#logitg "TESTE, _bu_url: [$_bu_url] _bu_outurl=[$_bu_outurl]"

		# adicionar protocolo?
		in_str "https" "$_bu_url"; p1="$?"
		in_str "http" "$_bu_url"; p2="$?"
		in_str "://" "$_bu_url"; p3="$?"
		# adicionar protocolo, caso ausente
		if [ "$p1$p2$p3" = "111" ]; then _bu_url="$PROTO://$_bu_url"; fi
		# Arquivo, quando omitido
		in_str "$_bu_file" "$_bu_url"; p4="$?"
		if [ "$p4" = "1" ]; then
			# o nome do arquivo nao consta na _bu_url
			if [ "x$UPATH" = "x" ]; then
				_bu_url="$_bu_url/$_bu_file"
			else
				# adicionar pasta
				_bu_url="$_bu_url/$UPATH/$_bu_file"
			fi
		fi
		# Adicionar variaveis
		in_str "?" "$_bu_url"; p5="$?"
		if [ "$p5" = "0" ]; then
			# ja existem variaveis GET na url, adicionar nossas
			_bu_url="$_bu_url&$QSTRING"
		else
			# nao existem variaveis, adicionar tb o '?'
			_bu_url="$_bu_url?$QSTRING"
		fi

		# remover '//' quando elas aparecerem fora do espaco http:// ou https://
		_bu_tmp=$(str_replace "$_bu_url" "http://" "-919-")
		_bu_tmp=$(str_replace "$_bu_tmp" "https://" "-929-")
		_bu_tmp=$(str_replace "$_bu_tmp" "//" "/")
		_bu_tmp=$(str_replace "$_bu_tmp" "//" "/")
		_bu_tmp=$(str_replace "$_bu_tmp" "-919-" "http://")
		_bu_url=$(str_replace "$_bu_tmp" "-929-" "https://")

		# Gerar url do arquivo
		FINALURL_FILE="$_bu_url"
		# Gerar url do md5
		FINALURL_MD5=$(str_replace "$FINALURL_FILE" ".$_bu_fext?" ".md5?")
	}
	# prograss-bar resumido - filtrar saida do wget
	_progressfilt(){
		grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
		return
		local flag=false c count cr=$'\r' nl=$'\n'
		while IFS='' read -d '' -rn 1 c
		do
			if $flag
			then
				printf '%c' "$c"
			else
				if [[ $c != $cr && $c != $nl ]]
				then
					count=0
				else
					((count++))
					if ((count > 1))
					then
						flag=true
					fi
				fi
			fi
		done
	}

	# obter arquivo via HTTP, usar funcao interna em vez de alias
	# 1: URL 2:ARQUIVO
	_http_get(){
		_hg_url="$1"
		_hg_file="$2"
		_hg_opt=""
		_hg_debug=""
		
		[ "$DUALSTACK" = "0" ] && _hg_opt="-4"

		#logit2 "[$LABEL] Baixando" "$_hg_url -> $_hg_file"
		_hg_eu=$(echo "$_hg_url" | cut -f1 -d'?')
		logit2 -n "[$LABEL] Baixando" "$_hg_eu -> "
		_hg_opt="$_hg_opt --no-cache --no-check-certificate --timeout=$TIMEOUT --read-timeout=$READTIMEOUT --tries=$TRIES --wait=1 --waitretry=1 -O $_hg_file"

		if [ "$DEBUG" = "0" ]; then
			wget --progress=dot $_hg_opt "$_hg_url" 2>&1 | _progressfilt
			_hg_ret="$?"
			lineclear -n -r
		else
			# modo debug
			logity "wget $_hg_opt '$_hg_url'"
			wget $_hg_opt "$_hg_url"
			_hg_ret="$?"
		fi
		return $_hg_ret
	}
	# retornar formato resumido do tamanho em bytes
	_get_size_human() { numfmt --to=iec "$1"; }

#
# Processar argumentos
#----------------------------------------------------------------------------
	ARGS="$@"
	while [ 0 ]; do
		# Ajuda
		if [ "$1" = "-h" -o "$1" = "--h" -o "$1" = "--help" ]; then _usage "Ajuda solicitada"; fi
		# URL
		if [ "$1" = "-url" -o "$1" = "--url"  -o "$1" = "-u" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe a URL apos o parametro"; exit; fi
			URL="$2"; shift 2; continue
		# PORTA DO SERVIDOR
		elif [ "$1" = "-port" -o "$1" = "--port"  -o "$1" = "-p" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe a PORTA apos o parametro"; exit; fi
			PORT="$2"; shift 2; continue
		# PROTOCOLO
		elif [ "$1" = "-proto" -o "$1" = "--proto"  -o "$1" = "-P" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe o PROTOCOLO (http ou https) apos o parametro"; exit; fi
			if [ "$2" != "http" -a "$2" != "https" ]; then _usage "Protocolo desconhecido: '$2'"; exit; fi
			PROTO="$2"; shift 2; continue
		# PASTA
		elif [ "$1" = "-path" -o "$1" = "--path"  -o "$1" = "-a" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe o PATH (pasta do arquivo) apos o parametro"; exit; fi
			UPATH="$2"; shift 2; continue
		# ADICIONAR VARIAVEL GET
		elif [ "$1" = "-var" -o "$1" = "--var"  -o "$1" = "-v" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe a VARIAVEL (var=value) apos o parametro"; exit; fi
			VARS="$VARS $2"; shift 2; continue
		# READ-TIMEOUT
		elif [ "$1" = "-zumbi" -o "$1" = "--zumbi" -o "$1" = "-z" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe o READTIMEOUT apos o parametro"; exit; fi
			READTIMEOUT="$2"; shift 2; continue
		# TIMEOUT
		elif [ "$1" = "-timeout" -o "$1" = "--timeout" -o "$1" = "-t" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe o TIMEOUT apos o parametro"; exit; fi
			TIMEOUT="$2"; shift 2; continue
		# TRIES
		elif [ "$1" = "-tries" -o "$1" = "--tries" -o "$1" = "-n" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe o TRIES apos o parametro"; exit; fi
			TRIES="$2"; shift 2; continue
		# RETRIES
		elif [ "$1" = "-retries" -o "$1" = "--retries" -o "$1" = "-r" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe o RETRIES apos o parametro"; exit; fi
			RETRIES="$2"; shift 2; continue
		# DUAL-STACK
		elif [ "$1" = "-dual-stack" -o "$1" = "--dual-stack" -o "$1" = "-d" ]; then
			DUALSTACK=1
			shift 1; continue
		# LABEL
		elif [ "$1" = "-label" -o "$1" = "--label" -o "$1" = "-l" ]; then
			if [ "x$2" = "x" ]; then _usage "Informe o LABEL apos o parametro"; exit; fi
			LABEL="$2"; shift 2; continue
		# DEBUG
		elif [ "$1" = "--debug" -o "$1" = "-D" ]; then
			DEBUG=1
			shift 1; continue
		else
			break
		fi
	done
	# Sem argumentos restantes
	n=$(echo -n "$@")
	if [ "x$n" = "x" ]; then _usage "Faltou informar mais parametros"; fi

	# Argumentos restantes, podem ser informados sem parametros
	# A URL seguida do ARQUIVO
	for arg in $@; do
		if [ "x$URL" =  "x" ]; then URL="$arg"; continue; fi
		if [ "x$LOCALFILE" =  "x" ]; then LOCALFILE="$arg"; continue; fi
	done

#
# Criticar variaveis
#----------------------------------------------------------------------------

	# detectar protocolo
	in_str https "$URL"; if [ "$?" = "0" ]; then PROTO=https; else PROTO=http; fi
	# porta padrao
	is_numeric "$PORT" || PORT=""
	# detectar porta padrao
	if [ "x$PORT" = "x" ]; then if [ "$PROTO" = "https" ]; then PORT=443; else PORT=80; fi; fi
	# timeout
	is_numeric "$TIMEOUT" || TIMEOUT=5
	# readtimeout
	is_numeric "$READTIMEOUT" || READTIMEOUT=3
	# tries
	is_numeric "$TRIES" || TRIES=3
	# retries
	is_numeric "$RETRIES" || RETRIES=300

	# URL nao informada
	if [ "x$URL" = "x" ]; then _usage "Faltou informar a URL"; _quit; fi

	# Arquivo nao informado
	if [ "x$LOCALFILE" = "x" ]; then STDNO=11; _quit; fi
	FILENAME=$(basename "$LOCALFILE")

	# Criar arquivos temporarios
	LOCALTMPFILE=$(mktemp /tmp/http-sync-localfile-XXXXXX)
	REMOTEMD5FILE=$(mktemp /tmp/http-sync-localmd5-XXXXXX)

	# Arquivo md5 do arquivo local, armazenado localmente
	LOCALEXT=$(fileextension "$LOCALFILE")
	MD5FILE=$(str_replace "$LOCALFILE" ".$LOCALEXT" ".md5")

	# Construir URL
	_build_url

#
# DEBUG
#----------------------------------------------------------------------------

	# Depurar
	if [ "$DEBUG" = "1" ]; then
		logity "[debug-1]"
		logit "    URL...............: ($URL)"
		logit "    VARS..............: ($VARS)"
		logit "    QSTRING...........: ($QSTRING)"
		logit "    PROTO.............: ($PROTO)"
		logit "    PORT..............: ($PORT)"
		logit "    UPATH.............: ($UPATH)"
		logit "    TIMEOUT...........: ($TIMEOUT)"
		logit "    READTIMEOUT.......: ($READTIMEOUT)"
		logit "    TRIES.............: ($TRIES)"
		logit "    RETRIES...........: ($RETRIES)"
		logit "    DUALSTACK.........: ($DUALSTACK)"
		logit "    LOCALFILE.........: ($LOCALFILE)"
		logit "    MD5FILE...........: ($MD5FILE)"
		logit "    MD5VALUE..........: ($MD5VALUE)"
		logit "    LOCALTMPFILE......: ($LOCALTMPFILE)"
		logit "    REMOTEMD5FILE.....: ($REMOTEMD5FILE)"
		echo
		logit "    FINALURL_FILE.....: ($FINALURL_FILE)"
		logit "    FINALURL_MD5......: ($FINALURL_MD5)"
		echo
	fi

#
# Verificar arquivo local
# Atualizar MD5 do arquivo local
#----------------------------------------------------------------------------

	logit2 "[$LABEL]" "Arquivo: $LOCALFILE"


	# Arquivo local tem que existir
	touch "$LOCALFILE"; ret="$?"
	if [ "$ret" = "0" ]; then
		if [ -s "$LOCALFILE" ]; then
			# arquivo tem conteudo, gerar md5 dele
			MD5VALUE=$(_getmd5sum "$LOCALFILE")
		else
			# arquivo vazio
			MD5VALUE=""
			NEEDUPDATE=1
		fi
	else
		# erro, sistema incapaz de escrever
		STDNO=12
		_quit
	fi

	# Caso arquivo md5 do arquivo local nao exista, atualiza-lo
	if [ "x$MD5VALUE" != "x" -a ! -s "$MD5FILE" ]; then echo "$MD5VALUE" > "$MD5FILE"; fi

	# Depurar
	if [ "$DEBUG" = "1" ]; then
		logity "[debug-2]"
		logit "    MD5FILE...........: ($MD5FILE)"
		logit "    MD5VALUE..........: ($MD5VALUE)"
		echo
	fi

#
# Obter MD5 do arquivo remoto
#----------------------------------------------------------------------------

	logit2 "[$LABEL]" "Obtendo MD5 remoto..."

	_http_get "$FINALURL_MD5" "$REMOTEMD5FILE"; ret1="$?"

	# Erro ao obter MD5 remoto
	if [ "$ret1" != "0" ]; then STDNO=21; abort "Erro $ret1 ao baixar arquivo MD5"; fi

	# Obter conteudo do arquivo - assinatura MD5 remota
	REMOTEMD5FILE_MD5=$(head -1 "$REMOTEMD5FILE")
	n=$(strlen "$REMOTEMD5FILE_MD5")
	if [ "$n" != "32" ]; then STDNO=22; abort "Conteudo obtido nao parece ser um hash MD5 de 32 digitos ($n)"; fi

	# Depurar
	if [ "$DEBUG" = "1" ]; then
		logity "[debug-3]"
		logit "    REMOTEMD5FILE......: ($REMOTEMD5FILE)"
		logit "    REMOTEMD5FILE_MD5..: ($REMOTEMD5FILE_MD5)"
		echo
	fi

	# Comparar com do MD5 local
	logit2 "[$LABEL] MD5 remoto:" "$REMOTEMD5FILE_MD5"
	if [ "x$MD5VALUE" = "x" ]; then
		logit2 "[$LABEL] MD5 local.:" "(vazio)"
	else
		logit2 "[$LABEL] MD5 local.:" "$MD5VALUE"
		# ambos os valores disponiveis, comparar
		if [ "$REMOTEMD5FILE_MD5" = "$MD5VALUE" ]; then
			# Iguais
			logit2 "[$LABEL]" "Download desnecessario, MD5 iguais"
			_quit
		else
			# diferentes
			logit2 -n "[$LABEL] Download necessario,"; echoc -c yellow " MD5 DIFERENTES"
			NEEDUPDATE=2
		fi
	fi

	# Requer update?
	# nao
	if [ "$NEEDUPDATE" = "0" ]; then
		_quit
	elif [ "$NEEDUPDATE" = "1" ]; then
		logit2 -n "[$LABEL] Download necessario,"; echoc -c yellow " local ausente"
	fi

#
# Obter arquivo remoto
#----------------------------------------------------------------------------

	# Baixar arquivo remoto

	logit2 "[$LABEL]" "Obtendo arquivo remoto ($FILENAME)"

	_http_get "$FINALURL_FILE" "$LOCALTMPFILE"; ret2="$?"

	# Erro ao obter MD5 remoto
	if [ "$ret2" != "0" ]; then STDNO=23; abort "Erro $ret1 ao baixar arquivo"; fi
	LOCALTMPFILE_SIZE=$(filesize "$LOCALTMPFILE")
	if [ "$LOCALTMPFILE_SIZE" = "0" ]; then STDNO=24; abort "Erro, arquivo baixado com tamanho zero"; fi

	logit2 "[$LABEL] Tamanho do arquivo......:" "$LOCALTMPFILE_SIZE bytes ($(_get_size_human $LOCALTMPFILE_SIZE))"

#
# Comparar MD5 baixado com o MD5 do arquivo baixado
#----------------------------------------------------------------------------

	LOCALTMPFILE_MD5=$(_getmd5sum "$LOCALTMPFILE")

	# improvavel, mas verificar se md5 calculado e' coerente
	n=$(strlen "$LOCALTMPFILE_MD5")
	if [ "$n" != "32" ]; then STDNO=99; abort "MD5 obtido do arquivo baixado nao parece ser um hash MD5 de 32 digitos ($n)"; fi

	logit2 "[$LABEL] MD5 local.:" "$LOCALTMPFILE_MD5"
	logit2 "[$LABEL] MD5 remoto:" "$REMOTEMD5FILE_MD5"

	if [ "$LOCALTMPFILE_MD5" = "$REMOTEMD5FILE_MD5" ]; then
		logit2 "[$LABEL] Download sincrono. Atualizando arquivo local:" "$LOCALFILE"

		# copiar arquivo baixado para o arquivo local
		# - usar CAT para nao afetar as propriedades do arquivo
		cat "$LOCALTMPFILE" > "$LOCALFILE"

		STDNO=1
		_quit

	else
		logit2 "[$LABEL] Download corrompido." "Assinaturas nao conferem"
		logit2 -n "[$LABEL]"; echoc -c red -l "Verifique sua rede e tente novamente."

		STDNO=25
		_quit

	fi















