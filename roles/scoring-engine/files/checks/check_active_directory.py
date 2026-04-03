"""
SCP-AD-001 "The Registry" - Active Directory Check
Tests: LDAP port 389, Kerberos port 88, optional LDAP bind query
"""

import socket
import ssl
import struct
from typing import Dict

LDAP_PORT   = 389
LDAPS_PORT  = 636
KRB_PORT    = 88
TIMEOUT     = 5

# LDAP anonymous bind request (minimal BER encoding)
# Sequence { MessageID=1, BindRequest { version=3, dn="", simple="" } }
LDAP_BIND_REQUEST = bytes([
    0x30, 0x0c,          # Sequence, 12 bytes
    0x02, 0x01, 0x01,    # Integer: MessageID = 1
    0x60, 0x07,          # Application 0 (BindRequest), 7 bytes
    0x02, 0x01, 0x03,    # Integer: version = 3
    0x04, 0x00,          # OctetString: dn = ""
    0x80, 0x00,          # Context[0]: simple password = ""
])

def _check_port(host: str, port: int, timeout: int = TIMEOUT) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except Exception:
        return False


def _ldap_bind(host: str, timeout: int = TIMEOUT) -> tuple:
    """Attempt anonymous LDAP bind and check for a valid response."""
    try:
        with socket.create_connection((host, LDAP_PORT), timeout=timeout) as s:
            s.sendall(LDAP_BIND_REQUEST)
            data = s.recv(256)
            # A valid LDAP BindResponse starts with 0x30 (Sequence)
            # and should contain result code 0x0a (resultCode)
            if data and data[0] == 0x30:
                return True, "LDAP bind response received"
            return False, "Unexpected LDAP response"
    except Exception as e:
        return False, f"LDAP bind failed: {e}"


def run(host: str) -> Dict:
    """
    Returns dict with keys: uptime (bool), functional (bool), message (str)
    Uptime    = LDAP port 389 is open
    Functional = LDAP anonymous bind returns valid response AND Kerberos port 88 is open
    """
    ldap_up = _check_port(host, LDAP_PORT)
    krb_up  = _check_port(host, KRB_PORT)

    if not ldap_up:
        return {
            "uptime": False,
            "functional": False,
            "message": f"LDAP port {LDAP_PORT} unreachable on {host}"
        }

    func_ok, func_msg = _ldap_bind(host)

    if not krb_up:
        func_ok = False
        func_msg = f"LDAP up but Kerberos port {KRB_PORT} unreachable"

    return {
        "uptime": ldap_up,
        "functional": func_ok,
        "message": func_msg if not func_ok else f"LDAP bind OK, Kerberos port {KRB_PORT} open"
    }
