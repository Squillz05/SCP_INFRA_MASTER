"""
SCP-SMB-005 "The Vault" - SMB File Share Check
Tests: TCP port 445 (uptime), scored share accessible via smbclient (functional)

Uptime     = TCP connect to port 445 succeeds
Functional = smbclient can list the scored share anonymously (or with creds)

Set SMB_SHARE and optionally SMB_USER/SMB_PASS in .env:
  SMB_SHARE=SCPVault          (just the share name, no slashes)
  SMB_USER=scorer             (optional, leave blank for anonymous)
  SMB_PASS=password           (optional)
"""

import socket
import subprocess
import os
import shutil
from typing import Dict

SMB_PORT  = 445
TIMEOUT   = 8

SMB_SHARE = os.environ.get("SMB_SHARE", "SCPVault")
SMB_USER  = os.environ.get("SMB_USER", "")
SMB_PASS  = os.environ.get("SMB_PASS", "")


def _port_open(host: str, timeout: int = TIMEOUT) -> bool:
    try:
        with socket.create_connection((host, SMB_PORT), timeout=timeout):
            return True
    except Exception:
        return False


def _check_share(host: str, timeout: int = TIMEOUT) -> tuple:
    """
    Use smbclient to list the scored share.
    Returns (success: bool, message: str)
    """
    if not shutil.which("smbclient"):
        # smbclient not installed — fall back to TCP hold check
        return _tcp_hold_check(host, timeout)

    # Build smbclient command
    target = f"//{host}/{SMB_SHARE}"
    cmd = ["smbclient", target, "-t", str(timeout)]

    if SMB_USER and SMB_PASS:
        cmd += ["-U", f"{SMB_USER}%{SMB_PASS}"]
    else:
        cmd += ["-N"]  # anonymous / no password

    cmd += ["-c", "ls"]  # list share contents

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout + 2
        )
        output = result.stdout + result.stderr

        if result.returncode == 0:
            return True, f"Share \\\\{host}\\{SMB_SHARE} accessible, listing OK"

        # Parse common failure messages
        if "NT_STATUS_ACCESS_DENIED" in output:
            return False, f"Share exists but access denied — credentials may have changed"
        if "NT_STATUS_BAD_NETWORK_NAME" in output or "NT_STATUS_OBJECT_NAME_NOT_FOUND" in output:
            return False, f"Share '{SMB_SHARE}' not found on {host}"
        if "NT_STATUS_LOGON_FAILURE" in output:
            return False, f"Authentication failed for share '{SMB_SHARE}'"
        if "Connection refused" in output or "Connection timed out" in output:
            return False, f"smbclient could not connect to {host}"

        return False, f"smbclient failed (rc={result.returncode}): {output[:120].strip()}"

    except subprocess.TimeoutExpired:
        return False, f"smbclient timed out connecting to {host}"
    except Exception as e:
        return False, f"smbclient error: {e}"


def _tcp_hold_check(host: str, timeout: int = TIMEOUT) -> tuple:
    """
    Fallback if smbclient is not installed.
    Connects and waits — SMB holds the connection open before negotiation.
    """
    try:
        with socket.create_connection((host, SMB_PORT), timeout=timeout) as s:
            s.settimeout(2)
            try:
                data = s.recv(4)
                if data:
                    return True, f"SMB port open, service responding ({data.hex()})"
                return False, "SMB connection closed immediately"
            except socket.timeout:
                return True, f"SMB port {SMB_PORT} open and holding connections"
    except Exception as e:
        return False, f"TCP hold check failed: {e}"


def run(host: str) -> Dict:
    """
    Uptime     = TCP connect to port 445 succeeds (30pts)
    Functional = Scored share accessible via smbclient (30pts)
    """
    uptime = _port_open(host)
    if not uptime:
        return {
            "uptime":     False,
            "functional": False,
            "message":    f"Port {SMB_PORT} unreachable on {host}"
        }

    func_ok, message = _check_share(host)
    return {
        "uptime":     True,
        "functional": func_ok,
        "message":    message
    }