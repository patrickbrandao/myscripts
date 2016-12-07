#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

file=$1

if [ -f "$file" ]; then
	md5sum $file 2>/dev/null | awk '{print $1}'
else
	echo ""
fi

