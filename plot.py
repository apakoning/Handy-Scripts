import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("/home/apak/netlog.csv")

# Convert time safely
df["time"] = pd.to_datetime(df["time"], errors="coerce")

plt.figure(figsize=(15,6))

plt.plot(df["time"], df["download"], label="Download (Mbps)")
plt.plot(df["time"], df["upload"], label="Upload (Mbps)")

plt.legend()
plt.xlabel("Time")
plt.ylabel("Speed (Mbps)")
plt.title("Internet Performance Over Time")

plt.xticks(rotation=45)
plt.tight_layout()

plt.savefig("/home/apak/netlog.png")
plt.show()
