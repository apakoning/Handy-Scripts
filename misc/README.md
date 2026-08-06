# ✅ Modern CLI Tool Checker for RHEL-Compatible Systems

This project helps Linux users on RHEL-compatible systems (RHEL, Rocky, Alma, CentOS Stream) quickly check for and install modern CLI tools that improve productivity, safety, and usability.

---

## 📜 Purpose

Linux distributions like RHEL and its clones tend to be conservative with packages. This script helps identify whether useful modern command-line tools are available and assists with installing them if desired.

---

## ✅ "Still Worth It" Tools (Actively Maintained & Useful)

| Tool        | Replaces    | Status       | Purpose / Advantage                                        |
|-------------|-------------|--------------|-------------------------------------------------------------|
| `bat`       | `cat`       | 🟢 Excellent  | Syntax highlighting + Git integration                      |
| `fd`        | `find`      | 🟢 Excellent  | Easier syntax, very fast, respects `.gitignore`            |
| `ripgrep`   | `grep`      | 🟢 Excellent  | Fast, recursive, colorized, respects `.gitignore`          |
| `bottom`    | `top`/`htop`| 🟢 Excellent  | Clean TUI interface, real-time system metrics              |
| `fzf`       | *(none)*    | 🟢 Excellent  | TUI fuzzy finder, integrates with Bash/Zsh                 |
| `dust`      | `du`        | 🟢 Excellent  | Disk usage analyzer with bar graphs                        |
| `tldr`      | `man`       | 🟢 Excellent  | Short, community-contributed man-style examples            |
| `delta`     | `diff`      | 🟢 Excellent  | Syntax-colored diffs for Git or files                      |

---

## 🟡 Optional Tools

| Tool           | Replaces    | Status           | Notes                                                                 |
|----------------|-------------|------------------|-----------------------------------------------------------------------|
| `httpie`       | `curl`      | 🟡 Optional       | Clean, human-friendly syntax for REST APIs                           |
| `eza`          | `ls`        | 🟡 Optional       | Modern `ls` replacement (now preferred over `exa`)                   |
| `aria2`        | `wget`      | 🟡 Situational    | Powerful multi-source downloader                                     |
| `curlie`       | `curl`      | 🟡 Fun UI         | Simpler `curl` UI, but redundant if you use `httpie`                 |

---

## ❌ Outdated / Superseded / Not Recommended

| Tool           | Replaces    | Notes                                                                 |
|----------------|-------------|-----------------------------------------------------------------------|
| `chkrootkit`   | *(none)*    | ❌ Obsolete. Use `rkhunter`, `Lynis`, or `osquery` instead.           |
| `hashdeep`     | *(none)*    | ❌ Niche and unmaintained. Use `sha256sum`, `integrit`, or `aide`.    |
| `exa`          | `ls`        | ❌ Deprecated. Switch to `eza`.                                       |
| `trash`        | `rm`        | ❌ Desktop environments already handle trash. Rarely useful on servers.|

---

## 🔄 Modern Alternatives

- `exa` → **`eza`**
- `chkrootkit` → **`rkhunter`, `Lynis`, or `osquery`**
- `hashdeep` → **`sha256sum`, `integrit`, or `aide`**
- `curlie` → **just use `httpie` if installed**

---

## Use

This script is useful for:
- Setting up new systems quickly
- Checking for missing developer-friendly tools
- Streamlining your terminal setup

---

## 🚀 To Auto-Install All "Still Worth It" Tools

You can use the companion installer script: `install_modern_cli_tools.sh`

```bash
chmod +x install_modern_cli_tools.sh
sudo ./install_modern_cli_tools.sh
```

**This script:**

- Enables CodeReady Builder  
- Installs EPEL  
- Installs `bat`, `fd`, `ripgrep`, `bottom`, `fzf`, `dust`, `tldr`, and `delta`  
- Creates symlinks if necessary (`batcat` → `bat`, `fdfind` → `fd`)  
- Updates the `tldr` cache  
