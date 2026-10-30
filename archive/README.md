# Historical experiments

Retained for reference and provenance; these scripts are not part of the maintained tool set. Syntax checks do not certify that they work on a current system.

| Path | Reason retained here |
| --- | --- |
| `security/` | Historical reboot-blocking experiments modify shared system binaries, update settings and sysctls; the reversal script does not restore captured original state. Do not use as a security control. |
| `misc/setup_devops_rhel95.sh`, `misc/fix-devops-setup.sh` | RHEL 9.5-era environment provisioning; privileged changes and upstream downloads need a fresh review. |
| `misc/cli/install-nerd-fonts.sh` | Old full-font installer; fixed release/download assumptions and recursive permissions need redesign before reuse. |
| `misc/tmm-download.sh` | Site-specific personal download experiment requiring a local authenticated cookie file. No cookies are included. |
| `misc/scratch/` | Early network logging prototypes; superseded by [Network Analyzer](https://github.com/apakoning/network-analyzer). |

Moved paths remain available in Git history. Prefer the maintained projects linked from the main README.
