"""
SCP Foundation Scoring Engine
Site Golisano - Containment Programming Monitor
Grey Team (Overseers) - Echo Team

Scoring methodology:
  30 pts - uptime (port/connectivity)
  30 pts - functionality (protocol/auth check)
  60 pts - maximum per service per check
"""

import sqlite3
import time
import threading
import logging
import os
from datetime import datetime
from typing import Optional
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from checks import (
    check_active_directory,
    check_apache,
    check_smtp,
    check_mysql,
    check_smb,
    check_ssh,
    check_openvpn,
)

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

DB_PATH        = os.environ.get("SCORING_DB", "/opt/scp-scoring/scoring.db")
CHECK_INTERVAL = int(os.environ.get("CHECK_INTERVAL", "120"))

# Points are now split: 30 for uptime, 30 for functionality (60 total per check)
UPTIME_POINTS   = 30
FUNC_POINTS     = 30
POINTS_PER_CHECK = UPTIME_POINTS + FUNC_POINTS  # 60

# ---------------------------------------------------------------------------
# Service Definitions
# ---------------------------------------------------------------------------
SERVICES = [
    {
        "id":           "active_directory",
        "name":         "Active Directory",
        "scp_name":     'SCP-AD-001 "The Registry"',
        "host_env":     "AD_HOST",
        "host_default": "10.0.0.10",
        "category":     "Authentication Services",
        "os":           "Windows Server",
        "description":  "Domain authentication and directory services. LDAP port 389, Kerberos port 88.",
        "check_fn":     check_active_directory.run,
    },
    {
        "id":           "apache",
        "name":         "Apache HTTP",
        "scp_name":     'SCP-WEB-002 "The Portal"',
        "host_env":     "APACHE_HOST",
        "host_default": "10.0.0.20",
        "category":     "Web Services",
        "os":           "Linux",
        "description":  "HTTP/HTTPS web server. Checks availability and page content integrity.",
        "check_fn":     check_apache.run,
    },
    {
        "id":           "smtp",
        "name":         "SMTP Mail",
        "scp_name":     'SCP-MAIL-003 "The Courier"',
        "host_env":     "SMTP_HOST",
        "host_default": "10.0.0.10",
        "category":     "Email Services",
        "os":           "Windows Server",
        "description":  "SMTP mail relay. Checks port 25 banner and EHLO handshake.",
        "check_fn":     check_smtp.run,
    },
    {
        "id":           "mysql",
        "name":         "MySQL Database",
        "scp_name":     'SCP-DB-004 "The Archive"',
        "host_env":     "MYSQL_HOST",
        "host_default": "10.0.0.21",
        "category":     "Database Services",
        "os":           "Linux",
        "description":  "MySQL RDBMS. Checks connectivity, authentication, and query execution.",
        "check_fn":     check_mysql.run,
    },
    {
        "id":           "smb",
        "name":         "SMB File Share",
        "scp_name":     'SCP-SMB-005 "The Vault"',
        "host_env":     "SMB_HOST",
        "host_default": "10.0.0.10",
        "category":     "File Services",
        "os":           "Windows Server",
        "description":  "SMB/CIFS file share. Checks port 445, connection hold, and share accessibility.",
        "check_fn":     check_smb.run,
    },
    {
        "id":           "ssh",
        "name":         "SSH Server",
        "scp_name":     'SCP-SSH-006 "The Tunnel"',
        "host_env":     "SSH_HOST",
        "host_default": "10.0.0.22",
        "category":     "Remote Access",
        "os":           "Ubuntu",
        "description":  "OpenSSH server. Checks banner, key exchange, and authenticated command.",
        "check_fn":     check_ssh.run,
    },
    {
        "id":           "openvpn",
        "name":         "OpenVPN",
        "scp_name":     'SCP-VPN-007 "The Veil"',
        "host_env":     "OPENVPN_HOST",
        "host_default": "10.0.0.22",
        "category":     "VPN Services",
        "os":           "Ubuntu",
        "description":  "OpenVPN gateway. Checks port 1194 UDP reachability and management interface.",
        "check_fn":     check_openvpn.run,
    },
]

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

def init_db(db_path: str):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.executescript("""
        CREATE TABLE IF NOT EXISTS services (
            id               TEXT PRIMARY KEY,
            name             TEXT NOT NULL,
            scp_name         TEXT NOT NULL,
            host             TEXT NOT NULL,
            category         TEXT NOT NULL,
            os               TEXT NOT NULL,
            description      TEXT,
            points_per_check INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS checks (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            service_id   TEXT NOT NULL,
            timestamp    TEXT NOT NULL,
            success      INTEGER NOT NULL,
            uptime_ok    INTEGER NOT NULL,
            func_ok      INTEGER NOT NULL,
            uptime_pts   INTEGER NOT NULL DEFAULT 0,
            func_pts     INTEGER NOT NULL DEFAULT 0,
            points       INTEGER NOT NULL,
            latency_ms   REAL,
            message      TEXT,
            FOREIGN KEY (service_id) REFERENCES services(id)
        );

        CREATE TABLE IF NOT EXISTS scores (
            service_id      TEXT PRIMARY KEY,
            total_points    INTEGER NOT NULL DEFAULT 0,
            uptime_points   INTEGER NOT NULL DEFAULT 0,
            func_points     INTEGER NOT NULL DEFAULT 0,
            checks_run      INTEGER NOT NULL DEFAULT 0,
            checks_passed   INTEGER NOT NULL DEFAULT 0,
            last_check      TEXT,
            last_status     INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (service_id) REFERENCES services(id)
        );

        CREATE TABLE IF NOT EXISTS events (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp   TEXT NOT NULL,
            event_type  TEXT NOT NULL,
            service_id  TEXT,
            message     TEXT
        );

        CREATE TABLE IF NOT EXISTS daily_snapshots (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            snapshot_date TEXT NOT NULL,
            service_id    TEXT NOT NULL,
            total_points  INTEGER NOT NULL,
            uptime_points INTEGER NOT NULL,
            func_points   INTEGER NOT NULL,
            checks_run    INTEGER NOT NULL,
            checks_passed INTEGER NOT NULL,
            FOREIGN KEY (service_id) REFERENCES services(id)
        );
    """)
    conn.commit()
    conn.close()
    logger.info(f"Database initialized at {db_path}")


def upsert_services(db_path: str):
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    for svc in SERVICES:
        host = os.environ.get(svc["host_env"], svc["host_default"])
        c.execute("""
            INSERT INTO services (id, name, scp_name, host, category, os, description, points_per_check)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                host=excluded.host,
                points_per_check=excluded.points_per_check
        """, (svc["id"], svc["name"], svc["scp_name"], host,
              svc["category"], svc["os"], svc["description"], POINTS_PER_CHECK))

        c.execute("""
            INSERT OR IGNORE INTO scores
                (service_id, total_points, uptime_points, func_points, checks_run, checks_passed)
            VALUES (?, 0, 0, 0, 0, 0)
        """, (svc["id"],))

    conn.commit()
    conn.close()


def record_check(db_path: str, service_id: str, success: bool,
                 uptime_ok: bool, func_ok: bool,
                 uptime_pts: int, func_pts: int,
                 latency_ms: float, message: str):
    now = datetime.utcnow().isoformat()
    points = uptime_pts + func_pts
    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    c.execute("""
        INSERT INTO checks
            (service_id, timestamp, success, uptime_ok, func_ok, uptime_pts, func_pts, points, latency_ms, message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (service_id, now, int(success), int(uptime_ok), int(func_ok),
          uptime_pts, func_pts, points, latency_ms, message))

    c.execute("SELECT last_status FROM scores WHERE service_id=?", (service_id,))
    row = c.fetchone()
    prev_status = row[0] if row else None

    c.execute("""
        UPDATE scores SET
            total_points  = total_points + ?,
            uptime_points = uptime_points + ?,
            func_points   = func_points + ?,
            checks_run    = checks_run + 1,
            checks_passed = checks_passed + ?,
            last_check    = ?,
            last_status   = ?
        WHERE service_id = ?
    """, (points, uptime_pts, func_pts, int(success), now, int(success), service_id))

    if prev_status is not None and prev_status != int(success):
        event_type = "SERVICE_UP" if success else "SERVICE_DOWN"
        c.execute("""
            INSERT INTO events (timestamp, event_type, service_id, message)
            VALUES (?, ?, ?, ?)
        """, (now, event_type, service_id, message))

    conn.commit()
    conn.close()


def log_event(db_path: str, event_type: str, service_id: Optional[str], message: str):
    now = datetime.utcnow().isoformat()
    conn = sqlite3.connect(db_path)
    conn.execute("""
        INSERT INTO events (timestamp, event_type, service_id, message)
        VALUES (?, ?, ?, ?)
    """, (now, event_type, service_id, message))
    conn.commit()
    conn.close()


# ---------------------------------------------------------------------------
# Daily Reset
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Check Runner
# ---------------------------------------------------------------------------

def run_check(svc: dict):
    host = os.environ.get(svc["host_env"], svc["host_default"])
    logger.info(f"[CHECK] {svc['name']} @ {host}")

    start = time.time()
    try:
        result   = svc["check_fn"](host)
        latency  = (time.time() - start) * 1000

        uptime_ok = result.get("uptime", False)
        func_ok   = result.get("functional", False)
        message   = result.get("message", "")
        success   = uptime_ok and func_ok

        # 30pts for uptime, 30pts for functionality — independent
        uptime_pts = UPTIME_POINTS if uptime_ok else 0
        func_pts   = FUNC_POINTS   if func_ok   else 0
        points     = uptime_pts + func_pts

        if success:
            status_str = "PASS"
        elif uptime_ok and not func_ok:
            status_str = "PARTIAL"
        elif func_ok and not uptime_ok:
            status_str = "PARTIAL"
        else:
            status_str = "FAIL"

        logger.info(
            f"  [{status_str}] {svc['name']} | {points}pts "
            f"(up:{uptime_pts} fn:{func_pts}) | {latency:.0f}ms | {message}"
        )

    except Exception as e:
        latency = (time.time() - start) * 1000
        uptime_ok = func_ok = success = False
        uptime_pts = func_pts = points = 0
        message = f"Exception: {e}"
        logger.error(f"  [ERROR] {svc['name']}: {e}")

    record_check(DB_PATH, svc["id"], success, uptime_ok, func_ok,
                 uptime_pts, func_pts, latency, message)


# ---------------------------------------------------------------------------
# Main Loop
# ---------------------------------------------------------------------------

def scoring_loop():
    logger.info("=" * 60)
    logger.info("SCP FOUNDATION SCORING ENGINE - SITE GOLISANO")
    logger.info(f"Check interval : {CHECK_INTERVAL}s | Services: {len(SERVICES)}")
    logger.info(f"Points per check: {UPTIME_POINTS} uptime + {FUNC_POINTS} functional = {POINTS_PER_CHECK} max")
    logger.info("=" * 60)

    init_db(DB_PATH)
    upsert_services(DB_PATH)
    log_event(DB_PATH, "ENGINE_START", None,
              f"Scoring engine started. Interval={CHECK_INTERVAL}s. "
              f"{UPTIME_POINTS}pts uptime + {FUNC_POINTS}pts functional per service.")

    while True:
        round_start = time.time()
        threads = []
        for svc in SERVICES:
            t = threading.Thread(target=run_check, args=(svc,), daemon=True)
            threads.append(t)
            t.start()

        for t in threads:
            t.join(timeout=30)

        elapsed = time.time() - round_start
        sleep_time = max(0, CHECK_INTERVAL - elapsed)
        logger.info(f"Round complete in {elapsed:.1f}s. Next check in {sleep_time:.0f}s.\n")
        time.sleep(sleep_time)


if __name__ == "__main__":
    scoring_loop()