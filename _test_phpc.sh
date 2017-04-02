#!/bin/sh

# Limpar e finalizar
_cleartest(){ rm /tmp/phptest-* 2>/dev/null; }
_abort(){ logitr "$1"; exit $2; }

# limpar testes anteriores
	_cleartest

# Variaveis
	phpcl=/compiler/projects/myscripts/php-implode.php
	phpob=/compiler/projects/myscripts/php-obfusc.php
	phpxcode=/compiler/projects/myscripts/php-xcode.php
	phpx=/usr/local/bin/phpx
	sampdir=/compiler/projects/myscripts/phpsamples

	secretfile=/compiler/projects/php5-xcode/secret.txt

	alias phpcl=$phpcl
	alias phpob=$phpob
	alias phpxcode=$phpxcode

# Critica de ambiente
	[ -x $phpcl ] || _abort "Falta o $phpcl" 90
	[ -x $phpob ] || _abort "Falta o $phpob" 91
	[ -x $phpx ] || _abort "Falta o $phpx" 92

# Funcoes
_test(){
	src="$1"
	clean_out="$2"
	obfusc_out="$3"
	xcode_out="$4"
	extreme_obfusc_out="$5"
	extreme_xcode_out="$6"
	extreme_xcodebin_out="$7"

	logitg "Source.......: $src"
	logitg "            Output clean....: $clean_out"
	logitg "            Output obfusc...: $obfusc_out"
	logitg "            Output XCODE....: $xcode_out"
	logitg "           EXTREME obfusc...: $extreme_obfusc_out"
	logitg "           EXTREME XCODE....: $extreme_xcode_out"
	logitg "           EXTREME XCODE BIN: $extreme_xcodebin_out"

	# limpar
	#logitr "phpcl -x -c -f $src -w $clean_out"
	phpcl -x -c -f $src -w $clean_out || _abort "Erro $? ao implodir/limpar [$src] para [$clean_out]" 8

	# obfuscar
	phpob -q -x -c -f $clean_out -w $obfusc_out || _abort "Erro $? ao obfuscar [$clean_out] para [$obfusc_out]" 9

	# codificar em xcode
	phpxcode -q -x $secretfile -f $obfusc_out -w $xcode_out || _abort "Erro $? ao codificar [$obfusc_out] para [$xcode_out]" 10

	# gerar MD5 da saida normal
	md5source=$($phpx $src 2>/tmp/srcerr | md5sum | awk '{print $1}')
	srcerr=$(cat /tmp/srcerr)
	[ "x$srcerr" = "x" ] || { logity "Erro ao executar $src"; cat /tmp/srcerr; exit 7; }

	# gerar MD5 do codigo limpo/implodido
	md5clean=$($phpx $clean_out 2>/tmp/clserr | md5sum | awk '{print $1}')
	clserr=$(cat /tmp/clserr)
	[ "x$clserr" = "x" ] || { logity "Erro ao executar $clean_out"; cat /tmp/clserr; exit 8; }

	# gerar MD5 do codigo obfuscado
	md5obfusc=$($phpx $obfusc_out 2>/tmp/obferr | md5sum | awk '{print $1}')
	obferr=$(cat /tmp/obferr)
	[ "x$obferr" = "x" ] || { logity "Erro ao executar $obfusc_out"; cat /tmp/obferr; exit 8; }

	# gerar MD5 do codigo criptografado
	md5xcode=$($phpx $xcode_out 2>/tmp/xcoderr | md5sum | awk '{print $1}')
	xcoderr=$(cat /tmp/xcoderr)
	[ "x$xcoderr" = "x" ] || { logity "Erro ao executar $xcode_out"; cat /tmp/xcoderr; exit 8; }

	# Teste extremos: obfuscar com caracteres extendidos e criptografar
	# obfuscar extremo
	phpob -E -q -x -c -f $clean_out -w $extreme_obfusc_out || _abort "Erro $? ao obfuscar [$clean_out] para [$extreme_obfusc_out]" 21
	md5EXTREMEobfusc=$($phpx $extreme_obfusc_out 2>/tmp/obfEXTREMEerr | md5sum | awk '{print $1}')
	obfEXTREMEerr=$(cat /tmp/obfEXTREMEerr)
	[ "x$obfEXTREMEerr" = "x" ] || { logity "Erro ao executar $extreme_obfusc_out"; cat /tmp/obfEXTREMEerr; exit 28; }

	# criptografar extremo
	phpxcode -q -x $secretfile -f $extreme_obfusc_out -w $extreme_xcode_out || _abort "Erro $? ao codificar [$extreme_obfusc_out] para [$extreme_xcode_out]" 29
	md5EXTREMExcode=$($phpx $extreme_xcode_out 2>/tmp/xcodeEXTREMEerr | md5sum | awk '{print $1}')
	xcodeEXTREMEerr=$(cat /tmp/xcodeEXTREMEerr)
	[ "x$xcodeEXTREMEerr" = "x" ] || { logity "Erro ao executar $extreme_xcode_out"; cat /tmp/xcodeEXTREMEerr; exit 8; }

	# criptografar extremo com fonte em binario
	phpxcode -q -1 -x $secretfile -f $extreme_obfusc_out -w $extreme_xcodebin_out || _abort "Erro $? ao codificar [$extreme_obfusc_out] para [$extreme_xcodebin_out]" 29
	md5EXTREMEBINxcode=$($phpx $extreme_xcodebin_out 2>/tmp/xcodeEXTREMEBINerr | md5sum | awk '{print $1}')
	xcodeEXTREMEBINerr=$(cat /tmp/xcodeEXTREMEBINerr)
	[ "x$xcodeEXTREMEBINerr" = "x" ] || { logity "Erro ao executar $extreme_xcodebin_out"; cat /tmp/xcodeEXTREMEBINerr; exit 8; }

	logita    " MD5 SRC.......: $md5source  "

	logita -n " MD5 CLEAN.....: $md5clean   "

	# Teste do codigo original para limpo
	if [ "$md5source" = "$md5clean" ]; then echo_success; else echo_failure; exit 80; fi

	logita -n " MD5 OBFUSC....: $md5obfusc  "
	if [ "$md5source" = "$md5obfusc" ]; then echo_success; else echo_failure; exit 81; fi

	logita -n " MD5 XCODE.....: $md5xcode  "
	if [ "$md5source" = "$md5xcode" ]; then echo_success; else echo_failure; exit 82; fi

	logita -n " MD5 X-OBFUSC..: $md5EXTREMEobfusc  "
	if [ "$md5source" = "$md5EXTREMEobfusc" ]; then echo_success; else echo_failure; exit 81; fi

	logita -n " X-XCODE.......: $md5EXTREMExcode  "
	if [ "$md5source" = "$md5EXTREMExcode" ]; then echo_success; else echo_failure; exit 82; fi

	logita -n " EXT X-XCODE-B.: $md5EXTREMEBINxcode  "
	if [ "$md5source" = "$md5EXTREMEBINxcode" ]; then echo_success; else echo_failure; exit 82; fi

	echo
}


# Teste direto
if [ "x$1" != "x" ]; then
	xfile="$1"
	ifile=$(readlink -f $xfile)
	if [ -f "$ifile" ]; then
		phpfile=$(basename $ifile)

		xsrc=$ifile
		xclean_out=/tmp/phptest-clean-$phpfile
		xobfusc_out=/tmp/phptest-obfusc-$phpfile
		xcode_out=/tmp/phptest-xcode-$phpfile
		xobfusc_extreme_out=/tmp/phptest-extreme-obfusc-$phpfile
		xcode_extreme_out=/tmp/phptest-extreme-xcode-$phpfile
		xcode_extremebin_out=/tmp/phptest-extremebin-xcode-$phpfile

		_test "$xsrc" \
			"$xclean_out" "$xobfusc_out" "$xcode_out" \
			"$xobfusc_extreme_out" "$xcode_extreme_out" \
			"$xcode_extremebin_out"
		exit
	else
		_abort "Arquivo especificado nao existe: $ifile ($xfile)"
	fi
fi

# Teste de exemplos
	cd $sampdir || _abort "Incapaz de entrar no diretorio $sampdir" 93

	for phpfile in 0*.php; do
		xsrc=$sampdir/$phpfile
		xclean_out=/tmp/phptest-clean-$phpfile
		xobfusc_out=/tmp/phptest-obfusc-$phpfile
		xcode_out=/tmp/phptest-phptest-xcode-$phpfile
		xobfusc_extreme_out=/tmp/phptest-extreme-obfusc-$phpfile
		xcode_extreme_out=/tmp/phptest-extreme-xcode-$phpfile
		xcode_extremebin_out=/tmp/phptest-extremebin-xcode-$phpfile

		_test "$xsrc" \
			"$xclean_out" "$xobfusc_out" "$xcode_out" \
			"$xobfusc_extreme_out" "$xcode_extreme_out" \
			"$xcode_extremebin_out"
	done
	rm $sampdir/*.phps 2>/dev/null












