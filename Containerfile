ARG ALPINE_VERSION=edge
FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Björn Busse <bj.rn@baerlin.eu>"
LABEL org.opencontainers.image.source https://github.com/bbusse/swayvnc

ARG ALPINE_VERSION

# Tested with: x86_64 / aarch64
ENV USER="vnc-user" \
    APK_ADD="openssl socat sway xkeyboard-config wayvnc fontconfig freetype harfbuzz" \
    VNC_LISTEN_ADDRESS="0.0.0.0" \
    VNC_AUTH_ENABLE="false" \
    VNC_KEYFILE="key.pem" \
    VNC_CERT="cert.pem"

# Add packages
RUN apk add --no-cache $APK_ADD

# Add fonts
# As recommended by https://wiki.alpinelinux.org/wiki/Fonts
RUN apk add font-terminus font-inconsolata font-dejavu font-noto font-noto-cjk font-awesome font-noto-extra \
    && fc-cache -f
# Additionally add MS fonts
#RUN apk add --no-cache msttcorefonts-installer fontconfig \
#    && update-ms-fonts

# Add application user
RUN addgroup -S $USER && adduser -S $USER -G $USER

# Copy sway config
COPY config /etc/sway/config

# Add wayvnc to compositor startup and put IPC on the network
RUN mkdir /etc/sway/config.d \
    && echo "exec wayvnc 0.0.0.0 5910" >> /etc/sway/config.d/exec \
    && echo "exec \"socat TCP-LISTEN:7023,fork UNIX-CONNECT:/tmp/sway-ipc.sock\"" >> /etc/sway/config.d/exec

# Add entrypoint
USER $USER
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
