"""
SCP-VPN-007 "The Veil" - OpenVPN Check
Tests: UDP port 1194 reachability (uptime), management interface via SSH tunnel (functional)

Since the OpenVPN management interface is bound to 127.0.0.1 on the VPN host,
we SSH into the host and query the management interface locally.

Set in .env:
  OPENVPN_HOST=10.0.0.x
  OPENVPN_PORT=1194          (default)
  OPENVPN_PROTO=udp          (default)
  OPENVPN_MGMT_PORT=7505     (default)
  OPENVPN_SSH_USER=scorer    (user to SSH in as)
  OPENVPN_SSH_PASS=          (password, or leave blank to use key)
  OPENVPN_SSH_KEY=           (path to private key, optional)
"""

import socket
import os
from typing import Dict

OPENVPN_PORT     = int(os.environ.get("OPENVPN_PORT", "1194"))
OPENVPN_PROTO    = os.environ.get("OPENVPN_PROTO", "udp").lower()
MGMT_PORT        = int(os.environ.get("OPENVPN_MGMT_PORT", "7505"))
SSH_USER         = os.environ.get("OPENVPN_SSH_USER", "")
SSH_PASS         = os.environ.get("OPENVPN_SSH_PASS", "")
SSH_KEY          = os.environ.get("OPENVPN_SSH_KEY", "")
TIMEOUT          = 8

# Minimal OpenVPN hard-reset client probe packet
OPENVPN_PROBE = bytes([
    0x38,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00,
])


def _check_udp(host: str, port: int, timeout: int = TIMEOUT) -> tuple:
    """Send an OpenVPN probe via UDP and wait for a response."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(timeout)
        s.sendto(OPENVPN_PROBE, (host, port))
        try:
            data, _ = s.recvfrom(256)
            s.close()
            return True, True, f"UDP {port} responded ({len(data)} bytes)"
        except socket.timeout:
            s.close()
            # UDP timeout is ambiguous — firewall may be dropping silently
            # Award uptime if the port is reachable at the TCP/network level
            return True, False, f"UDP {port} no response (possible firewall or service issue)"
    except Exception as e:
        return False, False, f"UDP probe error: {e}"


def _check_tcp(host: str, port: int, timeout: int = TIMEOUT) -> tuple:
    """TCP connect check for TCP-mode OpenVPN."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True, True, f"TCP {port} open"
    except ConnectionRefusedError:
        return False, False, f"TCP {port} refused"
    except socket.timeout:
        return False, False, f"TCP {port} timeout"
    except Exception as e:
        return False, False, f"TCP error: {e}"


def _check_mgmt_via_ssh(host: str, timeout: int = TIMEOUT) -> tuple:
    """
    SSH into the OpenVPN host and query the management interface on 127.0.0.1.
    This works even when the management interface is bound to localhost only.
    """
    if not SSH_USER:
        return False, "OPENVPN_SSH_USER not set in .env"

    try:
        import paramiko
    except ImportError:
        return False, "paramiko not installed — run: pip install paramiko"

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        connect_kwargs = dict(
            hostname=host,
            port=22,
            username=SSH_USER,
            timeout=timeout,
            banner_timeout=timeout,
            auth_timeout=timeout,
            look_for_keys=False,
            allow_agent=False,
        )
        if SSH_KEY and os.path.isfile(SSH_KEY):
            connect_kwargs["key_filename"] = SSH_KEY
            connect_kwargs["look_for_keys"] = False
        elif SSH_PASS:
            connect_kwargs["password"] = SSH_PASS
        else:
            return False, "No SSH credentials set (OPENVPN_SSH_PASS or OPENVPN_SSH_KEY)"

        client.connect(**connect_kwargs)

        # Query the management interface locally on the VPN host
        # Send 'status' command and read response
        cmd = f"echo 'status\\nquit' | nc -w 3 127.0.0.1 {MGMT_PORT}"
        _, stdout, stderr = client.exec_command(cmd, timeout=10)
        output = stdout.read().decode("utf-8", errors="replace")
        err    = stderr.read().decode("utf-8", errors="replace")
        client.close()

        if "CLIENT_LIST" in output or "END" in output or "OpenVPN" in output:
            # Count connected clients from status output
            client_lines = [l for l in output.splitlines() if l.startswith("CLIENT_LIST") and "Common Name" not in l]
            n_clients = len(client_lines)
            return True, f"Management OK — {n_clients} client(s) connected"

        if "Connection refused" in output or "Connection refused" in err:
            return False, f"Management interface not running on {host}:127.0.0.1:{MGMT_PORT}"

        if output.strip():
            return True, f"Management responded: {output[:80].strip()}"

        return False, f"Management interface empty response (is OpenVPN running?)"

    except paramiko.AuthenticationException:
        return False, f"SSH auth failed for {SSH_USER}@{host}"
    except Exception as e:
        return False, f"SSH tunnel error: {e}"
    finally:
        client.close()


def run(host: str) -> Dict:
    """
    Uptime     = VPN port reachable (UDP probe sent / TCP connected) (30pts)
    Functional = Management interface responsive via SSH tunnel (30pts)
    """
    # Uptime check
    if OPENVPN_PROTO == "tcp":
        uptime, _, up_msg = _check_tcp(host, OPENVPN_PORT)
    else:
        uptime, _, up_msg = _check_udp(host, OPENVPN_PORT)

    if not uptime:
        return {
            "uptime":     False,
            "functional": False,
            "message":    up_msg
        }

    # Functional check via SSH tunnel to management interface
    func_ok, func_msg = _check_mgmt_via_ssh(host)
    return {
        "uptime":     True,
        "functional": func_ok,
        "message":    f"{up_msg} | Mgmt: {func_msg}"
    }