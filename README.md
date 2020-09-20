# swayvnc - VNC Desktop in a container
Uses [Sway](https://swaywm.org) with [wayvnc](https://github.com/any1/wayvnc) to create a headless wayland desktop with arbitrary payload, eg. a web page

## Build
Build container
```
$ podman build -t swayvnc .
```

## Run
Run container
```
$ podman run -e XDG_RUNTIME_DIR=/tmp \
             -e WLR_BACKENDS=headless \
             -e WLR_LIBINPUT_NO_DEVICES=1 \
             -e MOZ_ENABLE_WAYLAND=1 \
              -p5900:5900 swayvnc
```

## TODO
* swaymsg does not yet work
