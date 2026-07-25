#!/usr/bin/env bash
#
# bash_unit tests for swayvnc (https://github.com/bash-unit/bash_unit).
#
# Requires the image to be built first:
#   podman build -t swayvnc .
#
# Run with:
#   bash_unit tests/test_vnc_session.sh

IMAGE="${SWAYVNC_IMAGE:-swayvnc}"
VNC_PORT="${SWAYVNC_TEST_PORT:-15910}"
CONTAINER_NAME="swayvnc-test-$$"
SUPPORT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/support" && pwd)"

_executor() {
    if command -v podman >/dev/null 2>&1; then
        echo podman
    else
        echo docker
    fi
}

setup() {
    EXECUTOR=$(_executor)

    "$EXECUTOR" run -d --name "$CONTAINER_NAME" \
        -e XDG_RUNTIME_DIR=/tmp \
        -e WLR_BACKENDS=headless \
        -e WLR_LIBINPUT_NO_DEVICES=1 \
        -e WLR_RENDERER=pixman \
        -e SWAYSOCK=/tmp/sway-ipc.sock \
        -p "127.0.0.1:${VNC_PORT}:5910" \
        --privileged \
        "$IMAGE" >/dev/null

    # A bare TCP connect is not enough to know wayvnc is ready: the listening
    # socket can accept() slightly before the RFB server loop is actually
    # serving, which drops the very next connection with no data. Wait for
    # an actual RFB version banner instead.
    for _ in $(seq 1 30); do
        if python3 -c "
import socket
s = socket.create_connection(('127.0.0.1', ${VNC_PORT}), timeout=1)
s.settimeout(1)
banner = s.recv(12)
s.close()
raise SystemExit(0 if banner.startswith(b'RFB ') else 1)
" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done

    fail "wayvnc never started listening on 127.0.0.1:${VNC_PORT}" \
        "$("$EXECUTOR" logs "$CONTAINER_NAME" 2>&1 | tail -n 20)"
}

teardown() {
    EXECUTOR=$(_executor)
    "$EXECUTOR" rm -f "$CONTAINER_NAME" >/dev/null 2>&1
}

test_vnc_server_accepts_a_working_client_session() {
    local output
    if ! output=$(python3 "${SUPPORT_DIR}/vnc_handshake.py" 127.0.0.1 "$VNC_PORT" 2>&1); then
        fail "VNC handshake did not complete: $output"
        return
    fi

    assert_matches "^vnc session established: [0-9]+x[0-9]+ desktop" "$output"
}
