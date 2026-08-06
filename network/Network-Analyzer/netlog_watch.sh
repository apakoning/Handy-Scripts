#!/usr/bin/env bash
# =========================================================
# netlog_watch.sh
# =========================================================
#
# PURPOSE
# -------
# Helper script for managing the netlog tools.
#
# USAGE
# -----
#   ./netlog_watch.sh start
#   ./netlog_watch.sh stop
#   ./netlog_watch.sh status
#   ./netlog_watch.sh analyze
#   ./netlog_watch.sh plot
#   ./netlog_watch.sh tail
# =========================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COLLECT_SCRIPT="$SCRIPT_DIR/netlog_collect.py"
ANALYZE_SCRIPT="$SCRIPT_DIR/netlog_analyze.py"
PLOT_SCRIPT="$SCRIPT_DIR/netlog_plot.py"

DATA_DIR="${NETLOG_DATA_DIR:-$HOME/.local/share/netlog}"
STATE_DIR="${NETLOG_STATE_DIR:-$HOME/.local/state/netlog}"

LOG_FILE="${NETLOG_LOG_FILE:-$DATA_DIR/netlog.csv}"
PID_FILE="$STATE_DIR/netlog_collect.pid"
LOG_STDOUT="$STATE_DIR/netlog_collect.out"

mkdir -p "$DATA_DIR" "$STATE_DIR"


start_collector() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Collector already running with PID $(cat "$PID_FILE")"
        exit 0
    fi

    nohup python3 "$COLLECT_SCRIPT" --log-file "$LOG_FILE" >> "$LOG_STDOUT" 2>&1 &
    echo $! > "$PID_FILE"

    echo "Collector started with PID $(cat "$PID_FILE")"
    echo "CSV log: $LOG_FILE"
    echo "Output log: $LOG_STDOUT"
}


stop_collector() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "No PID file found. Collector may not be running."
        exit 0
    fi

    PID="$(cat "$PID_FILE")"

    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "Collector stopped."
    else
        echo "Process not running, removing stale PID file."
    fi

    rm -f "$PID_FILE"
}


status_collector() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Collector is running with PID $(cat "$PID_FILE")"
        echo "CSV log: $LOG_FILE"
        echo "Output log: $LOG_STDOUT"
    else
        echo "Collector is not running."
    fi
}


run_analysis() {
    python3 "$ANALYZE_SCRIPT" --log-file "$LOG_FILE"
}


run_plot() {
    python3 "$PLOT_SCRIPT" --log-file "$LOG_FILE"
}


tail_log() {
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Log file does not exist yet: $LOG_FILE"
        exit 1
    fi

    tail -f "$LOG_FILE"
}


show_usage() {
    echo "Usage: $0 {start|stop|status|analyze|plot|tail}"
}


case "${1:-}" in
    start)
        start_collector
        ;;
    stop)
        stop_collector
        ;;
    status)
        status_collector
        ;;
    analyze)
        run_analysis
        ;;
    plot)
        run_plot
        ;;
    tail)
        tail_log
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
