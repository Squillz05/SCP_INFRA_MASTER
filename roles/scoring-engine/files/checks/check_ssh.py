"""
SCP-SSH-006 "The Tunnel" - SSH Server Check
Tests: TCP port 22 + banner (uptime), password auth for all scored users (functional)

Scored users must ALL successfully authenticate for full functional points.
If any single user fails, functional = False.

Set in .env:
  SSH_HOST=10.0.0.x
  SSH_USER_1=scp343
  SSH_PASS_1=<password>
  SSH_USER_2=scp073
  SSH_PASS_2=<password>
"""

import socket
import os
from typing import Dict, List

SSH_PORT = 22
TIMEOUT  = 8

# Scored users — add more SSH_USER_N / SSH_PASS_N pairs to .env as needed
SCORED_USERS = []
i = 1
while True:
    user = os.environ.get(f"SSH_USER_{i}", "")
    pw   = os.environ.get(f"SSH_PASS_{i}", "")
    if not user:
        break
    SCORED_USERS.append({"user": user, "password": pw})
    i += 1

# Fallback: legacy single-user config
if not SCORED_USERS:
    legacy_user = os.environ.get("SSH_USER", "")
    legacy_key  = os.environ.get("SSH_KEY_PATH", "")
    if legacy_user:
        SCORED_USERS.append({"user": legacy_user, "password": "", "key": legacy_key})


def _check_banner(host: str, timeout: int = TIMEOUT) -> tuple:
    """Check port 22 is open and returns a valid SSH banner."""
    try:
        with socket.create_connection((host, SSH_PORT), timeout=timeout) as s:
            s.settimeout(timeout)
            banner = s.recv(256).decode("utf-8", errors="replace").strip()
            if banner.startswith("SSH-"):
                return True, banner
            return False, f"Unexpected banner: {banner[:80]}"
    except ConnectionRefusedError:
        return False, f"Port {SSH_PORT} refused"
    except socket.timeout:
        return False, f"Timeout on {host}:{SSH_PORT}"
    except Exception as e:
        return False, f"Error: {e}"


def _auth_user(host: str, username: str, password: str, timeout: int = TIMEOUT) -> tuple:
    """Attempt password authentication for a single user via paramiko."""
    try:
        import paramiko
    except ImportError:
        return False, "paramiko not installed — run: pip install paramiko"

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(
            hostname=host,
            port=SSH_PORT,
            username=username,
            password=password,
            look_for_keys=False,
            allow_agent=False,
            timeout=timeout,
            banner_timeout=timeout,
            auth_timeout=timeout,
        )
        # Run a quick command to confirm the session is truly functional
        _, stdout, _ = client.exec_command("echo SCP_OK", timeout=5)
        output = stdout.read().decode("utf-8", errors="replace").strip()
        client.close()

        if "SCP_OK" in output:
            return True, f"Auth OK for {username}"
        return False, f"Auth succeeded for {username} but command failed (got: '{output[:40]}')"

    except paramiko.AuthenticationException:
        return False, f"Authentication failed for {username}"
    except paramiko.SSHException as e:
        return False, f"SSH error for {username}: {e}"
    except Exception as e:
        return False, f"Error authenticating {username}: {e}"
    finally:
        client.close()


def run(host: str) -> Dict:
    """
    Uptime     = Port 22 open and SSH banner received (30pts)
    Functional = ALL scored users authenticate successfully (30pts)
                 Fails if any single user cannot log in.
    """
    # Uptime check
    banner_ok, banner_msg = _check_banner(host)
    if not banner_ok:
        return {
            "uptime":     False,
            "functional": False,
            "message":    banner_msg
        }

    # Functional check — must have scored users configured
    if not SCORED_USERS:
        return {
            "uptime":     True,
            "functional": False,
            "message":    "Banner OK but no scored users configured (set SSH_USER_1, SSH_PASS_1, etc. in .env)"
        }

    if any(not u["password"] for u in SCORED_USERS):
        missing = [u["user"] for u in SCORED_USERS if not u["password"]]
        return {
            "uptime":     True,
            "functional": False,
            "message":    f"Banner OK but passwords not set for: {', '.join(missing)}"
        }

    # Try each user — all must pass
    failed = []
    passed = []
    for u in SCORED_USERS:
        ok, msg = _auth_user(host, u["user"], u["password"])
        if ok:
            passed.append(u["user"])
        else:
            failed.append(msg)

    if failed:
        return {
            "uptime":     True,
            "functional": False,
            "message":    f"Auth failed — {'; '.join(failed)}"
        }

    return {
        "uptime":     True,
        "functional": True,
        "message":    f"All users authenticated: {', '.join(passed)}"
    }