#!/bin/sh

c_code="$1"
c_args="$@"

HERE=$(pwd)
CMP=/tmp/xexec-source-$RANDOM.c

_abort(){
    echoc -c yellow "Falhou ao executar: $c_code [$c_args] $@"
    exit 1
}

# cache de compilacao
fname=$(basename $c_code)
cachemd5file="/tmp/cexec_md5_$fname"
cachebin="/tmp/cexec_bin_$fname"
codemd5=$(getmd5sum $c_code)
compile=1
if [ -f "$cachemd5file" -a -f "$cachebin" ]; then
	cachedmd5=$(head -1 $cachemd5file)
	if [ "$codemd5" = "$cachedmd5" ]; then
		#logit "Em cache ($cachebin)"
		compile=0
	fi
fi
if [ "$compile" = "1" ]; then
	rm -f "$cachebin" 2>/dev/null
	cat $c_code | egrep -v '/bin/cexec' > $CMP
	gcc $CMP -o $cachebin || _abort "Erro $? em: gcc $CMP -o $cachebin"
	echo "$codemd5" > $cachemd5file
fi

# executar
$cachebin $c_args

