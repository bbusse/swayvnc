#!/bin/sh
set -o errexit

VNC_LISTEN_ADDRESS="${VNC_LISTEN_ADDRESS:-0.0.0.0}"
VNC_AUTH_ENABLE="${VNC_AUTH_ENABLE:-false}"
VNC_KEYFILE="${VNC_KEYFILE:-key.pem}"
VNC_CERT="${VNC_CERT:-cert.pem}"
VNC_PASS="${VNC_PASS:-$(openssl rand -base64 12)}"
HOME_DIR="/home/$USER"

mkdir -p "$HOME_DIR/.config/wayvnc"

cat > "$HOME_DIR/.config/wayvnc/config" <<EOF
address=$VNC_LISTEN_ADDRESS
enable_auth=$VNC_AUTH_ENABLE
username=$USER
password=$VNC_PASS
private_key_file=$HOME_DIR/$VNC_KEYFILE
certificate_file=$HOME_DIR/$VNC_CERT
EOF

if [ ! -f "$HOME_DIR/$VNC_KEYFILE" ] || [ ! -f "$HOME_DIR/$VNC_CERT" ]; then
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout "$HOME_DIR/$VNC_KEYFILE" -out "$HOME_DIR/$VNC_CERT" -subj /CN=localhost \
        -addext subjectAltName=DNS:localhost,IP:127.0.0.1
fi

echo "VNC password: $VNC_PASS" >&2

case "$1" in
    sh|bash)
        set -- "$@"
    ;;
    *)
        set -- sway
    ;;
esac

exec "$@"
