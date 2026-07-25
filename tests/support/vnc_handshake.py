#!/usr/bin/env python3
"""Perform the opening steps of the RFB (VNC) protocol handshake against a
running wayvnc server, to prove a real VNC client could establish a session:

  ProtocolVersion -> Security -> SecurityResult -> ClientInit/ServerInit

Exits 0 and prints the negotiated framebuffer size on success.
Exits 1 with a message on stderr on any protocol violation or timeout.
"""
import socket
import struct
import sys


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


def recv_exact(sock, n):
    data = b""
    while len(data) < n:
        chunk = sock.recv(n - len(data))
        if not chunk:
            fail(f"connection closed early, expected {n} bytes, got {len(data)}")
        data += chunk
    return data


def main():
    if len(sys.argv) != 3:
        fail(f"usage: {sys.argv[0]} <host> <port>")

    host, port = sys.argv[1], int(sys.argv[2])

    with socket.create_connection((host, port), timeout=10) as sock:
        sock.settimeout(10)

        # 1. ProtocolVersion handshake
        server_version = recv_exact(sock, 12)
        if not server_version.startswith(b"RFB "):
            fail(f"expected an RFB version banner, got {server_version!r}")
        sock.sendall(server_version)

        # 2. Security handshake
        num_types = recv_exact(sock, 1)[0]
        if num_types == 0:
            reason_len = struct.unpack(">I", recv_exact(sock, 4))[0]
            reason = recv_exact(sock, reason_len)
            fail(f"server refused connection: {reason!r}")

        sec_types = recv_exact(sock, num_types)
        if 1 not in sec_types:
            fail(f"expected security type 'None' (1) to be offered, got {list(sec_types)}")
        sock.sendall(bytes([1]))

        sec_result = struct.unpack(">I", recv_exact(sock, 4))[0]
        if sec_result != 0:
            fail(f"expected SecurityResult OK (0), got {sec_result}")

        # 3. ClientInit / ServerInit
        sock.sendall(bytes([1]))  # shared-flag: share the desktop
        width, height = struct.unpack(">HH", recv_exact(sock, 4))
        recv_exact(sock, 16)  # PIXEL_FORMAT, not inspected here
        name_len = struct.unpack(">I", recv_exact(sock, 4))[0]
        name = recv_exact(sock, name_len).decode(errors="replace")

        if width == 0 or height == 0:
            fail(f"server reported an empty framebuffer: {width}x{height}")

        print(f"vnc session established: {width}x{height} desktop {name!r}")


if __name__ == "__main__":
    main()
