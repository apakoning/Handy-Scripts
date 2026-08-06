#!/usr/bin/env bash

# No strict-mode booby traps. We want the UI to stay alive.
set -o pipefail

COMFY_DIR="$HOME/ComfyUI"
COMFY_URL="http://127.0.0.1:8188"

OLLAMA_PORT="11434"
OLLAMA_URL="http://127.0.0.1:${OLLAMA_PORT}"

OPENWEBUI_VENV="$HOME/venvs/openwebui"
OPENWEBUI_PORT="3000"
OPENWEBUI_URL="http://127.0.0.1:${OPENWEBUI_PORT}"

LOG_DIR="$HOME/.local/state/ai-control-panel"
COMFY_LOG="$LOG_DIR/comfyui.log"
OLLAMA_LOG="$LOG_DIR/ollama.log"
OPENWEBUI_LOG="$LOG_DIR/openwebui.log"
mkdir -p "$LOG_DIR"

have_cmd() { command -v "$1" >/dev/null 2>&1; }
ts() { date +"%F %T"; }

# ---------------- Status checks ----------------
is_comfy_running() { pgrep -af "python.*main\.py" >/dev/null 2>&1; }
is_openwebui_running() { pgrep -af "open-webui.*serve" >/dev/null 2>&1; }

# Ollama: check either process argv or port listener
is_ollama_running() {
  pgrep -af "ollama.*serve" >/dev/null 2>&1 && return 0
  if have_cmd ss; then
    ss -ltnp 2>/dev/null | grep -qE "(:${OLLAMA_PORT})" && return 0
  fi
  return 1
}

# ---------------- Browser helpers (Flatpak-first) ----------------
flatpak_has() {
  have_cmd flatpak || return 1
  flatpak info "$1" >/dev/null 2>&1
}

open_url() {
  url="$1"

  # Prefer Brave Flatpak
  if flatpak_has com.brave.Browser; then
    flatpak run com.brave.Browser --new-window "$url" >/dev/null 2>&1 &
    return 0
  fi

  # Next: Chrome/Chromium Flatpaks
  if flatpak_has com.google.Chrome; then
    flatpak run com.google.Chrome --new-window "$url" >/dev/null 2>&1 &
    return 0
  fi
  if flatpak_has org.chromium.Chromium; then
    flatpak run org.chromium.Chromium --new-window "$url" >/dev/null 2>&1 &
    return 0
  fi

  # Native fallbacks
  for b in brave-browser brave google-chrome chromium chromium-browser; do
    if have_cmd "$b"; then
      "$b" --new-window "$url" >/dev/null 2>&1 &
      return 0
    fi
  done

  # Default browser
  xdg-open "$url" >/dev/null 2>&1 &
}

open_openwebui() { open_url "$OPENWEBUI_URL"; }
open_comfyui() { open_url "$COMFY_URL"; }

# ---------------- ComfyUI ----------------
start_comfy() {
  if is_comfy_running; then
    echo "ComfyUI already running: $COMFY_URL"
    return 0
  fi
  if [ ! -d "$COMFY_DIR" ]; then
    echo "ERROR: ComfyUI dir not found: $COMFY_DIR"
    return 1
  fi
  echo "[$(ts)] Starting ComfyUI..." | tee -a "$COMFY_LOG"
  ( cd "$COMFY_DIR" && ./run.sh ) >>"$COMFY_LOG" 2>&1 &
  sleep 1
  echo "ComfyUI started (or starting). URL: $COMFY_URL"
  echo "Log: $COMFY_LOG"
}

stop_comfy() {
  echo "Stopping ComfyUI..."
  pkill -f "python.*main\.py" >/dev/null 2>&1 || true
  sleep 1
  if is_comfy_running; then
    echo "ComfyUI still running:"
    pgrep -af "python.*main\.py" || true
    return 1
  fi
  echo "ComfyUI stopped."
}

# ---------------- Ollama ----------------
start_ollama() {
  if is_ollama_running; then
    echo "Ollama already running: $OLLAMA_URL"
    return 0
  fi
  if ! have_cmd ollama; then
    echo "ERROR: ollama not found in PATH."
    return 1
  fi
  echo "[$(ts)] Starting Ollama..." | tee -a "$OLLAMA_LOG"
  ( ollama serve ) >>"$OLLAMA_LOG" 2>&1 &
  sleep 1
  echo "Ollama started (or starting). URL: $OLLAMA_URL"
  echo "Log: $OLLAMA_LOG"
}

stop_ollama() {
  echo "Stopping Ollama..."

  # Stop systemd user service if it exists (prevents auto-restart)
  if have_cmd systemctl; then
    systemctl --user is-active ollama.service >/dev/null 2>&1 && {
      systemctl --user stop ollama.service >/dev/null 2>&1 || true
    }
  fi

  # Try to stop via CLI if available (ignore failure)
  if have_cmd ollama; then
    ollama stop all >/dev/null 2>&1 || true
  fi

  # Kill by argv match
  pkill -f "ollama.*serve" >/dev/null 2>&1 || true
  sleep 1

  # If still listening, kill PID holding the port
  if have_cmd ss; then
    pids="$(ss -ltnp 2>/dev/null | sed -n "s/.*:${OLLAMA_PORT} .*pid=\\([0-9]\\+\\).*/\\1/p" | sort -u)"
    if [ -n "$pids" ]; then
      echo "Killing PID(s) holding port ${OLLAMA_PORT}: $pids"
      kill $pids >/dev/null 2>&1 || true
      sleep 1
      kill -9 $pids >/dev/null 2>&1 || true
    fi
  fi

  sleep 1
  if is_ollama_running; then
    echo "Ollama STILL running. Matches:"
    pgrep -af ollama || true
    have_cmd ss && ss -ltnp 2>/dev/null | grep ":${OLLAMA_PORT}" || true
    return 1
  fi

  echo "Ollama stopped."
}

# ---------------- Open WebUI (SQLite auto-fix) ----------------
ensure_openwebui_env() {
  if [ ! -d "$OPENWEBUI_VENV" ]; then
    echo "ERROR: Open WebUI venv not found: $OPENWEBUI_VENV"
    return 1
  fi

  # shellcheck disable=SC1090
  . "$OPENWEBUI_VENV/bin/activate"

  command -v open-webui >/dev/null 2>&1 || {
    echo "Installing open-webui into venv..."
    pip install -U pip >/dev/null 2>&1 || true
    pip install -U open-webui >/dev/null 2>&1 || true
  }

  python -c "import pysqlite3" >/dev/null 2>&1 || {
    echo "Installing pysqlite3-binary into venv..."
    pip install -U pysqlite3-binary >/dev/null 2>&1 || true
  }

  sitepkg="$(python -c 'import site; print(site.getsitepackages()[0])' 2>/dev/null)"
  if [ -n "$sitepkg" ]; then
    mkdir -p "$sitepkg"
    cat > "$sitepkg/sitecustomize.py" <<'PYEOF'
import sys
try:
    import pysqlite3
    sys.modules["sqlite3"] = pysqlite3
except Exception:
    pass
PYEOF
  fi

  sqlite_ver="$(python -c 'import sqlite3; print(sqlite3.sqlite_version)' 2>/dev/null || echo "unknown")"
  echo "Open WebUI env ready. sqlite3=$sqlite_ver"
  return 0
}

start_openwebui() {
  if is_openwebui_running; then
    echo "Open WebUI already running: $OPENWEBUI_URL"
    return 0
  fi

  ensure_openwebui_env || return 1

  echo "[$(ts)] Starting Open WebUI..." | tee -a "$OPENWEBUI_LOG"
  ( open-webui serve --host 127.0.0.1 --port "$OPENWEBUI_PORT" ) >>"$OPENWEBUI_LOG" 2>&1 &
  sleep 1

  if is_openwebui_running; then
    echo "Open WebUI started. URL: $OPENWEBUI_URL"
    echo "Log: $OPENWEBUI_LOG"
    return 0
  fi

  echo "Open WebUI did not start. Check log: $OPENWEBUI_LOG"
  return 1
}

stop_openwebui() {
  echo "Stopping Open WebUI..."
  pkill -f "open-webui.*serve" >/dev/null 2>&1 || true
  sleep 1
  if is_openwebui_running; then
    echo "Open WebUI still running:"
    pgrep -af "open-webui.*serve" || true
    return 1
  fi
  echo "Open WebUI stopped."
}

# ---------------- Logs & Status ----------------
view_logs() {
  echo
  echo "Log viewers"
  echo "1) Tail ComfyUI log"
  echo "2) Tail Ollama log"
  echo "3) Tail Open WebUI log"
  echo "4) Tail ALL (tabs)"
  echo "0) Back"
  read -r -p "Choose [0-4]: " c
  case "$c" in
    1) gnome-terminal --title="ComfyUI log" -- bash -lc "tail -n 200 -f '$COMFY_LOG'" >/dev/null 2>&1 || true ;;
    2) gnome-terminal --title="Ollama log" -- bash -lc "tail -n 200 -f '$OLLAMA_LOG'" >/dev/null 2>&1 || true ;;
    3) gnome-terminal --title="Open WebUI log" -- bash -lc "tail -n 200 -f '$OPENWEBUI_LOG'" >/dev/null 2>&1 || true ;;
    4) gnome-terminal \
         --tab --title="ComfyUI log" -- bash -lc "tail -n 200 -f '$COMFY_LOG'" \
         --tab --title="Ollama log" -- bash -lc "tail -n 200 -f '$OLLAMA_LOG'" \
         --tab --title="Open WebUI log" -- bash -lc "tail -n 200 -f '$OPENWEBUI_LOG'" \
         >/dev/null 2>&1 || true ;;
    0) return 0 ;;
    *) echo "Invalid choice." ;;
  esac
}

status_once() {
  echo "ComfyUI    : $(is_comfy_running && echo RUNNING || echo stopped)  ($COMFY_URL)"
  echo "Ollama     : $(is_ollama_running && echo RUNNING || echo stopped)  ($OLLAMA_URL)"
  echo "Open WebUI : $(is_openwebui_running && echo RUNNING || echo stopped)  ($OPENWEBUI_URL)"
}

status_realtime() {
  echo "Real-time status (press q + Enter to quit)"
  while true; do
    clear || true
    echo "STATUS  ($(ts))"
    echo "----------------------------------------"
    status_once
    echo "----------------------------------------"
    read -r -t 1 -p "q=quit > " key || true
    [ "${key:-}" = "q" ] && break
  done
}

# ---------------- Main menu ----------------
while true; do
  echo
  echo "AI Control Panel"
  echo "1)  Start ComfyUI"
  echo "2)  Stop  ComfyUI"
  echo "3)  Start Ollama"
  echo "4)  Stop  Ollama"
  echo "5)  Start Open WebUI"
  echo "6)  Stop  Open WebUI"
  echo "7)  Start ALL"
  echo "8)  Stop  ALL"
  echo "9)  Status (once)"
  echo "10) Status (real-time)"
  echo "14) Log viewers"
  echo "15) Open Open WebUI in Brave/Chrome"
  echo "16) Open ComfyUI in Brave/Chrome"
  echo "0)  Exit"
  echo
  read -r -p "Choose: " choice

  case "$choice" in
    1) start_comfy ;;
    2) stop_comfy ;;
    3) start_ollama ;;
    4) stop_ollama ;;
    5) start_openwebui ;;
    6) stop_openwebui ;;
    7) start_comfy; start_ollama; start_openwebui ;;
    8) stop_comfy; stop_openwebui; stop_ollama ;;
    9) status_once ;;
    10) status_realtime ;;
    14) view_logs ;;
    15) open_openwebui ;;
    16) open_comfyui ;;
    0) echo "Bye."; exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
