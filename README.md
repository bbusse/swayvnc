# swayvnc - VNC Desktop in a Container
Due to missing applications (payloads) the container is of little use as it is. It is the base image
for application containers like [swayvnc-firefox](https://github.com/bbusse/swayvnc-firefox). Try this one
to get a better experience of how this works.
The base image for remote application servers like [swayvnc-firefox](https://github.com/bbusse/swayvnc-firefox) uses [Sway](https://swaywm.org) with [wayvnc](https://github.com/any1/wayvnc) to create a headless wayland desktop with arbitrary payloads, e.g. a web page with [swayvnc-firefox](https://github.com/bbusse/swayvnc-firefox)

## Build
### Build dependency
Use [swayvnc-build](https://github.com/bbusse/swayvnc-build) to build the needed wayvnc apk for alpine
The needed packages are getting copied from the swayvnc-build image with "COPY --from=" during the build of swayvnc. You don't need to do this manually

### Build container
```
$ podman build -t swayvnc .
```

## Run Container
Run container
```
export LISTEN_ADDRESS="127.0.0.1"; podman run -e XDG_RUNTIME_DIR=/tmp \
             -e WLR_BACKENDS=headless \
             -e WLR_LIBINPUT_NO_DEVICES=1 \
             -e SWAYSOCK=/tmp/sway-ipc.sock
             -p${LISTEN_ADDRESS}:5900:5900 \
             -p${LISTEN_ADDRESS}:7023:7023 swayvnc
```

## Run Commands
Run commands with swaymsg by using socat to put them on the network
Replace $IP with the actual IP you want to listen on
```
$ socat UNIX-LISTEN:/tmp/swayipc,fork TCP:$IP:7023
$ SWAYSOCK=/tmp/swayipc swaymsg command exec "firefox [URL]"
```

## Connect
Use some vnc client to connect the server
```
$ wlvncc <vnc-server>
# or
$ vinagre [vnc-server:5900]
```

## TODO
* Add tab rotation for the browser payload
