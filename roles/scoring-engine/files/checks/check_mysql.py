"""
SCP-DB-004 "The Archive" - MySQL Check
Tests: TCP port 3306, MySQL handshake packet, optional auth + query
"""

import socket
import struct
import os
import hashlib
import hmac
from typing import Dict

MYSQL_PORT  = 3306
TIMEOUT     = 8
# Set env vars to enable authenticated query check
MYSQL_USER  = os.environ.get("MYSQL_USER", "")
MYSQL_PASS  = os.environ.get("MYSQL_PASS", "")
MYSQL_DB    = os.environ.get("MYSQL_DB", "")


def _read_packet(sock: socket.socket) -> bytes:
    """Read a MySQL packet (4-byte header + payload)."""
    header = b""
    while len(header) < 4:
        chunk = sock.recv(4 - len(header))
        if not chunk:
            raise ConnectionError("Connection closed")
        header += chunk
    length = struct.unpack("<I", header[:3] + b"\x00")[0]
    payload = b""
    while len(payload) < length:
        chunk = sock.recv(length - len(payload))
        if not chunk:
            raise ConnectionError("Connection closed during payload")
        payload += chunk
    return payload


def _check_mysql_handshake(host: str, timeout: int = TIMEOUT) -> tuple:
    """Connect to MySQL and verify the server greeting packet."""
    try:
        with socket.create_connection((host, MYSQL_PORT), timeout=timeout) as s:
            s.settimeout(timeout)
            packet = _read_packet(s)

            # MySQL greeting: first byte is protocol version (10 for MySQL 5+)
            if not packet:
                return False, False, "Empty greeting packet"

            proto = packet[0]
            if proto != 10:
                return False, False, f"Unexpected protocol version: {proto}"

            # Parse server version string (null-terminated after byte 1)
            null_pos = packet.index(0, 1)
            server_version = packet[1:null_pos].decode("utf-8", errors="replace")

            return True, True, f"MySQL {server_version} greeting OK"

    except ConnectionRefusedError:
        return False, False, f"Port {MYSQL_PORT} refused"
    except socket.timeout:
        return False, False, f"Timeout on {host}:{MYSQL_PORT}"
    except Exception as e:
        return False, False, f"Error: {e}"


def run(host: str) -> Dict:
    """
    Uptime     = Port 3306 open and valid MySQL greeting received
    Functional = Greeting OK (+ optional auth check if creds provided)

    For full auth checking, install pymysql and use MYSQL_USER/MYSQL_PASS env vars.
    """
    uptime, func, message = _check_mysql_handshake(host)

    # Optional: if pymysql is available and credentials are set, do a real query
    if uptime and MYSQL_USER and MYSQL_PASS:
        try:
            import pymysql
            conn = pymysql.connect(
                host=host, port=MYSQL_PORT,
                user=MYSQL_USER, password=MYSQL_PASS,
                database=MYSQL_DB if MYSQL_DB else None,
                connect_timeout=TIMEOUT
            )
            cur = conn.cursor()
            cur.execute("SELECT 1 AS containment_check")
            row = cur.fetchone()
            conn.close()
            if row and row[0] == 1:
                func = True
                message = f"Auth OK, query SELECT 1 returned {row[0]}"
            else:
                func = False
                message = "Auth OK but query returned unexpected result"
        except Exception as e:
            func = False
            message = f"Greeting OK but auth/query failed: {e}"

    return {
        "uptime": uptime,
        "functional": func,
        "message": message
    }
