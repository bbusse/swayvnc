FROM alpine:3.12

# Tested with: x86_64 / aarch64
ENV ARCH aarch64
ENV USER vnc-user
ENV PKG_WAYVNC wayvnc-0.2.0-r0.apk

RUN echo $'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
RUN apk update

# Add packages
RUN apk add --no-cache sway mesa-dri-swrast xkeyboard-config neatvnc firefox socat

# Add fonts
RUN apk add --no-cache msttcorefonts-installer fontconfig
RUN update-ms-fonts

# Add application user
RUN addgroup -S $USER && adduser -S $USER -G $USER -G abuild

COPY $PKG_WAYVNC /home/$USER/$PKG_WAYVNC
RUN apk add --allow-untrusted /home/$USER/$PKG_WAYVNC

# Copy sway config
COPY config /etc/sway/config

# Add wayvnc to compositor startup and put IPC on the network
RUN mkdir /etc/sway/config.d
RUN echo "exec wayvnc" >> /etc/sway/config.d/exec
RUN echo "exec socat TCP-LISTEN:7023,fork UNIX-CONNECT:/tmp/sway-ipc.sock" >> /etc/sway/config.d/exec

# Add entrypoint
USER $USER
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
