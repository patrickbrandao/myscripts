#!/bin/sh

#
# Sincronizar diretorio remoto com diretorio local baseado em indice MD5
#	Autor: Patrick Brandao, patrickbrandao@gmail.com, www.patrickbrandao.com
#	GIT: https://github.com/patrickbrandao/eveunl
#
	# Cores
	ANSI_RESET='\033[0m'
	# Light
	ANSI_LIGHT_RED='\x1B[91m'          # Red
	ANSI_LIGHT_GREEN='\x1B[92m'        # Green
	ANSI_LIGHT_YELLOW='\x1B[93m'       # Yellow
	ANSI_LIGHT_BLUE='\x1B[94m'         # Blue
	ANSI_LIGHT_PINK='\x1B[95m'         # Purple
	ANSI_LIGHT_CYAN='\x1B[96m'               # Cyan
	ANSI_LIGHT_WHITE='\x1B[97m'              # White

# Funcoes
	_echo_lighred(){ /bin/echo -e "${ANSI_LIGHT_RED}$@$ANSI_RESET"; }
	_echo_lighgreen(){ /bin/echo -e "${ANSI_LIGHT_GREEN}$@$ANSI_RESET"; }
	_echo_lighyellow(){ /bin/echo -e "${ANSI_LIGHT_YELLOW}$@$ANSI_RESET"; }
	_echo_lighblue(){ /bin/echo -e "${ANSI_LIGHT_BLUE}$@$ANSI_RESET"; }
	_echo_lighpink(){ /bin/echo -e "${ANSI_LIGHT_PINK}$@$ANSI_RESET"; }
	_echo_lighcyan(){ /bin/echo -e "${ANSI_LIGHT_CYAN}$@$ANSI_RESET"; }
	_echo_lighwhite(){ /bin/echo -e "${ANSI_LIGHT_WHITE}$@$ANSI_RESET"; }
    _abort(){ echo; _echo_lighred "** ABORTADO: $1"; echo; exit $2; }

	# obter arquivo via HTTP
	# - obter md5 de um arquivo
	_getmd5(){ md5sum "$1" | awk '{print $1}'; }
	# - obter md5 de um arquivo e comprar com md5 de referencia, retornar comparacao no stdno
	_testmd5(){ _m=$(_getmd5 "$1"); [ "x$_m" = "x$2" ] && return 0; return 1; }
	# - obter arquivo via HTTP
	_http_get(){
		_hg_url="$1"; _hg_file="$2"; _hg_md5="$3"; _hg_opt=""; _hg_debug=""
		_hg_eu=$(echo "$_hg_url" | cut -f1 -d'?')
		_echo_lighgreen "> HTTP-GET: Baixando: [$_hg_eu] -> [$_hg_file]"
		_hg_opt="-4 --retry-connrefused --no-cache --progress=bar:force:noscroll --no-check-certificate --timeout=5 --read-timeout=5 --tries=30 --wait=1 --waitretry=1 -O $_hg_file"
		wget $_hg_opt "$_hg_url?nocache=$RANDOM"; _hg_ret="$?"
		if [ "$_hg_ret" = "0" -a "x$_hg_md5" != "x" ]; then _testmd5 "$_hg_file" "$_hg_md5"; _hg_ret="$?"; fi
		return $_hg_ret
	}
	# - sincronizar arquivos via HTTP
	_http_sync(){
		# Parametros
		hs_localdir="$1"
		hs_baseurl="$2"
		hs_indexname="$3"
		hs_filter="$4"; [ "x$hs_filter" = "x" ] && hs_filter="."
		# Variaveis locais
		hs_indexurl="$hs_baseurl/$hs_indexname"
		hs_tmpindex="/tmp/httpsync-$hs_indexname"; rm -f "$hs_tmpindex" 2>/dev/null

		# Criar e acessar diretorio
		mkdir -p "$hs_localdir" 2>/dev/null
		cd "$hs_localdir" || {
			_echo_lighyellow "> HTTP-SYNC :: Erro ao acessar diretorio [$hs_localdir]"
			return 7
		}
		_echo_lighgreen "> HTTP-SYNC :: Diretorio....: [$hs_localdir]"
		_echo_lighgreen "> HTTP-SYNC :: Base URL.....: [$hs_baseurl]"
		_echo_lighgreen "> HTTP-SYNC :: Indice.......: [$hs_indexname]"

		# OBTER INDICE
		_http_get "$hs_indexurl" "$hs_tmpindex" 2>/dev/null || { _echo_lighgreen "> HTTP-SYNC :: Erro $? ao obter indice."; rm -f "$hs_tmpindex" 2>/dev/null; return 11; }

		# PROCESSAR INDICE aplicando filtro
		hs_filteredindex="/tmp/httpsync-filtered-$hs_indexname"; rm -f "$hs_filteredindex" 2>/dev/null
		cat "$hs_tmpindex" | egrep "$hs_filter" > $hs_filteredindex
		hs_idxcount=$(cat "$hs_filteredindex" | wc -l)
		if [ "$hs_idxcount" = "0" ]; then
			_echo_lighgreen "> HTTP-SYNC :: Nenhum arquivo na lista [filtro: $hs_filter]"
			return 0
		fi
		# Obter lista de MD5
		hs_list=$(cat "$hs_filteredindex" | awk '{print $1}')
		hs_count=0
		for hs_md5 in $hs_list; do
			
			hs_file=$(egrep "^$hs_md5" $hs_filteredindex | awk '{print $2}' | head -1)
			#_echo_lighcyan "  - HTTP-SYNC :: Processando $hs_md5 - $hs_file"

			# Sincronizar
			hs_tmp="/tmp/httpsync-$hs_file"
			hs_url="$hs_baseurl/$hs_file"
			hs_dstfile="$hs_localdir/$hs_file"

			# Arquivo ja existe, conferir assinatura
			[ -f "$hs_dstfile" ] && _testmd5 "$hs_dstfile" "$hs_md5" && {
				_echo_lighgreen "  - HTTP-SYNC [$hs_file]: Sincronizado (nao duplicado)"
				continue
			}

			# Procurar assinatura em algum arquivo existente e evitar baixar arquivo duplicado
			_echo_lighcyan "  - HTTP-SYNC :: Procurando arquivo duplicado [$hs_file";
			hs_filefound=x
			for hs_efile in *; do
				[ -f "$hs_efile" ] || continue
				hs_tmpmd5=$(_getmd5 "$hs_efile")
				[ "$hs_md5" = "$hs_tmpmd5" ] && hs_filefound="$hs_efile" && break
			done
			[ "$hs_filefound" = "x" ] || {
				_echo_lighcyan "  - HTTP-SYNC: [$hs_file]: Imagem OK [em $hs_filefound, $hs_md5]"
				continue
			}
			# Remover temporario e destino
			rm -f "$hs_tmp" 2>/dev/null; rm -f "$hs_dstfile" 2>/dev/null

			# Baixar
			_echo_lighcyan "  - HTTP-SYNC [$hs_file]: Obtendo via URL $hs_url"

			_http_get "$hs_url" "$hs_tmp"; hs_ret="$?"
			[ "$hs_ret" = "0" ] || {
				_echo_lighyellow "  - HTTP-SYNC [$hs_file]: Erro $hs_ret ao baixar [$hs_url] para [$hs_tmp]"
				continue;
			}

			# Verificar assinatura MD5
			hs_local_md5=$(_getmd5 "$hs_tmp")
			[ "$hs_local_md5" = "x" ] && {
				_echo_lighyellow "  - HTTP-SYNC [$hs_file]: Erro ao obter assinatura MD5 de [$hs_tmp]"
				continue
			}
			[ "$hs_md5" = "$hs_local_md5" ] || {
				_echo_lighyellow "  - HTTP-SYNC [$hs_file]: Download corrompido [$hs_md5] =/= [$hs_local_md5]"
				continue
			}

			# Tudo certo, instalar
			mv "$hs_tmp" "$hs_dstfile" || {
				_echo_lighyellow "  - HTTP-SYNC [$hs_file]: Erro ao mover [$hs_tmp] > [$hs_dstfile]"
				continue
			}
			_echo_lighgreen "  - HTTP-SYNC [$hs_file]: Sincronizado."
		done
		echo
	}

	_help(){
		echo
		_echo_lighwhite "http-rsync -d (diretorio-local) -u (url-base) -i (index-name) [-h]"
		echo
		_echo_lighwhite "  diretorio-local  - Diretorio local onde os arquivos serao baixados"
		_echo_lighwhite "  url-base         - URL base dos arquivos e do indice"
		_echo_lighwhite "  index-name       - Nome do arquivo indice contendo MD5 e nome dos arquivos"
		_echo_lighwhite "  -h               - Ajuda"
		echo
		exit 1
	}

# Processar parametros
	LOCDIR=""
	BASEURL=""
	INDEXNAME=""
	while [ 0 ]; do
		[ "x$1" = "x" ] && break
		[ "$1" = "-h" -o "$1" = "help" -o "$1" = "-help" -o "$1" = "--help" ] && _help
		# diretorio-local
		[ "$1" = "-d" ] && LOCDIR="$2" && shift 2 && continue
		[ "$1" = "-u" ] && BASEURL="$2" && shift 2 && continue
		[ "$1" = "-i" ] && BASEURL="$2" && shift 2 && continue
		# auto-completar
		[ "x$LOCDIR" = "x" ] && LOCDIR="$1" && shift && continue
		[ "x$BASEURL" = "x" ] && BASEURL="$1" && shift && continue
		[ "x$INDEXNAME" = "x" ] && INDEXNAME="$1" && shift && continue
	done

	[ "x$LOCDIR" = "x" ] && _abort "Diretorio local nao informado"
	[ "x$BASEURL" = "x" ] && _abort "Base da URL nao informada"
	[ "x$INDEXNAME" = "x" ] && _abort "Nome do arquivo indice nao informado"


	# Efetivar
	_http_sync "$LOCDIR" "$BASEURL" "$INDEXNAME" || _abort "Falhou, erro $? ao executar sincronismo diretorio[$LOCDIR] url-base[$BASEURL] indice[$INDEXNAME]"







