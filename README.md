Uses wayvnc with Sway to create a headless desktop with arbitrary payload, eg. a web page


Build container
```
$ podman build -t swayvnc .
```

Run container
```
podman run -e XDG_RUNTIME_DIR=/tmp -e WLR_BACKENDS=headless -e WLR_LIBINPUT_NO_DEVICES=1 -e MOZ_ENABLE_WAYLAND=1 -p5900:5900 swayvnc
```
