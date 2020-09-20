#!/bin/sh
set -o errexit

BROWSER="firefox"
PAYLOAD="BROWSER"

case "$1" in
    sh|bash)
        set -- "$@"
    ;;
    *)
        set -- sway
        export SWAYSOCK=/tmp/sway-ipc.100..sock
	echo $SWAYSOCK
        #swaymsg exec $BROWSER $IS2_URL
    ;;
esac

exec "$@"
