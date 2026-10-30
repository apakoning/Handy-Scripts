# Handy-Scripts

[![Checks](https://github.com/apakoning/Handy-Scripts/actions/workflows/checks.yml/badge.svg)](https://github.com/apakoning/Handy-Scripts/actions/workflows/checks.yml)

Practical Bash utilities from Linux workstation administration, infrastructure troubleshooting and local automation. The collection includes focused tools and documented, environment-specific helpers.

## Start here

```bash
git clone https://github.com/apakoning/Handy-Scripts.git
cd Handy-Scripts
bash diagnostics/check-cli-tools-2.sh
```

This first example only checks installed commands. There is no bulk installer for the collection. Read a script and its catalogue entry before running it; use `sudo` only where the individual tool requires it.

## Script catalogue

“Inspect” means reporting rather than deliberate configuration changes; commands can still make network requests or update local caches. “Local setup” entries retain machine-specific assumptions and are not general-purpose provisioning products.

| Tool | Purpose / requirements | Behaviour and scope |
| --- | --- | --- |
| [CLI checklist](diagnostics/check-cli-tools-2.sh) | Bash command-presence report | Inspect; does not validate tool configuration |
| [Verbose CLI checklist](diagnostics/check_cli_tools.sh) | Earlier verbose variant | Inspect; retained for comparison |
| [Cloud checklist](cloud/check-system-2.sh) | Cloud/container/dev tooling presence and package suggestions | Inspect; Bash, RHEL-oriented suggestions |
| [Original cloud checklist](cloud/check-system.sh), [expanded variant](cloud/check-system-expanded.sh) | Alternative checklist output and tool lists | Inspect; historic variants, not installers |
| [Multi-cloud checklist](cloud/multi-cloud-post-install-check.md) | Manual CLI/account/local-cluster examples | Documentation; account and cluster actions are explicit manual steps |
| [AI Control Panel](ai/AI-Control-Panel-2.sh) | Local Ollama, Open WebUI and ComfyUI controls | Starts/stops local services/processes; review paths and ports first |
| [Mounted-drive backup](backup/backup4tb.sh) | rsync mirror; `rsync`, `mountpoint`, `realpath` | Dry run by default; `--apply` copies and deletes destination files; both paths must be mounted |
| [DNS timing](network/dns-benchmark) | Five queries per resolver; `dig` | Network queries; optional domain and server arguments |
| [USB status](misc/usb-status.sh) | USB devices, links and USB-C roles; `usbutils` | Inspect; unavailable sysfs fields can be empty |
| [Find a PDF](misc/find_pdf_with_progress.sh) | Search mounted filesystems for a supplied filename | Inspect; potentially long-running scan; `findmnt`, `find`, `awk` |
| [DNF signature diagnostic](system/check-dnf-repo-signatures.sh) | Inspect enabled repositories for signature-related messages | Calls `sudo dnf makecache`; updates repository cache; not a complete signature audit |
| [Repository mirror helper](system/mirror-important-zip-the-rest.sh) | Download/mirror selected upstream source repositories | Writes downloads under the configured storage path; potentially large transfers |
| [Modern CLI installer](system/setup/install_modern_cli_tools.sh) | Install selected tools and configure repositories | Privileged local setup; RHEL-oriented package/repository assumptions need review |
| [Exclusive audio helper](audio/audio-hifi.sh) | Detect Khadas Tea and stop desktop audio for direct ALSA playback | Changes user audio session; `--restore` starts PipeWire services again |
| [DaVinci Resolve helper](video/davinci_resolve_rhel95_setup.sh) | RHEL 9-era dependencies and optional NVIDIA setup | Start with `--help` / `--check-only`; other modes install packages or repositories |
| [NVIDIA patch copy](video/nvidia-patch.sh) | Retained third-party NVENC patch | Modifies driver libraries; see [provenance](THIRD_PARTY.md); not a maintained portfolio tool |

The old `system/bulletproof.sh` path forwards to the more accurately named DNF diagnostic.

## Standalone projects

- [Linux System Inventory](https://github.com/apakoning/linux-system-inventory): hardware, software, networking and service reports. This replaces the divergent copy previously in `diagnostics/`.
- [Network Analyzer](https://github.com/apakoning/network-analyzer): CSV network collection, analysis and graphs. The old folder now contains a migration pointer.
- [Termcap Auto Wizard](https://github.com/apakoning/TermcapAutoWizard): terminal-aware manual-page colour settings.

## Examples

```bash
# Preview a mounted-drive mirror, without copying or deleting:
bash backup/backup4tb.sh --dry-run

# Time DNS queries against explicitly selected resolvers:
bash network/dns-benchmark example.com 1.1.1.1 9.9.9.9

# Search for a filename you provide:
bash misc/find_pdf_with_progress.sh 'example.pdf'
```

Backup defaults are `/mnt/HDD4TB` and `/mnt/Backup4TB`; override with `BACKUP_SOURCE` and `BACKUP_DESTINATION`. Use `--apply` only after inspecting the preview.

## Historical work and validation

[archive/](archive/README.md) preserves superseded network prototypes, old privileged setup experiments and personal utilities. Those scripts are not part of the maintained tool set.

GitHub Actions checks Bash syntax and Python compilation, and regression tests verify backup mount/deletion guards. It does not run installers, patch drivers, change audio, contact cloud accounts or certify compatibility with a particular workstation.

```bash
python3 -m unittest discover -s tests -v
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for change guidelines and [THIRD_PARTY.md](THIRD_PARTY.md) for licensing scope. Maintained by [Alain A.P. Koningverdraag](https://github.com/apakoning).
