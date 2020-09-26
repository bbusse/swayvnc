FROM alpine:3.12

# Tested with: x86_64 / aarch64
ENV ARCH aarch64
ENV USER vnc-user
ENV USER_BUILD build
ENV PKG_WAYVNC wayvnc-0.2.0-r0.apk
ENV VNC_LISTEN_ADDRESS 0.0.0.0
ENV VNC_PASS $(pwgen -yns 8 1)

RUN echo $'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
RUN apk update

# Add packages
RUN apk add --no-cache neatvnc firefox mesa-dri-swrast neatvnc openssl socat sway xkeyboard-config

# Add fonts
RUN apk add --no-cache msttcorefonts-installer fontconfig
RUN update-ms-fonts

# Add application user
RUN addgroup -S $USER && adduser -S $USER -G $USER -G abuild

COPY --from=ghcr.io/bbusse/swayvnc-build:latest /home/$USER_BUILD/packages/home/$ARCH/$PKG_WAYVNC /home/$USER/$PKG_WAYVNC
RUN apk add --allow-untrusted /home/$USER/$PKG_WAYVNC

# Copy sway config
COPY config /etc/sway/config

# Add wayvnc to compositor startup and put IPC on the network
RUN mkdir /etc/sway/config.d
RUN echo "exec wayvnc" >> /etc/sway/config.d/exec
RUN echo "exec \"socat TCP-LISTEN:7023,fork UNIX-CONNECT:/tmp/sway-ipc.sock\"" >> /etc/sway/config.d/exec
RUN mkdir -p /home/$USER/.config/wayvnc/
RUN printf "\
address=$VNC_LISTEN_ADDRESS\n\
enable_auth=false\n\
username=$USER\n\
password=$VNC_PASS\n\
private_key_file=/home/$USER/key.pem\n\
certificate_file=/home/$USER/cert.pem" > /home/$USER/.config/wayvnc/config

# Generate certificates vor VNC
RUN openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
	-keyout key.pem -out cert.pem -subj /CN=localhost \
	-addext subjectAltName=DNS:localhost,DNS:localhost,IP:127.0.0.1

# Add entrypoint
USER $USER
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
