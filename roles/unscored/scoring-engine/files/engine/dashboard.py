"""
SCP Foundation Scoring Dashboard
Site Golisano - Containment Status Monitor
"""

import sqlite3
import os
from datetime import datetime, timedelta
from flask import Flask, render_template, jsonify, g

app = Flask(__name__,
            template_folder=os.path.join(os.path.dirname(__file__), '..', 'templates'))

DB_PATH           = os.environ.get("SCORING_DB", "/opt/scp-scoring/scoring.db")
MAX_HISTORY_HOURS = int(os.environ.get("HISTORY_HOURS", "4"))


def get_db():
    db = getattr(g, "_database", None)
    if db is None:
        db = g._database = sqlite3.connect(DB_PATH)
        db.row_factory = sqlite3.Row
    return db


@app.teardown_appcontext
def close_db(exception):
    db = getattr(g, "_database", None)
    if db is not None:
        db.close()


def query_db(query, args=(), one=False):
    cur = get_db().execute(query, args)
    rv  = cur.fetchall()
    cur.close()
    return (rv[0] if rv else None) if one else rv


# ---------------------------------------------------------------------------
# API Endpoints
# ---------------------------------------------------------------------------

@app.route("/api/scores")
def api_scores():
    rows = query_db("""
        SELECT sc.service_id, sc.total_points, sc.uptime_points, sc.func_points,
               sc.checks_run, sc.checks_passed, sc.last_check, sc.last_status,
               sv.name, sv.scp_name, sv.host, sv.category, sv.os,
               sv.description, sv.points_per_check
        FROM scores sc
        JOIN services sv ON sc.service_id = sv.id
        ORDER BY sv.name
    """)
    result = []
    for r in rows:
        uptime_pct = round((r["checks_passed"] / r["checks_run"] * 100), 1) if r["checks_run"] > 0 else 0
        result.append({
            "id":             r["service_id"],
            "name":           r["name"],
            "scp_name":       r["scp_name"],
            "host":           r["host"],
            "category":       r["category"],
            "os":             r["os"],
            "description":    r["description"],
            "points_per_check": r["points_per_check"],
            "total_points":   r["total_points"],
            "uptime_points":  r["uptime_points"],
            "func_points":    r["func_points"],
            "checks_run":     r["checks_run"],
            "checks_passed":  r["checks_passed"],
            "uptime_pct":     uptime_pct,
            "last_check":     r["last_check"],
            "status":         r["last_status"],
        })
    return jsonify(result)


@app.route("/api/total")
def api_total():
    row = query_db("""
        SELECT SUM(total_points)  as pts,
               SUM(uptime_points) as up_pts,
               SUM(func_points)   as fn_pts,
               SUM(checks_run)    as runs,
               SUM(checks_passed) as passes
        FROM scores
    """, one=True)
    return jsonify({
        "total_points":   row["pts"]     or 0,
        "uptime_points":  row["up_pts"]  or 0,
        "func_points":    row["fn_pts"]  or 0,
        "checks_run":     row["runs"]    or 0,
        "checks_passed":  row["passes"]  or 0,
    })


@app.route("/api/events")
def api_events():
    cutoff = (datetime.utcnow() - timedelta(hours=MAX_HISTORY_HOURS)).isoformat()
    rows = query_db("""
        SELECT e.id, e.timestamp, e.event_type, e.service_id, e.message,
               sv.name as service_name
        FROM events e
        LEFT JOIN services sv ON e.service_id = sv.id
        WHERE e.timestamp >= ?
        ORDER BY e.timestamp DESC
        LIMIT 50
    """, (cutoff,))
    return jsonify([dict(r) for r in rows])


@app.route("/api/history/<service_id>")
def api_history(service_id):
    cutoff = (datetime.utcnow() - timedelta(hours=MAX_HISTORY_HOURS)).isoformat()
    rows = query_db("""
        SELECT timestamp, success, uptime_ok, func_ok,
               uptime_pts, func_pts, points, latency_ms, message
        FROM checks
        WHERE service_id = ? AND timestamp >= ?
        ORDER BY timestamp DESC
        LIMIT 60
    """, (service_id, cutoff))
    return jsonify([dict(r) for r in rows])


@app.route("/api/snapshots")
def api_snapshots():
    """Returns all daily snapshots for manual tally review."""
    rows = query_db("""
        SELECT ds.snapshot_date, ds.service_id, ds.total_points,
               ds.uptime_points, ds.func_points,
               ds.checks_run, ds.checks_passed,
               sv.name as service_name
        FROM daily_snapshots ds
        JOIN services sv ON ds.service_id = sv.id
        ORDER BY ds.snapshot_date DESC, sv.name
    """)
    return jsonify([dict(r) for r in rows])


@app.route("/api/snapshots/<date>")
def api_snapshot_day(date):
    """Returns snapshot for a specific date (YYYY-MM-DD)."""
    rows = query_db("""
        SELECT ds.snapshot_date, ds.service_id, ds.total_points,
               ds.uptime_points, ds.func_points,
               ds.checks_run, ds.checks_passed,
               sv.name as service_name
        FROM daily_snapshots ds
        JOIN services sv ON ds.service_id = sv.id
        WHERE ds.snapshot_date = ?
        ORDER BY sv.name
    """, (date,))
    return jsonify([dict(r) for r in rows])


# ---------------------------------------------------------------------------
# Manual reset endpoint (Grey team use only)
# ---------------------------------------------------------------------------

@app.route("/api/admin/reset", methods=["POST"])
def api_manual_reset():
    """
    Manually trigger a snapshot + reset outside of midnight schedule.
    Usage: curl -X POST http://10.0.0.40:5000/api/admin/reset
    """
    try:
        today = datetime.utcnow().strftime("%Y-%m-%d")
        db = get_db()

        # Snapshot current scores
        rows = db.execute(
            "SELECT service_id, total_points, uptime_points, func_points, checks_run, checks_passed FROM scores"
        ).fetchall()

        for row in rows:
            db.execute("""
                INSERT INTO daily_snapshots
                    (snapshot_date, service_id, total_points, uptime_points, func_points, checks_run, checks_passed)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (today, row["service_id"], row["total_points"], row["uptime_points"],
                  row["func_points"], row["checks_run"], row["checks_passed"]))

        # Reset live scores to zero
        db.execute("""
            UPDATE scores SET
                total_points  = 0,
                uptime_points = 0,
                func_points   = 0,
                checks_run    = 0,
                checks_passed = 0,
                last_status   = 0
        """)

        db.execute("""
            INSERT INTO events (timestamp, event_type, service_id, message)
            VALUES (?, 'DAY_RESET', NULL, ?)
        """, (datetime.utcnow().isoformat(), f"Manual reset by Overseers. Snapshot saved for {today}."))

        db.commit()
        return jsonify({"status": "ok", "message": f"Scores snapshotted for {today} and reset to zero."})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


# ---------------------------------------------------------------------------
# Main Dashboard
# ---------------------------------------------------------------------------

@app.route("/")
def index():
    return render_template("dashboard.html")


if __name__ == "__main__":
    host  = os.environ.get("DASHBOARD_HOST", "0.0.0.0")
    port  = int(os.environ.get("DASHBOARD_PORT", "5000"))
    debug = os.environ.get("FLASK_DEBUG", "0") == "1"
    app.run(host=host, port=port, debug=debug)