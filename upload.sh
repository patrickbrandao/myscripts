#!/bin/sh

chmod +x *

rsync -e "ssh -p 1822" -ravp * root@compiler.nuva.net.br:/compiler/projects/myscripts/


