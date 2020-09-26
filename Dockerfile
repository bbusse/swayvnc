ARG ALPINE_VERSION=3.12
FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Björn Busse <bj.rn@baerlin.eu>"

# Tested with: x86_64 / aarch64
ENV ARCH="aarch64" \
    USER="vnc-user" \
    USER_BUILD="build" \
    APK_ADD="firefox mesa-dri-swrast openssl socat sway xkeyboard-config" \
    APK_DEL="bash curl" \
    PKG_WAYVNC="wayvnc-0.2.0-r0.apk" \
    PKG_NEATVNC="neatvnc-0.3.1-r0.apk" \
    VNC_LISTEN_ADDRESS="0.0.0.0" \
    VNC_AUTH_ENABLE="false" \
    VNC_KEYFILE="key.pem" \
    VNC_CERT="cert.pem" \
    VNC_PASS="$(pwgen -yns 8 1)"

RUN echo $'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && apk update

# Add packages
RUN apk add --no-cache $APK_ADD

# Add fonts
RUN apk add --no-cache msttcorefonts-installer fontconfig \
    && update-ms-fonts

# Add application user and remove existing users
RUN addgroup -S $USER && adduser -S $USER -G $USER -G abuild

COPY --from=ghcr.io/bbusse/swayvnc-build:latest /home/$USER_BUILD/packages/home/$ARCH/$PKG_WAYVNC /home/$USER/$PKG_WAYVNC
COPY --from=ghcr.io/bbusse/swayvnc-build:latest /home/$USER_BUILD/$PKG_NEATVNC /home/$USER/$PKG_NEATVNC
RUN apk add --no-cache --allow-untrusted /home/$USER/$PKG_WAYVNC

# Copy sway config
COPY config /etc/sway/config

# Add wayvnc to compositor startup and put IPC on the network
RUN mkdir /etc/sway/config.d \
    && echo "exec wayvnc" >> /etc/sway/config.d/exec \
    && echo "exec \"socat TCP-LISTEN:7023,fork UNIX-CONNECT:/tmp/sway-ipc.sock\"" >> /etc/sway/config.d/exec \
    && mkdir -p /home/$USER/.config/wayvnc/ \
    && printf "\
address=$VNC_LISTEN_ADDRESS\n\
enable_auth=$VNC_AUTH_ENABLE\n\
username=$USER\n\
password=$VNC_PASS\n\
private_key_file=/home/$USER/$VNC_KEYFILE\n\
certificate_file=/home/$USER/$VNC_CERT" > /home/$USER/.config/wayvnc/config

# Generate certificates vor VNC
RUN openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
	-keyout key.pem -out cert.pem -subj /CN=localhost \
	-addext subjectAltName=DNS:localhost,DNS:localhost,IP:127.0.0.1

# Cleanup
RUN rm -rf \
      /usr/share/man/* \
      /usr/includes/* \
      /var/cache/apk/* \
    && apk del --no-cache ${APK_DEL} \
    && deluser --remove-home daemon \
    && deluser --remove-home adm \
    && deluser --remove-home lp \
    && deluser --remove-home sync \
    && deluser --remove-home shutdown \
    && deluser --remove-home halt \
    && deluser --remove-home postmaster \
    && deluser --remove-home cyrus \
    && deluser --remove-home mail \
    && deluser --remove-home news \
    && deluser --remove-home uucp \
    && deluser --remove-home operator \
    && deluser --remove-home man \
    && deluser --remove-home cron \
    && deluser --remove-home ftp \
    && deluser --remove-home sshd \
    && deluser --remove-home at \
    && deluser --remove-home squid \
    && deluser --remove-home xfs \
    && deluser --remove-home games \
    && deluser --remove-home vpopmail \
    && deluser --remove-home ntp \
    && deluser --remove-home smmsp \
    && deluser --remove-home guest

# Add entrypoint
USER $USER
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
