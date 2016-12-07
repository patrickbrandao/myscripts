#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

dir="$1"

cd "$dir" || exit

clear
find . | sed 's#^\./#/#g' | \
	while read x; do
		if [ -d "$dir/$x" ]; then
			echo $x
		fi
	done | sort

