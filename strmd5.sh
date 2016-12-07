#!/bin/sh

echo -n "$1" | md5sum | awk '{print $1}'

