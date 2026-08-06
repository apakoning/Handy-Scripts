# =========================================================
# NETLOG PRO — Internet Performance Monitoring Script
# =========================================================
#
# WHAT THIS DOES:
# - Logs network performance every minute
# - Runs continuous ping sampling (captures spikes + jitter)
# - Runs speedtest (download / upload)
# - Stores clean CSV data
# - Generates graph every 10 minutes
#
# OUTPUT:
# /home/apak/netlog.csv  -> raw data
# /home/apak/netlog.png  -> graph
#
# USAGE:
# python3 netlog.py
# Let it run at least 24 hours for meaningful data
#
# =========================================================

import os
import csv
import time
import subprocess
from datetime import datetime

import pandas as pd
import matplotlib.pyplot as plt


# -------------------------------
# FILE LOCATIONS
# -------------------------------
LOG_FILE = "/home/apak/netlog.csv"
GRAPH_FILE = "/home/apak/netlog.png"

counter = 0


# -------------------------------
# RESET OLD DATA (fresh start)
# -------------------------------
for f in [LOG_FILE, GRAPH_FILE]:
    if os.path.exists(f):
        os.remove(f)

print("Fresh start. Old logs removed.")


# -------------------------------
# ENSURE CSV HEADER EXISTS
# -------------------------------
def ensure_log():
    if not os.path.exists(LOG_FILE):
        with open(LOG_FILE, "w", newline="") as f:
            writer = csv.writer(f)

            # CSV header
            writer.writerow([
                "time",
                "phase",
                "speedtest_ping",
                "latency_min",
                "latency_avg",
                "latency_max",
                "jitter",
                "download",
                "upload"
            ])


# -------------------------------
# RUN SPEEDTEST
# -------------------------------
def run_speedtest():
    """
    Runs speedtest-cli and extracts:
    ping / download / upload

    NOTE:
    - This tests real-world throughput
    - Not pure bandwidth (for that use iperf3)
    """
    try:
        out = subprocess.check_output(
            ["speedtest-cli", "--simple"],
            timeout=30
        ).decode()

        ping, down, up = "0", "0", "0"

        for line in out.splitlines():
            if "Ping:" in line:
                ping = line.split()[1]
            elif "Download:" in line:
                down = line.split()[1]
            elif "Upload:" in line:
                up = line.split()[1]

        return ping, down, up

    except Exception:
        # Return 0 if test fails (will be filtered later)
        return "0", "0", "0"


# -------------------------------
# RUN PING WINDOW (JITTER + SPIKES)
# -------------------------------
def run_ping_window():
    """
    Runs continuous ping for ~20 seconds:
    - Captures latency min / avg / max
    - Calculates jitter (stability)

    JITTER = average change between successive pings
    """
    try:
        out = subprocess.check_output(
            ["ping", "-i", "0.2", "-w", "20", "1.1.1.1"],
            timeout=25
        ).decode()

        rtts = []

        for line in out.splitlines():
            if "time=" in line:
                try:
                    rtts.append(float(line.split("time=")[1].split()[0]))
                except:
                    pass

        if not rtts:
            return "0", "0", "0", "0"

        latency_min = min(rtts)
        latency_avg = sum(rtts) / len(rtts)
        latency_max = max(rtts)

        # Jitter calculation
        jitter = sum(
            abs(rtts[i] - rtts[i - 1]) for i in range(1, len(rtts))
        ) / max(1, len(rtts) - 1)

        return (
            f"{latency_min:.2f}",
            f"{latency_avg:.2f}",
            f"{latency_max:.2f}",
            f"{jitter:.2f}"
        )

    except Exception:
        return "0", "0", "0", "0"


# -------------------------------
# LOG ONE MEASUREMENT CYCLE
# -------------------------------
def log():
    """
    One full measurement cycle:
    1. Ping sampling (captures spikes/jitter)
    2. Speedtest (throughput)
    3. Write to CSV
    """
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    lat_min, lat_avg, lat_max, jitter = run_ping_window()
    st_ping, down, up = run_speedtest()

    with open(LOG_FILE, "a", newline="") as f:
        csv.writer(f).writerow([
            timestamp,
            "NORMAL",   # phase (can be expanded later)
            st_ping,
            lat_min,
            lat_avg,
            lat_max,
            jitter,
            down,
            up
        ])

    print(
        f"{timestamp} | down={down} up={up} "
        f"| lat={lat_avg} | jitter={jitter}"
    )


# -------------------------------
# GENERATE GRAPH
# -------------------------------
def plot():
    """
    Reads CSV and generates graph.

    IMPORTANT:
    - Filters out failed measurements (0 values)
    - Sorts time (prevents broken lines)
    - Handles bad data safely
    """
    try:
        df = pd.read_csv(LOG_FILE)

        if df.empty:
            return

        # Convert time safely
        df["time"] = pd.to_datetime(df["time"], errors="coerce")

        # Convert numeric columns
        for col in df.columns[2:]:
            df[col] = pd.to_numeric(df[col], errors="coerce")

        # REMOVE BAD DATA (fixes fake drops to zero)
        df = df[(df["download"] > 0) & (df["upload"] > 0)]

        # Clean dataset
        df = df.dropna(subset=["time"])
        df = df.sort_values("time")

        if df.empty:
            return

        plt.figure(figsize=(15, 6))

        # Throughput
        plt.plot(df["time"], df["download"], label="Download (Mbps)")
        plt.plot(df["time"], df["upload"], label="Upload (Mbps)")

        # Stability metrics
        plt.plot(df["time"], df["latency_avg"], label="Latency Avg (ms)")
        plt.plot(df["time"], df["jitter"], label="Jitter (ms)")

        plt.legend()
        plt.xlabel("Time")
        plt.ylabel("Speed / Latency")
        plt.title("Internet Performance + Stability Over Time")

        plt.xticks(rotation=45)
        plt.tight_layout()

        plt.savefig(GRAPH_FILE)
        plt.close()

    except Exception as e:
        print("Plot error:", e)


# =========================================================
# MAIN LOOP
# =========================================================

ensure_log()

while True:
    cycle_start = time.time()

    log()
    counter += 1

    # Update graph every 10 minutes
    if counter % 10 == 0:
        plot()

    # Keep cycle at ~60 seconds
    elapsed = time.time() - cycle_start
    time.sleep(max(1, int(60 - elapsed)))
