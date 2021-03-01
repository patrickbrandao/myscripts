#!/bin/sh

#
# Criar certificado auto-assinado
#
# Variaveis globais de orientacao:
#    SSL_ARG_SUBJ    - dados para certificado auto-assinado
#                caso SSL_ARG_SUBJ esteja ausente, as seguintes variaveis serao usadas para preenche-lo
#        SSL_COUNTRY=BR
#        SSL_PROVINCE="Minas Gerais"
#        SSL_CITY="Belo Horizonte"
#        SSL_COMPANY="Intranet Corporation"
#        SSL_ORG_UNIT="Intranet IT Department"
#        SSL_COMMONNAME="*.intranet.br"
#        SSL_EMAIL=contato@intranet.br
#
#    SSL_DAYS       - numero de dias de validade, padrao 3650
#
#    SSL_KEY        - caminho para chave privada
#    SSL_CRT        - caminho para certificado

# Funcoes
    _log(){ now=$(date "+%Y-%m-%d-%T"); xlog="$now|https|$@"; echo "$xlog"; echo "$xlog" >> /var/log/init.log; }
    _abort(){ echo; echo "Abort: $1"; echo; exit $2; }
    _help(){
        echo ""
        echo "Use: $0 (comando) [opcoes]"
        echo ""
        echo "Gerar certificado auto-assinado para uso local"
        echo ""
        echo "Comando principal"
        echo " complete                   - Acao para completar arquivos ausentes (padrao)"
        echo " reset                      - Gerar novamente (chave e certificado)"
        echo " clear                      - Limpar arquivos (deletar chave e certificado)"
        echo ""
        echo ""
        echo "Opcoes gerais:"
        echo " complete                   - Acao para completar arquivos ausentes (padrao)"
        echo " reset                      - Gerar novamente (chave e certificado)"
        echo " clear                      - Limpar arquivos (deletar chave e certificado)"
        echo ""
        echo ""
        echo "Opcoes de CA:"
        echo " --workdir DIRECTORY        - Diretorio para arquivos temporarios"
        echo " --ca_filename CA_FILENAME  - Nome da unidade certificadora"
        echo " --ca_name  CA_NAME         - Nome da unidade certificadora"
        echo ""
        echo "Argumentos de informacoes do certificado SSL:"
        echo " --filename NAME            - Nome dos arquivos [$SSL_NAME]"
        echo " --country COUNTRY          - Pais [$SSL_COUNTRY]"
        echo " --province PROVINCE        - Estado/Provincia [$SSL_PROVINCE]"
        echo " --city CITY                - Cidade [$SSL_CITY]"
        echo " --company COMPANY          - Nome da empresa [$SSL_COMPANY]"
        echo " --ou ORG_UNIT              - Unidade organizacional, departamento [$SSL_ORG_UNIT]"
        echo " --cn COMMONNAME            - Nome CN (dominio, subdominio, wildcard), [$SSL_COMMONNAME]"
        echo " --email EMAIL              - Email do responsavel [$SSL_EMAIL]"
        echo " --days  DAYS               - Validade, em dias, do certificado [$SSL_DAYS]"
        echo ""
        echo ""
        echo "Argumentos para instalacao de certificado em local de uso:"
        echo " --copy N                   - Copiar: 0=nao, 1=sim, 2=apenas de destino ausente/invalido"
        echo " --key-dst SSL_KEY_DEST     - Caminho de destino da chave privada"
        echo " --crt-dst SSL_CRT_DEST     - Caminho de destino da chave privada"
        echo ""
        echo ""
        exit 1
    }
    _empty_test(){ [ "x$1" = "x" ] && return 1; return 0; }
    _verbose(){ [ "$DEBUG" = "1" ] && echo "$@"; }
    _delete(){
        _verbose "Delete: $1"
        rm -f "$1" 2>/dev/null
    }
    _build_cacert_cnf(){
        (
            echo '[ req ]'
            echo 'default_bits            = 2048'
            echo 'distinguished_name      = req_distinguished_name'
            echo ''
            echo 'encrypt_key             = no'
            echo 'prompt                  = no'
            echo ''
            echo 'string_mask             = nombstr'
            echo 'x509_extensions         = x509'
            echo ''
            echo '[ req_distinguished_name ]'
            echo "O                       = $CA_NAME"
            echo ''
            echo '[ x509 ]'
            echo 'basicConstraints        = CA:true, pathlen:0'
            echo 'keyUsage                = keyCertSign'
        ) > $CACERT_CNF
    }
    _build_cert_cnf(){
        (
            echo '[ req ]'
            echo 'default_bits            = 2048'
            echo "default_keyfile         = $SSL_KEY"
            echo 'distinguished_name      = req_distinguished_name'
            echo ''
            echo 'encrypt_key             = no'
            echo 'prompt                  = no'
            echo ''
            echo 'string_mask             = nombstr'
            echo 'x509_extensions         = x509'
            echo ''
            echo '[ req_distinguished_name ]'
            echo "countryName             = $SSL_COUNTRY"
            echo "stateOrProvinceName     = $SSL_PROVINCE"
            echo "localityName            = $SSL_CITY"
            echo "0.organizationName      = $SSL_COMPANY"
            echo "organizationalUnitName  = $SSL_ORG_UNIT"
            echo "emailAddress            = $SSL_EMAIL"
            echo ''
            echo "commonName              = $SSL_COMMONNAME"
            echo "unstructuredName        = $(date '+%Y-%m-%d'),$UNIQUE_IDENTIFIER"
            echo ''
            echo '[ x509 ]'
            echo 'basicConstraints        = CA:false'
            echo 'keyUsage                = digitalSignature,keyEncipherment,dataEncipherment'
            echo 'extendedKeyUsage        = serverAuth,clientAuth'
            echo "subjectAltName          = DNS:$HOSTNAME"
        ) > $CERT_CNF
    }

    # Verificar se par de chave+certificado estao OK
    # retorno 0 se OK, 1+ se houver problemas
    _ssl_files_verity(){
        _sfv_key="$1"
        _sfv_crt="$2"
        # Existencia dos arquivos
        [ -f "$_sfv_key" ] || return 1
        [ -f "$_sfv_crt" ] || return 2
        # Modulus coerente
        _sfv_key_md5=$(openssl rsa -noout -modulus -in "$_sfv_key"  | md5sum | awk '{print $1}')
        _sfv_crt_md5=$(openssl x509 -noout -modulus -in "$_sfv_crt" | md5sum | awk '{print $1}')
        [ "$_sfv_key_md5" = "$_sfv_crt_md5" ] || return 3
        # Validade do certificado
        _sfv_expire_unixdt=$(openssl x509 -enddate -noout -in "$_sfv_crt" | cut -d= -f 2)
        _sfv_expire_ts=$(date --date="$_sfv_expire_unixdt" "+%s")
        _sfv_now_ts=$(date "+%s")
        _sfv_left_secs=$(($_sfv_expire_ts-$_sfv_now_ts))
        # expirou...
        [ "$_sfv_left_secs" -lt 3660 ] && return 4

        # passou em tudo, ok
        return 0
    }

# Variaveis
#------------------------------------------------------------------------------------------------------------------------

    WORKDIR=${WORKDIR:-"/tmp/selfsig"}

    SSL_KEY_DEST=${SSL_KEY_DEST:-"/etc/ssl/server.key"}
    SSL_CRT_DEST=${SSL_CRT_DEST:-"/etc/ssl/server.crt"}
    COPY=1

    SSL_KEY=""
    SSL_CRT=""

    CA_FILENAME=${CA_FILENAME:-"nuva"}
    CA_NAME=${CA_NAME:-"Nuva Solucoes"}

    # nome para arquivos (chave e certificado)
    SSL_FILENAME="admin"

    SSL_COUNTRY=${SSL_COUNTRY:-"BR"}
    SSL_PROVINCE=${SSL_PROVINCE:-"Minas Gerais"}
    SSL_CITY=${SSL_CITY:-"Belo Horizonte"}
    SSL_COMPANY=${SSL_COMPANY:-"Intranet Corporation"}
    SSL_ORG_UNIT=${SSL_ORG_UNIT:-"Intranet IT Department"}
    SSL_COMMONNAME=${SSL_COMMONNAME:-"$(hostname -f)"}
    SSL_EMAIL=${SSL_EMAIL:-"contato@intranet.br"}
    SSL_DAYS=${SSL_DAYS:-"3650"}

    SSL_ARG_SUBJ=""

    DEBUG=0


# Processar argumentos
#------------------------------------------------------------------------------------------------------------------------

    # Acao: complete, reset, clear
    CMD=complete

    ARGS="$@"
    while [ 0 ]; do
        #echo "1=[$1] 2=[$2] 3=[$3] 4=[$4] 5=[$5] 6=[$6] 7=[$7] 8=[$8]"
        # Ajuda
        if [ "$1" = "-h" -o "$1" = "--h" -o "$1" = "--help" -o "$1" = "help" ]; then
            _help; exit 0;

        # Comando: refazer
        elif [ "$1" = "restart" -o "$1" = "reset" -o "$1" = "reboot" -o "$1" = "refresh" ]; then
            CMD="reset"; shift; continue

        # Comando: completar
        elif [ "$1" = "complete" -o "$1" = "normal" -o "$1" = "boot" -o "$1" = "start" -o "$1" = "play" ]; then
            CMD="complete"; shift; continue

        # Comando: limpar
        elif [ "$1" = "clear" -o "$1" = "clean" -o "$1" = "drop" -o "$1" = "delete" -o "$1" = "rm" ]; then
            CMD="clear"; shift; continue

        # Diretorio de trabalho
        elif [ "$1" = "--workdir" -o "$1" = "-workdir" -o "$1" = "--work-dir" -o "$1" = "-work-dir" -o "$1" = "-w" -o "$1" = "-W" ]; then
            _empty_test "$2" 40 && WORKDIR="$2"; shift 2; continue

        # Tipo de copia:
        elif [ "$1" = "--copy" -o "$1" = "-copy" -o "$1" = "--cp" -o "$1" = "-cp" ]; then
            _empty_test "$2" 41 && COPY="$2"; shift 2; continue

        # Caminho para destino de chave privada
        elif [ "$1" = "--key-dst" -o "$1" = "-key-dst" -o "$1" = "--keydst" -o "$1" = "-keydst" -o "$1" = "-key" -o "$1" = "--key" ]; then
            _empty_test "$2" 42 && SSL_KEY_DEST="$2"; shift 2; continue

        # Caminho para destino de certificado
        elif [ "$1" = "--crt-dst" -o "$1" = "-crt-dst" -o "$1" = "--crtdst" -o "$1" = "-crtdst" -o "$1" = "-crt" -o "$1" = "--crt" ]; then
            _empty_test "$2" 43 && SSL_CRT_DEST="$2"; shift 2; continue


        # Nome da CA para arquivos de chave e certificados da CA
        elif [ "$1" = "--ca-filename" -o "$1" = "-ca-filename" -o "$1" = "--ca_filename" -o "$1" = "-ca_filename" -o "$1" = "-F" ]; then
            _empty_test "$2" 51 && CA_FILENAME="$2"; shift 2; continue

        # Nome da CA para arquivos de chave e certificados da CA
        elif [ "$1" = "--ca-name" -o "$1" = "-ca-name" -o "$1" = "--caname" -o "$1" = "-caname" -o "$1" = "-C" -o "$1" = "-ca" -o "$1" = "--ca" ]; then
            _empty_test "$2" 52 && CA_NAME="$2"; shift 2; continue

        # Nome dos arquivos de saida (sem extensao)
        elif [ "$1" = "--name" -o "$1" = "-name" -o "$1" = "-n" -o "$1" = "name" ]; then
            _empty_test "$2" 11 && SSL_FILENAME="$2"; shift 2; continue

        # Pais
        elif [ "$1" = "--country" -o "$1" = "-country" -o "$1" = "-c" -o "$1" = "country" ]; then
            _empty_test "$2" 12 && SSL_COUNTRY="$2"; shift 2; continue

        # Estado/provincia
        elif [ "$1" = "--province" -o "$1" = "-province" -o "$1" = "-p" -o "$1" = "province" ]; then
            _empty_test "$2" 13 && SSL_PROVINCE="$2"; shift 2; continue

        # Cidade
        elif [ "$1" = "--city" -o "$1" = "-city" -o "$1" = "-y" -o "$1" = "city" ]; then
            _empty_test "$2" 14 && SSL_CITY="$2"; shift 2; continue

        # Empresa
        elif [ "$1" = "--company" -o "$1" = "-company" -o "$1" = "-x" -o "$1" = "company" ]; then
            _empty_test "$2" 15 && SSL_COMPANY="$2"; shift 2; continue

        # Organizacao/departamento
        elif [ "$1" = "--ou" -o "$1" = "-ou" -o "$1" = "-o" -o "$1" = "org" -o "$1" = "org_unit" ]; then
            _empty_test "$2" 16 && SSL_ORG_UNIT="$2"; shift 2; continue

        # Organizacao/departamento
        elif [ "$1" = "--cn" -o "$1" = "-cn" -o "$1" = "-N" -o "$1" = "commonname" -o "$1" = "-common-name" ]; then
            _empty_test "$2" 17 && SSL_COMMONNAME="$2"; shift 2; continue

        # Organizacao/departamento
        elif [ "$1" = "--email" -o "$1" = "-email" -o "$1" = "-e" -o "$1" = "email" -o "$1" = "e-mail" ]; then
            _empty_test "$2" 18 && SSL_EMAIL="$2"; shift 2; continue

        # Dias de validade
        elif [ "$1" = "--days" -o "$1" = "-days" -o "$1" = "-d" -o "$1" = "days" ]; then
            _empty_test "$2" 19 && SSL_DAYS="$2"; shift 2; continue

        # DEBUG
        elif [ "$1" = "--debug" -o "$1" = "-X" ]; then
            DEBUG=1
            shift
            continue
        else
            # argumento padrao: SSL_FILENAME
            if [ "x$SSL_FILENAME" = "x" ]; then
                SSL_FILENAME="$1"
                [ "x$1" = "x" ] || { shift; continue; }
            fi
            break
        fi
    done

    # Preparar
    mkdir -p "/admin/conf/cert"
    mkdir -p "$WORKDIR"

    # Variaveis defaults
    SSL_KEY=${SSL_KEY:-"$WORKDIR/$SSL_FILENAME.key"}
    SSL_CRT=${SSL_CRT:-"$WORKDIR/$SSL_FILENAME.crt"}
    SSL_CSR="$WORKDIR/$SSL_FILENAME.csr"

    CACERT_CNF="$WORKDIR/cacert.cnf"
    CERT_CNF="$WORKDIR/cert.cnf"



# Variaveis de ambiente
#------------------------------------------------------------------------------------------------------------------------

    export CACERT_CNF=$CACERT_CNF
    export UNIQUE_IDENTIFIER=a77fe9b89d43852f18d3d3
    export RANDFILE=/dev/urandom
    export SSL_DIRECTORY=$WORKDIR
    export CA_SSL_DIRECTORY=$WORKDIR
    export CA_NAME=$CA_NAME
    export CA_FILENAME=$CA_FILENAME
    export REQ_LOG=$WORKDIR/req.log
    export CERT_CNF=$CERT_CNF

    export CA_KEY=$WORKDIR/$CA_FILENAME.key
    export CA_CERT=$WORKDIR/$CA_FILENAME.crt
    export CA_SERIAL=$WORKDIR/$CA_FILENAME.srl
    export CA_STORE=$WORKDIR/castore.pem
    export HOSTNAME=$(hostname -f)



# Exibir variaveis
#------------------------------------------------------------------------------------------------------------------------

    # Exibir variaveis
    [ "$DEBUG" = "1" ] && {
        echo "[variaveis]"
        echo "        CMD..................: $CMD"
        echo ""
        echo "        WORKDIR..............: $WORKDIR"
        echo "        HOSTNAME.............: $HOSTNAME"
        echo ""
        echo "        CA_NAME..............: $CA_NAME"
        echo "        CA_FILENAME..........: $CA_FILENAME"
        echo "        CA_KEY...............: $CA_KEY"
        echo "        CA_CERT..............: $CA_CERT"
        echo "        CA_SERIAL............: $CA_SERIAL"
        echo "        CA_STORE.............: $CA_STORE"

        echo ""
        echo "        SSL_KEY_DEST.........: $SSL_KEY_DEST"
        echo "        SSL_CRT_DEST.........: $SSL_CRT_DEST"
        echo ""
        echo "        SSL_KEY..............: $SSL_KEY"
        echo "        SSL_CRT..............: $SSL_CRT"
        echo "        SSL_CSR..............: $SSL_CSR"
        echo "        SSL_FILENAME.........: $SSL_FILENAME"
        echo ""
        echo "        SSL_COUNTRY..........: $SSL_COUNTRY"
        echo "        SSL_PROVINCE.........: $SSL_PROVINCE"
        echo "        SSL_CITY.............: $SSL_CITY"
        echo "        SSL_COMPANY..........: $SSL_COMPANY"
        echo "        SSL_ORG_UNIT.........: $SSL_ORG_UNIT"
        echo "        SSL_COMMONNAME.......: $SSL_COMMONNAME"
        echo "        SSL_EMAIL............: $SSL_EMAIL"
        echo ""
        echo "        SSL_DAYS.............: $SSL_DAYS"
        echo ""
        echo "        CACERT_CNF...........: $CACERT_CNF"
        echo "        CERT_CNF.............: $CERT_CNF"
        echo ""
    }



# Acoes imediatas
#------------------------------------------------------------------------------------------------------------------------

    if [ "$CMD" = "reset" -o  "$CMD" = "clear" ]; then
        _verbose "Clean/reset command, delete files."
        _delete "$SSL_KEY"
        _delete "$SSL_CRT"
        _delete "$SSL_CSR"
        _delete "$CACERT_CNF"
        _delete "$CERT_CNF"
        _delete "$CA_KEY"
        _delete "$CA_CERT"
        _delete "$CA_SERIAL"
        _delete "$CA_STORE"
    fi

    # Limpeza nao requer continuacao
    if [ "$CMD" = "clear" ]; then
        _verbose "Clean command, ended."
        exit 0
    fi

    # Construir confs
    _verbose "Construindo: $CACERT_CNF"
    _build_cacert_cnf
    _verbose "Construindo: $CERT_CNF"
    _build_cert_cnf





# Criando CA
#------------------------------------------------------------------------------------------------------------------------


    if [ -f $CA_CERT ]; then
        _verbose "Arquivo certificado CA ja existe: $CA_CERT"
    else
        _verbose "Arquivo certificado CA ausente, criando: $CA_CERT"
        openssl req \
            -new \
            -x509 \
            -config $CACERT_CNF \
            -days 4200 \
            -keyout $CA_KEY \
            -out $CA_CERT \
            -sha256 || _abort "Erro $? ao criar CA"
    fi

    # Ca Store
    [ -f $CA_STORE ] || \
        openssl x509 \
            -in $CA_CERT \
            -out $CA_STORE

    # Ca SERIAL
    [ -f $CA_SERIAL ] || \
        echo 202101170001 > $CA_SERIAL


# Requisitar certificado
#------------------------------------------------------------------------------------------------------------------------


    if [ -f $SSL_CSR ]; then
        _verbose "Arquivo de requisicao ja existe: $SSL_CSR"
    else
        _verbose "Arquivo de requisicao ausente, criando: $SSL_CSR"
        openssl req \
            -new \
            -config $CERT_CNF \
            -days 4200 \
            -keyout $SSL_KEY \
            -out $SSL_CSR \
            -sha256 || _abort "Erro $? ao criar CSR"
    fi

# Assinar/gerar certificado
#------------------------------------------------------------------------------------------------------------------------


    if [ -f $SSL_CRT ]; then
        _verbose "Certificado ja existe: $SSL_CRT"
    else
        _verbose "Certificado ausente, criando: $SSL_CRT"
        openssl x509 \
            -req \
            -in $SSL_CSR \
            -CA $CA_CERT \
            -CAkey $CA_KEY \
            -extfile $CERT_CNF \
            -extensions x509 \
            -CAserial $CA_SERIAL \
            -days 4200 \
            -out $SSL_CRT \
            -sha256 || _abort "Erro $? ao criar CRT"
    fi


# Verificar certificados finais
#------------------------------------------------------------------------------------------------------------------------

    # Verificar chaves geradas
    _ssl_files_verity "$SSL_KEY" "$SSL_CRT"; sn="$?"
    [ "$sn" = "0" ] || _abort "Falha na verificacao: [$SSL_KEY / $SSL_CRT] erro $sn"

    # Logar assinaturas finais
    KEY_MD5=$(openssl rsa -noout -modulus -in "$SSL_KEY"  | md5sum | awk '{print $1}')
    CRT_MD5=$(openssl x509 -noout -modulus -in "$SSL_CRT" | md5sum | awk '{print $1}')
    _verbose "Assinatura da chave......: $KEY_MD5"
    _verbose "Assinatura do certificado: $CRT_MD5"



# Instalacao em destino usavel
#------------------------------------------------------------------------------------------------------------------------


    # Sem copia (copy=0)
    if [ "$COPY" = "0" ]; then
        _verbose "Copia de chave/certificado desativada"
    fi

    # Copia de seguranca para manter funcionamento (copy=1)
    if [ "$COPY" = "1" ]; then
        _verbose "Copia de chave/certificado ativada - modo fallback"
        _ssl_files_verity "$SSL_KEY_DEST" "$SSL_CRT_DEST"; fsn="$?"
        if [ "$fsn" = "0" ]; then
            _verbose "Arquivos de destino OK, nao requer instalacao"
        else
            _verbose "Arquivos de destino com problemas (erro $fsn), instalando"
            cp -rav "$SSL_KEY" "$SSL_KEY_DEST" || _abort "Erro $? ao copiar chave privada: $SSL_KEY para $SSL_KEY_DEST"
            cp -rav "$SSL_CRT" "$SSL_CRT_DEST" || _abort "Erro $? ao copiar chave privada: $SSL_CRT para $SSL_CRT_DEST"
        fi
    fi

    # Copiar imperativamente
    if [ "$COPY" = "2" ]; then
        _verbose "Copia de chave/certificado ativada - modo instalacao arbritaria"
        cp -rav "$SSL_KEY" "$SSL_KEY_DEST" || _abort "Erro $? ao copiar chave privada: $SSL_KEY para $SSL_KEY_DEST"
        cp -rav "$SSL_CRT" "$SSL_CRT_DEST" || _abort "Erro $? ao copiar chave privada: $SSL_CRT para $SSL_CRT_DEST"
    fi




exit 0








