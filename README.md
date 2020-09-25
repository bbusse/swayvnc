# swayvnc - VNC Desktop in a Container
Uses [Sway](https://swaywm.org) with [wayvnc](https://github.com/any1/wayvnc) to create a headless wayland desktop with arbitrary payload, e.g. a web page

## Build
Build container
```
$ podman build -t swayvnc .
```

## Run Container
Run container
```
$ podman run -e XDG_RUNTIME_DIR=/tmp \
             -e WLR_BACKENDS=headless \
             -e WLR_LIBINPUT_NO_DEVICES=1 \
             -e MOZ_ENABLE_WAYLAND=1 \
             -e URL1 https://freebsd.org \
             -p5900:5900 \
             -p7023:7023 swayvnc
```

## Run commands
Run commands with swaymsg by using socat to put them on the network
```
$ socat -v UNIX-LISTEN:/tmp/swayipc,fork TCP:$IP:7023
$ SWAYSOCK=/tmp/swayipc swaymsg command exec firefox [URL]
```

## Connect
Use some vnc client to connect the server
```
$ vinagre localhost:5900
```

## TODO
* Add tab rotation for the browser payload
