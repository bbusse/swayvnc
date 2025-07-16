# swayvnc - VNC Desktop in a Container
The base image for remote application servers like [swayvnc-firefox](https://github.com/bbusse/swayvnc-firefox)  
swayvnc uses [Sway](https://swaywm.org) with [wayvnc](https://github.com/any1/wayvnc) to create a headless wayland desktop with arbitrary payloads, e.g. a web page with [swayvnc-firefox](https://github.com/bbusse/swayvnc-firefox)  
  
Due to missing applications (payloads) the container is of little use as it is. It is the base image
for application containers like [swayvnc-firefox](https://github.com/bbusse/swayvnc-firefox). Try this one
to get a better experience of how this works.

## Build container
```
$ podman build -t swayvnc .
```
### Build dependencies
The container uses [swayvnc-build](https://github.com/bbusse/swayvnc-build) to build the needed wayvnc apk for alpine,
since the packages are not available for all archs we want to support.
They get copied from the swayvnc-build image with "COPY --from=" during the build of swayvnc

## Run Container
```
$ export LISTEN_ADDRESS="127.0.0.1"; \
         podman run -e XDG_RUNTIME_DIR=/tmp \
                    -e WLR_BACKENDS=headless \
                    -e WLR_LIBINPUT_NO_DEVICES=1 \
                    -e SWAYSOCK=/tmp/sway-ipc.sock
                    -p${LISTEN_ADDRESS}:5910:5910 \
                    -p${LISTEN_ADDRESS}:7023:7023 swayvnc
# or
$ ./run.sh
```
## Connect
Use some vnc client to connect to the server
```
$ wlvncc <vnc-server> 5910
# or
$ vinagre [vnc-server:5910]
```
## Run Commands
Run commands with swaymsg by using socat to put them on the network
Replace $IP with the actual IP you want to listen on
```
$ socat UNIX-LISTEN:/tmp/swayipc,fork TCP:$IP:7023
$ SWAYSOCK=/tmp/swayipc swaymsg command exec "firefox [URL]"
```
## Notes
If you want to optimise for size, fonts take around 200MB of space
