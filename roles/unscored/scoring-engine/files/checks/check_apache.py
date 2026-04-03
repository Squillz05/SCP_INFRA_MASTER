"""
SCP-WEB-002 "The Portal" - Apache HTTP Check
Tests: TCP port 80, HTTP 200 response, page content keyword present
"""

import socket
import urllib.request
import urllib.error
import ssl
import os
from typing import Dict

HTTP_PORT   = 80
HTTPS_PORT  = 443
TIMEOUT     = 8
# Keyword that must appear in the HTTP response body
# Change APACHE_KEYWORD env var to match your deployed page content
KEYWORD     = os.environ.get("APACHE_KEYWORD", "SCP Foundation")


def _check_port(host: str, port: int, timeout: int = TIMEOUT) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except Exception:
        return False


def _http_get(url: str, timeout: int = TIMEOUT) -> tuple:
    """Fetch URL, return (status_code, body_snippet)."""
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        req = urllib.request.Request(url, headers={"User-Agent": "SCP-Scorer/1.0"})
        with urllib.request.urlopen(req, timeout=timeout, context=ctx if url.startswith("https") else None) as resp:
            body = resp.read(4096).decode("utf-8", errors="replace")
            return resp.status, body
    except urllib.error.HTTPError as e:
        return e.code, ""
    except Exception as e:
        return 0, str(e)


def run(host: str) -> Dict:
    """
    Uptime     = Port 80 accepting connections
    Functional = HTTP GET returns 200 AND keyword found in body
    """
    port_up = _check_port(host, HTTP_PORT)
    if not port_up:
        return {
            "uptime": False,
            "functional": False,
            "message": f"HTTP port {HTTP_PORT} unreachable on {host}"
        }

    url = f"http://{host}/"
    status, body = _http_get(url)

    if status == 0:
        return {
            "uptime": True,
            "functional": False,
            "message": f"Port open but HTTP request failed: {body[:120]}"
        }

    if status != 200:
        return {
            "uptime": True,
            "functional": False,
            "message": f"HTTP {status} (expected 200)"
        }

    keyword_found = KEYWORD.lower() in body.lower()
    return {
        "uptime": True,
        "functional": keyword_found,
        "message": (
            f"HTTP 200 OK, keyword '{KEYWORD}' found"
            if keyword_found
            else f"HTTP 200 but keyword '{KEYWORD}' NOT found in body"
        )
    }
