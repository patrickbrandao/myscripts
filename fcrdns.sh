#!/bin/sh

# Erros:
# 1 - sem reverso
# 2 - sem ip no nome
# 3 - retornos de reverso e IP nao conferem
# 9 - IP nao informado

# Argumentos:
# 1 - IP
ip="$1"
[ "x$ip" = "x" ] && exit 9

# 2 - sinal de verbose
v="$2"
_verbose(){ [ "x$v" = "x" ] || echo "# [$ip] $1"; }

# Obter reverso
_get_ipv4_rev(){
    host -t ptr $1 2>/dev/null | grep pointer | sed 's#pointer.#|#'| cut -f2 -d'|';
}
# Obter IPv4 do FQDN
_get_ipv4_name(){
     host -t a $1 2>/dev/null | grep 'has address' | head -1 | sed 's#address.#|#' | cut -f2 -d'|';
}

# Testar FCrDNS
    # - obter reverso
    rev=$(_get_ipv4_rev "$ip")
    _verbose "$ip IN PTR $rev"
    [ "x$rev" = "x" ] && { _verbose "err 1: $ip has no PTR"; exit 1; }

    # - obter ip do nome apontado no reverso
    ipv4=$(_get_ipv4_name "$rev")
    _verbose "$rev IN A $ipv4"
    [ "x$ipv4" = "x" ] && { _verbose "err 2: $rev has no A"; exit 2; }

    # comparar se sao iguais
    [ "$ipv4" = "$ip" ] || { _verbose "err 3: $rev=>$ipv4 <> $ip not match"; exit 3; }

    # tudo ok
    _verbose "OK, $ip == $ipv4"
    exit 0



