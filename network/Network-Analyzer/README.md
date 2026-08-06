## Requirements

- Linux
- Python 3.9 or newer
- `ping`
- Official Ookla Speedtest CLI

Verify that the Ookla CLI is installed:

```bash
speedtest --version
```

If the command prints the Speedtest version, you're ready to use Network Analyzer.

## Install Python dependencies

```bash
python3 -m pip install -r requirements.txt
```

## Quick Start

Make the scripts executable:

```bash
chmod +x netlog_watch.sh netlog_collect.py netlog_analyze.py netlog_plot.py
```

Start the collector:

```bash
./netlog_watch.sh start
```

Check its status:

```bash
./netlog_watch.sh status
```

Analyze the collected data:

```bash
./netlog_watch.sh analyze
```

Generate graphs:

```bash
./netlog_watch.sh plot
```

Stop the collector:

```bash
./netlog_watch.sh stop
```

## Output files

By default the project stores its data under:

```
~/.local/share/netlog/
```

Generated files include:

- `netlog.csv`
- `netlog_speed.png`
- `netlog_latency.png`

Runtime state is stored under:

```
~/.local/state/netlog/
```

including:

- `netlog_collect.out`
- `netlog_collect.pid`

## Project layout

```
netlog_collect.py    Collects network measurements
netlog_analyze.py    Analyzes collected measurements
netlog_plot.py       Generates graphs
netlog_watch.sh      Starts and manages the collector
USAGE.md             Additional usage examples
```

## License

Released under the MIT License.
