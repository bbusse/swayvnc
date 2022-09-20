#!/usr/bin/env bash

set -euo pipefail

export CONTAINER=swayvnc
export LISTEN_ADDRESS="[::1]"
export VERBOSE=1

SCRIPT_NAME=$(basename $0)
readonly SCRIPT_NAME


log() {
    if (( 1=="${VERBOSE}" )); then
        echo "$@" >&2
    fi

    logger -p user.notice -t ${SCRIPT_NAME} "$@"
}

error() {
    echo "$@" >&2
    logger -p user.error -t ${SCRIPT_NAME} "$@"
}

if [[ -z $(which podman) ]]; then
    if [[ -z $(which docker) ]]; then
        error "Could not find container executor."
        error "Install either podman or docker"
        exit 1
    else
        executor=docker
        log "Using ${executor} to run ${CONTAINER}"
    fi
else
    executor=podman
    log "Using ${executor} to run ${CONTAINER}"
fi

${executor} run -e XDG_RUNTIME_DIR=/tmp \
                -e WLR_BACKENDS=headless \
                -e WLR_LIBINPUT_NO_DEVICES=1 \
                -e SWAYSOCK=/tmp/sway-ipc.sock \
                -p${LISTEN_ADDRESS}:5910:5910 \
                -p${LISTEN_ADDRESS}:7000:7000 \
                -p${LISTEN_ADDRESS}:7023:7023 \
                ${CONTAINER}
