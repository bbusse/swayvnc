ARG ALPINE_VERSION=edge
FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Björn Busse <bj.rn@baerlin.eu>"
LABEL org.opencontainers.image.source https://github.com/bbusse/swayvnc

ARG ALPINE_VERSION

# Tested with: x86_64 / aarch64
ENV ARCH="x86_64" \
    USER="vnc-user" \
    USER_BUILD="build" \
    APK_ADD="openssl socat sway xkeyboard-config wayvnc" \
    APK_DEL="bash curl" \
    VNC_LISTEN_ADDRESS="0.0.0.0" \
    VNC_AUTH_ENABLE="false" \
    VNC_KEYFILE="key.pem" \
    VNC_CERT="cert.pem" \
    VNC_PASS="$(pwgen -yns 8 1)"

# Add packages
RUN apk add --no-cache $APK_ADD

# Add fonts
#RUN apk add --no-cache msttcorefonts-installer fontconfig \
#    && update-ms-fonts

# Add application user
RUN addgroup -S $USER && adduser -S $USER -G $USER

# Copy sway config
COPY config /etc/sway/config

# Add wayvnc to compositor startup and put IPC on the network
RUN mkdir /etc/sway/config.d \
    && echo "exec wayvnc 0.0.0.0 5910" >> /etc/sway/config.d/exec \
    && echo "exec \"socat TCP-LISTEN:7023,fork UNIX-CONNECT:/tmp/sway-ipc.sock\"" >> /etc/sway/config.d/exec \
    && mkdir -p /home/$USER/.config/wayvnc/ \
    && printf "\
address=$VNC_LISTEN_ADDRESS\n\
enable_auth=$VNC_AUTH_ENABLE\n\
username=$USER\n\
password=$VNC_PASS\n\
private_key_file=/home/$USER/$VNC_KEYFILE\n\
certificate_file=/home/$USER/$VNC_CERT" > /home/$USER/.config/wayvnc/config

# Generate certificates for VNC
RUN openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
	-keyout key.pem -out cert.pem -subj /CN=localhost \
	-addext subjectAltName=DNS:localhost,DNS:localhost,IP:127.0.0.1

# Add entrypoint
USER $USER
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
