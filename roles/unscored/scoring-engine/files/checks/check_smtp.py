"""
SCP-MAIL-003 "The Courier" - SMTP Check
Tests: TCP port 25, banner read, EHLO handshake
"""

import socket
import os
from typing import Dict

SMTP_PORT   = 25
TIMEOUT     = 8
EHLO_DOMAIN = os.environ.get("SMTP_EHLO_DOMAIN", "scorer.scp-foundation.local")


def _smtp_handshake(host: str, timeout: int = TIMEOUT) -> tuple:
    """Connect, read banner, send EHLO, check for 250 response."""
    try:
        with socket.create_connection((host, SMTP_PORT), timeout=timeout) as s:
            s.settimeout(timeout)
            # Read banner (220 ...)
            banner = s.recv(1024).decode("utf-8", errors="replace").strip()
            if not banner.startswith("220"):
                return False, False, f"Bad banner: {banner[:80]}"

            # Send EHLO
            s.sendall(f"EHLO {EHLO_DOMAIN}\r\n".encode())
            ehlo_resp = s.recv(1024).decode("utf-8", errors="replace").strip()

            # Send QUIT cleanly
            try:
                s.sendall(b"QUIT\r\n")
            except Exception:
                pass

            if "250" in ehlo_resp:
                return True, True, f"Banner OK, EHLO 250: {banner[:60]}"
            else:
                return True, False, f"Banner OK but EHLO failed: {ehlo_resp[:80]}"

    except ConnectionRefusedError:
        return False, False, f"Connection refused on port {SMTP_PORT}"
    except socket.timeout:
        return False, False, f"Timeout connecting to {host}:{SMTP_PORT}"
    except Exception as e:
        return False, False, f"Error: {e}"


def run(host: str) -> Dict:
    """
    Uptime     = Port 25 open and returns 220 banner
    Functional = EHLO receives 250 response
    """
    uptime, func, message = _smtp_handshake(host)
    return {
        "uptime": uptime,
        "functional": func,
        "message": message
    }
