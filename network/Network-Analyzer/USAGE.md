How to use Network Analyzer

1. Make scripts executable

chmod +x netlog_watch.sh
chmod +x netlog_collect.py
chmod +x netlog_analyze.py
chmod +x netlog_plot.py

2. Start collector in background

./netlog_watch.sh start

3. Check if collector is running

./netlog_watch.sh status

4. Run analysis

./netlog_watch.sh analyze

5. Generate graphs

./netlog_watch.sh plot

6. Watch raw CSV live

./netlog_watch.sh tail

7. Stop collector

./netlog_watch.sh stop

Default files:

CSV log:
~/.local/share/netlog/netlog.csv

Speed graph:
~/.local/share/netlog/netlog_speed.png

Latency graph:
~/.local/share/netlog/netlog_latency.png

Collector output log:
~/.local/state/netlog/netlog_collect.out

Optional custom location:

NETLOG_DATA_DIR="$HOME/network-tests" ./netlog_watch.sh start

Or run collector manually once:

python3 netlog_collect.py --once

Run collector manually with custom options:

python3 netlog_collect.py --ping-target 8.8.8.8 --cycle-seconds 120
