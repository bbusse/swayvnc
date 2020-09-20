FROM alpine:3.12

# Tested with: x86_64 / aarch64
ENV ARCH aarch64

RUN echo $'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
RUN apk update

# Add build requirements
RUN apk add alpine-sdk
RUN apk add --no-cache sway mesa-dri-swrast xkeyboard-config neatvnc firefox

# Add fonts
RUN apk add --no-cache msttcorefonts-installer fontconfig
RUN update-ms-fonts

# Add build and application user
RUN addgroup -S vnc-user && adduser -S vnc-user -G vnc-user -G abuild
RUN chown -R vnc-user /var/cache/distfiles

# Get and build wayvnc
USER vnc-user
WORKDIR /home/vnc-user
ADD https://git.alpinelinux.org/aports/plain/community/wayvnc/APKBUILD /home/vnc-user
RUN abuild-keygen -a -n
RUN abuild checksum
RUN abuild -r
USER root
RUN apk add --allow-untrusted /home/vnc-user/packages/home/$ARCH/wayvnc-0.2.0-r0.apk

# Start wayvnc and payload(s) with sway
COPY config /etc/sway/config

# Add payloads to compositor startup
RUN mkdir /etc/sway/config.d
RUN echo "exec firefox --kiosk --no-remote --private-window https://freebsd.org" >> /etc/sway/config.d/exec
RUN echo "exec wayvnc" >> /etc/sway/config.d/exec
RUN echo "MOZ_ENABLE_WAYLAND=1" >> /etc/sway/env
USER vnc-user
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
