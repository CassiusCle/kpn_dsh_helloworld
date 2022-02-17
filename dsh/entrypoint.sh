#!/bin/sh
medir=${0%/*}

source ${medir}/setup_ssl_dsh.sh

exec "$@"
