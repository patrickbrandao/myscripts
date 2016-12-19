#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Exemplo: ./sh-to-base64run.sh /var/lab/sample.sh /tmp/onboard-script.sh /var/lab/unpack-sample.sh

# Parametros
#
	# Arquivo de entrada
	SOURCE_FILE=""

	# Arquivo de saida
	OUTPUT_SCRIPT=""

	# Tipo de codificacao
	# - shell: ser acriado um script temporario e executado
	# - file: o script servira para criar um arquivo decodificado
	TARGET_TYPE="shell"

	# Caminho do destino do arquivo codificado apos decodifica-lo com sucesso
	TARGET_DESTIONATION=""

	# Compilar script com shc ?
	SHCCOMPILE=1

	# - parametros do shc
	SHCPARAM="-r"

	# - diretorio root do sh-implode
	SHI_IMPLODE=1
	SHI_ROOT="/"

	# Destino do arquivo decodificado
	DECODED_FILE=""

	# Comandos imbutidos
	CMD_POSTDECOD=""
	CMD_ENDSCRIPT=""

	# Mensagem de copyright
	COPYRIGHTMSG=""


#------------------------------------------------- Funcoes
# Ajuda
	_help(){
		echo "Use: sh-to-base64run (opcoes)"
		echo
		echo "Parametros:"
		echo "  -f (ARQUIVO)           Arquivo original (script ou arquivo)"
		echo "  -o (SCRIPT)            Script resultante (contendo decodificador)"
		echo "  -D (FILE)              Localizacao para salvar arquivo decodificado"
		echo "  -p (OPT)               Opcoes do SHC"
		echo "  -I                     Nao acionar sh-implode"
		echo "  -R                     sh-implode ROOT"
		echo "  -N                     Nao usar SHC"
		echo "  -O (PATH)              Caminho para salvar arquivo apos decodifica-lo"
		echo "  -t (TIPO)              Tipo:"
		echo "                            shell (padrao): executar como script"
		echo "                            file : salvar arquivo codificado"
		echo "  -x (CMD)               Comando a executar apos criar arquivo decodificado (antes de executar)"
		echo "  -X (CMD)               Comando final apos concluir tarefas (antes de encerrar)"
		echo "  -C (MSG)               Mensagem de copyright"
		echo
	}

	# Funcoes genericas
	_get_md5(){ md5sum $1 | awk '{print $1}'; }

	# Funcoes coloridas
	ANSI_RESET="\033[0m"
	ANSI_LIGHT_RED='\x1B[91m'
	ANSI_LIGHT_GREEN='\x1B[92m'
	ANSI_LIGHT_YELLOW='\x1B[93m'
	_echo_lighred_n(){ echo -ne "${ANSI_LIGHT_RED}$@$ANSI_RESET"; }
	_echo_lighgreen_n(){ echo -ne "${ANSI_LIGHT_GREEN}$@$ANSI_RESET"; }
	_echo_lighyellow_n(){ echo -ne "${ANSI_LIGHT_YELLOW}$@$ANSI_RESET"; }
	_echo_lighred(){ echo -e "${ANSI_LIGHT_RED}$@$ANSI_RESET"; }
	_echo_lighgreen(){ echo -e "${ANSI_LIGHT_GREEN}$@$ANSI_RESET"; }
	_echo_lighyellow(){ echo -e "${ANSI_LIGHT_YELLOW}$@$ANSI_RESET"; }

	# criar e registrar arquivos temporarios
	gtmplist=""
	tmpfile=""
	_new_tmp(){ tmpfile="/tmp/tmp-file-$RANDOM-$RANDOM"; gtmplist="$gtmplist $tmpfile"; }
	_cls_tmp(){ [ "x$gtmplist" = "x" ] && return; for xtmp in $gtmplist; do rm -f "$xtmp" 2>/dev/null; done; }

	# finalizar programa (e limpar ambiente)
	_end(){ errno="$1"; [ "x$errno" = "x" ] && errno=99; _cls_tmp; exit $errno; }

	# Erro fatal
	_abort(){ echo; _echo_lighred_n "Abortado: "; _echo_lighyellow "$1"; echo; _end $2; }

#------------------------------------------------- Parametros

# Nenhum parametro
	[ "x$1" = "x" ] && _help

# Processar argumentos
	while true; do
		[ "x$1" = "x" ] && break

		# Ajuda
		[ "$1" = "-h" -o "$1" = "-help" -o "$1" = "--help" ] && _help

		# Arquivo fonte
		[ "$1" = "-f" ] && SOURCE_FILE="$2" && shift 2 && continue
		# Arquivo script resultante
		[ "$1" = "-o" ] && OUTPUT_SCRIPT="$2" && shift 2 && continue
		# Local de destino do arquivo decodificado
		[ "$1" = "-D" ] && TARGET_DESTIONATION="$2" && shift 2 && continue

		# Parametro do SHC
		[ "$1" = "-p" ] && SHCPARAM="$2" && shift 2 && continue
		[ "$1" = "-N" ] && SHCCOMPILE=0 && shift 1 && continue

		# Comandos imbutidos
		[ "$1" = "-x" ] && CMD_POSTDECOD="$2" && shift 2 && continue
		[ "$1" = "-X" ] && CMD_ENDSCRIPT="$2" && shift 2 && continue

		# Direitos sobre o codigo
		[ "$1" = "-X" ] && COPYRIGHTMSG="$2" && shift 1 && continue

		# Direitos root do sh-implode
		[ "$1" = "-I" ] && SHI_IMPLODE="0" && shift 1 && continue
		[ "$1" = "-R" ] && SHI_ROOT="$2" && shift 2 && continue


		# Tipo
		if [ "$1" = "-t" ]; then
			[ "$2" = "shell" -o "$2" = "sh" ] && TARGET_TYPE="shell"
			[ "$2" = "file" -o "$2" = "archive" ] && TARGET_TYPE="file"
			shift 2
			continue
		fi

		# Autodetectar
		[ "$1" = "shell" ] && TARGET_TYPE="shell" && shift && continue
		[ "$1" = "file" ] && TARGET_TYPE="file" && shift && continue

		[ "x$SOURCE_FILE" = "x" -a -f "$1" ] && SOURCE_FILE="$1" && shift && continue
		[ "x$OUTPUT_SCRIPT" = "x" -a "x$SOURCE_FILE" != "x" ] && OUTPUT_SCRIPT="$1" && shift && continue
		[ "x$OUTPUT_SCRIPT" != "x" -a "x$SOURCE_FILE" != "x" ] && TARGET_DESTIONATION="$1" && shift && continue

		_abort "Parametro desconhecido: [$1]"
	done



#------------------------------------------------- Programa

# Criticar
	[ "x$SOURCE_FILE" = "x" ] && _abort "Informe o arquivo de entrada."
	[ -f "$SOURCE_FILE" ] || _abort "Arquivo de entrada nao existe [$SOURCE_FILE]."
	if [ "x$OUTPUT_SCRIPT" != "x" ]; then
		# tentar criar arquivo
		touch "$OUTPUT_SCRIPT" || _abort "Erro ao criar arquivo de saida [$OUTPUT_SCRIPT]"
	fi

	# Implodir shell-script
	TMP_SOURCE_FILE="$SOURCE_FILE"

	# se for shell-script, precisamos implodi-lo
	if [ "$TARGET_TYPE" = "shell" -a "$SHI_IMPLODE" = "1" ]; then
		_new_tmp; TMP_SOURCE_FILE="$tmpfile"
		sh-implode -f "$SOURCE_FILE" -w "$TMP_SOURCE_FILE" -r "$SHI_ROOT" || _abort "Erro $? ao executar sh-implode"
		#- echo
		#- cat $TMP_SOURCE_FILE
		#- echo
		#- exit
	fi

	# se for shell-script, precisamos compila-lo em C
	if [ "$TARGET_TYPE" = "shell" -a "$SHCCOMPILE" = "1" ]; then
		_new_tmp; shcoutput="$tmpfile"
		shc_cmd="shc $SHCPARAM -f '$TMP_SOURCE_FILE' -o '$shcoutput'"
		eval "$shc_cmd" || _abort "Erro $? ao executar shc [$shc_cmd]"
		TMP_SOURCE_FILE="$shcoutput"
	fi


	# md5 do arquivo a ser codificado em base64
	SOURCE_FILE_MD5=$(_get_md5 "$TMP_SOURCE_FILE")

	_debug(){
		echo
		_echo_lighgreen_n "SOURCE_FILE.............: "; _echo_lighyellow "$SOURCE_FILE"
		_echo_lighgreen_n "TMP_SOURCE_FILE.........: "; _echo_lighyellow "$TMP_SOURCE_FILE"
		_echo_lighgreen_n "SOURCE_FILE_MD5.........: "; _echo_lighyellow "$SOURCE_FILE_MD5"	
		_echo_lighgreen_n "OUTPUT_SCRIPT...........: "; _echo_lighyellow "$OUTPUT_SCRIPT"
		_echo_lighgreen_n "TARGET_DESTIONATION.....: "; _echo_lighyellow "$([ "x$TARGET_DESTIONATION" = "x" ] && echo '(temporary-file)' || echo $TARGET_DESTIONATION )"
		_echo_lighgreen_n "TARGET_TYPE.............: "; _echo_lighyellow "$TARGET_TYPE"
		_echo_lighgreen_n "SHCCOMPILE..............: "; _echo_lighyellow "$SHCCOMPILE"
		_echo_lighgreen_n "SHCPARAM................: "; _echo_lighyellow "$SHCPARAM"
		_echo_lighgreen_n "SHI_IMPLODE.............: "; _echo_lighyellow "$SHI_IMPLODE"
		_echo_lighgreen_n "SHI_ROOT................: "; _echo_lighyellow "$SHI_ROOT"
		#_echo_lighgreen_n "DECODED_FILE............: "; _echo_lighyellow "$DECODED_FILE"
		_echo_lighgreen_n "CMD_POSTDECOD...........: "; _echo_lighyellow "$CMD_POSTDECOD"
		_echo_lighgreen_n "CMD_ENDSCRIPT...........: "; _echo_lighyellow "$CMD_ENDSCRIPT"
		_echo_lighgreen_n "COPYRIGHTMSG............: "; _echo_lighyellow "$COPYRIGHTMSG"
		echo
	}

# 1 - codificar arquivo fonte
	# Gerar base64
	_new_tmp; tmp64="$tmpfile"
	base64 "$TMP_SOURCE_FILE" > $tmp64; sn="$?"
	[ "$sn" = "0" ] || _abort "Erro $sn ao gerar base64"
	# Gerar assinatura base64 (evitar corrupcao do base64 durante download)
	tmp64md5=$(_get_md5 "$tmp64")
	_echo_lighgreen_n "tmp64...................: "; _echo_lighyellow "$tmp64"
	_echo_lighgreen_n "tmp64md5................: "; _echo_lighyellow "$tmp64md5"


# 2 - prototipar script final
	_new_tmp; tmpscript="$tmpfile"

	(
		#NOCR="-n"
		echo '#!/bin/sh'
		echo '# AUTHOR'
		echo 'export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"'
		[ "x$COPYRIGHTMSG" = "x" ] || echo "# $COPYRIGHTMSG"
		echo $NOCR "TARGETmd5='$SOURCE_FILE_MD5';"
		echo $NOCR "BASE64md5='$tmp64md5';"
		echo $NOCR "TARGETfile='$TARGET_DESTIONATION';"
		echo $NOCR 'gtmplist=""; tmpfile="";'
		echo $NOCR 'ANSI_RESET="\033[0m"; ANSI_LIGHT_RED="\x1B[91m"; ANSI_LIGHT_GREEN="\x1B[92m"; ANSI_LIGHT_YELLOW="\x1B[93m";'

		# Apelidos
		echo $NOCR '_obecho=echo;_obeval=eval;_obwhich=which;'
		echo $NOCR '_obbase64=base64;_obnullfile=/dev/null;_obmd5sum=md5sum;_obremove=rm;'
		echo $NOCR '_obcatfile=cat;_obchmod=chmod;_obabort=_abort;'

		# Strings
		echo $NOCR 'gmsg001="Programa [base64] nao encontrado. Instale-o.";'
		echo $NOCR 'gmsg002="Abortado: ";'
		echo $NOCR 'gmsg003="Erro ao decodificar arquivo base64.";'
		echo $NOCR 'gmsg004="BASE64 interno corrompido. original[";'
		echo $NOCR 'gmsg005="] atual[";'
		echo $NOCR 'gmsg006="Erro ao ativar flag de execucao no script.";'

		# Funcoes
		echo $NOCR "_get_md5(){ \$_obmd5sum \$1 | awk '{print \$1}'; };"
		echo $NOCR '_echo_lighred_n(){ $_obecho -ne "${ANSI_LIGHT_RED}$@$ANSI_RESET"; };'
		echo $NOCR '_echo_lighgreen_n(){ $_obecho -ne "${ANSI_LIGHT_GREEN}$@$ANSI_RESET"; };'
		echo $NOCR '_echo_lighyellow_n(){ $_obecho -ne "${ANSI_LIGHT_YELLOW}$@$ANSI_RESET"; };'
		echo $NOCR '_echo_lighred(){ $_obecho -e "${ANSI_LIGHT_RED}$@$ANSI_RESET"; };'
		echo $NOCR '_echo_lighgreen(){ $_obecho -e "${ANSI_LIGHT_GREEN}$@$ANSI_RESET"; };'
		echo $NOCR '_echo_lighyellow(){ $_obecho -e "${ANSI_LIGHT_YELLOW}$@$ANSI_RESET"; };'
		echo $NOCR '_new_tmp(){ tmpfile="/tmp/tmp-file-$RANDOM-$RANDOM"; gtmplist="$gtmplist $tmpfile"; };'
		echo $NOCR '_cls_tmp(){ [ "x$gtmplist" = "x" ] && return; for xinlocotmp in $gtmplist; do $_obremove -f "$xinlocotmp" 2>$_obnullfile; done; };'
		echo $NOCR '_end_program(){ _cls_tmp; exit $1; };'
		echo $NOCR '_abort(){ $_obecho; _echo_lighred_n "$gmsg002"; _echo_lighyellow "$1"; $_obecho; _end_program $2; };'
		echo $NOCR '$_obwhich $_obbase64 > $_obnullfile || $_obabort "$gmsg001";'
		echo $NOCR '_new_tmp; tmpbase64file="$tmpfile";'
		echo $NOCR "if [ \"x\$TARGETfile\" = \"x\" ]; then _new_tmp; TARGETfile="\$tmpfile"; fi;"

		echo '$_obcatfile > $tmpbase64file << EOF'
		cat $tmp64
		echo 'EOF'

		# Validar base64 extraido
		echo $NOCR 'tmpbase64md5=$(_get_md5 "$tmpbase64file");'
		echo $NOCR '[ "$BASE64md5" = "$tmpbase64md5" ] || $_obabort "$gmsg004$BASE64md5$gmsg005$tmpbase64md5]";'

		# Decodificar de base64 para formato original
		echo $NOCR '$_obbase64 -d $tmpbase64file > $TARGETfile;'
		echo $NOCR 'xstdno="$?";'
		echo $NOCR '[ "$xstdno" = "0" ] || $_obabort "$gmsg003";'

		# Colocar flag de execucao no script
		[ "$TARGET_TYPE" = "shell" ] && \
		echo $NOCR '$_obchmod a+x $TARGETfile || $_obabort "$gmsg006";'

		# Comando pos descompactacao
		if [ "x$CMD_POSTDECOD" != "x" ]; then
			b64cmd=$(echo "$CMD_POSTDECOD" | base64)
			echo $NOCR "cmd_postdecod=\$(\$_obecho '$b64cmd' | \$_obbase64 -d);"
			echo $NOCR '$_obeval "($cmd_postdecod)";'
		fi

		# Executar script
		[ "$TARGET_TYPE" = "shell" ] && echo $NOCR '($TARGETfile);'

		# Remover temporarios aqui
		echo $NOCR '_cls_tmp;'

		# Executar comando final
		if [ "x$CMD_ENDSCRIPT" != "x" ]; then
			b64cmd=$(echo "$CMD_ENDSCRIPT" | base64)
			echo $NOCR "cmd_finaldecod=\$(echo '$b64cmd' | base64 -d);"
			echo $NOCR '$_obeval "($cmd_finaldecod)";'
		fi

		# Remover novamente por garantia
		echo '_end_program'

	) > $tmpscript


# 3 - obfuscar codigo
	KEYWORDS="
		_echo_lighyellow_n
		_echo_lighgreen_n
		_echo_lighred_n
		ANSI_LIGHT_YELLOW
		ANSI_LIGHT_GREEN
		ANSI_LIGHT_RED
		ANSI_RESET
		_echo_lighyellow
		_echo_lighgreen
		_echo_lighred
		_obnullfile
		_obmd5sum
		_obcatfile
		_obremove
		_obbase64
		_obwhich
		_obchmod
		_obabort
		_obecho
		_get_md5
		_new_tmp
		_abort
		gtmplist
		tmpfile
		_cls_tmp
		_end_program
		tmpbase64file
		TARGETfile
		TARGETmd5
		BASE64md5
		tmpbase64md5
		xstdno
		_obeval
		cmd_postdecod
		cmd_finaldecod
		xinlocotmp
		gmsg001
		gmsg002
		gmsg003
		gmsg004
		gmsg005
		gmsg006
	"
	# Ordenar KEYWORDS comecando pela maior palavra para a menor
	SORTEDKEYWORKS=$(for word in $KEYWORDS; do strlen=$(echo $word | wc -c); echo "$strlen $word"; done | sort -nr | awk '{print $2}')

	# Criar plano de substituicao
	SEDREPLACE="s#AUTHOR#Desenvolvido por Patrick Brandao, todos os direitos reservados.#"
	for CNAME in $SORTEDKEYWORKS; do
		a1=$(dechex "$RANDOM"); a2=$(dechex "$RANDOM"); a3=$(dechex "$RANDOM"); a4=$(dechex "$RANDOM")
		OBNAME="ob$a1$a2$a3$a4"
		SEDREPLACE="$SEDREPLACE; s#$CNAME#$OBNAME#g"
	done

	# Substituir
	sed -i "$SEDREPLACE" $tmpscript

# 4 - tudo pronto, jogar tmpscript no script de saida
	if [ "x$OUTPUT_SCRIPT" = "x" ]; then
		cat $tmpscript
	else
		cat $tmpscript > $OUTPUT_SCRIPT
		chmod +x $OUTPUT_SCRIPT
	fi


	# DEBUG
	#_echo_lighgreen_n "tmpscript...............: "; _echo_lighyellow "$tmpscript"
	#_echo_lighgreen "-------------------------------------------------------------------------"
	#cat $tmpscript
	#_echo_lighyellow "Testando:"
	#_echo_lighgreen "-------------------------------------------------------------------------"
	#sh $tmpscript
	#_echo_lighgreen "-------------------------------------------------------------------------"
	#echo
	#echo "gtmplist: [$gtmplist]"

# Limpar arquivos temporarios e encerrar
_end







