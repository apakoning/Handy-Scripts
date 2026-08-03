#!/usr/bin/env bash
set -euo pipefail

# resolve_rhel95_setup.sh
# Checks/install DaVinci Resolve dependencies on RHEL 9.x, and optionally NVIDIA repo/driver bits.

SCRIPT_NAME="$(basename "$0")"
LOG="/tmp/${SCRIPT_NAME%.sh}.log"

# -------- helpers --------
info()  { echo -e "[INFO] $*"  | tee -a "$LOG" >&2; }
warn()  { echo -e "[WARN] $*"  | tee -a "$LOG" >&2; }
err()   { echo -e "[ERROR] $*" | tee -a "$LOG" >&2; }
die()   { err "$*"; exit 1; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options]

Options:
  --deps            Install DaVinci Resolve dependencies/libs (default)
  --nvidia-repo     Add NVIDIA CUDA repo for RHEL9 (dnf config-manager add-repo)
  --nvidia-driver   Install NVIDIA driver + CUDA/OpenCL support packages (requires --nvidia-repo)
  --check-only      Do not install anything; only report status
  --yes             Assume yes (dnf -y). Default: yes
  --help            Show this help

Examples:
  sudo ./$SCRIPT_NAME
  sudo ./$SCRIPT_NAME --check-only
  sudo ./$SCRIPT_NAME --nvidia-repo
  sudo ./$SCRIPT_NAME --nvidia-repo --nvidia-driver
EOF
}

# -------- args --------
DO_DEPS=1
DO_NVIDIA_REPO=0
DO_NVIDIA_DRIVER=0
CHECK_ONLY=0
ASSUME_YES=1

if [[ $# -gt 0 ]]; then
  for a in "$@"; do
    case "$a" in
      --deps)          DO_DEPS=1 ;;
      --nvidia-repo)   DO_NVIDIA_REPO=1 ;;
      --nvidia-driver) DO_NVIDIA_DRIVER=1 ;;
      --check-only)    CHECK_ONLY=1 ;;
      --yes)           ASSUME_YES=1 ;;
      --help|-h)       usage; exit 0 ;;
      *) die "Unknown option: $a (use --help)";;
    esac
  done
fi

if [[ $DO_NVIDIA_DRIVER -eq 1 && $DO_NVIDIA_REPO -eq 0 ]]; then
  die "--nvidia-driver requires --nvidia-repo (so packages can be found reliably)."
fi


# -------- environment checks --------
[[ $EUID -eq 0 ]] || die "Run as root (use sudo)."

have_cmd dnf || die "dnf not found. This script targets RHEL/Rocky/Alma 9.x."

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
else
  die "Cannot read /etc/os-release"
fi

OS_ID="${ID:-unknown}"
OS_VER="${VERSION_ID:-unknown}"
OS_NAME="${PRETTY_NAME:-unknown}"

info "Detected OS: $OS_NAME"
case "$OS_ID" in
  rhel|rocky|almalinux|centos)
    ;;
  *)
    warn "This script is intended for RHEL-family. Proceeding anyway."
    ;;
esac

if [[ "$OS_VER" != 9* ]]; then
  warn "You are not on 9.x (VERSION_ID=$OS_VER). This script is tuned for RHEL 9.x."
fi

# -------- package lists --------
# Core Resolve "it tends to break if missing" deps/tools
DEPS_PKGS=(
  libxcrypt-compat
  apr apr-util
  mesa-libGLU
  alsa-lib alsa-plugins-pulseaudio
  pulseaudio-libs
  libXcursor libXi libXinerama libXrandr libXrender libXtst libXcomposite libXdamage libXfixes
  libSM libICE
  fontconfig freetype
  xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm
  ocl-icd clinfo
  pciutils
  fuse-libs
)

# Optional-but-helpful debug tools
EXTRA_PKGS=(
  mesa-demos
  xorg-x11-server-Xorg
  xorg-x11-xauth
)

# Build bits for NVIDIA DKMS (only installed if --nvidia-driver)
NVIDIA_BUILD_PKGS=(
  gcc make dkms
  elfutils-libelf-devel
  kernel-devel-$(uname -r)
  kernel-headers-$(uname -r)
)

# NVIDIA driver packages (repo provides these names)
NVIDIA_DRIVER_PKGS=(
  nvidia-driver-cuda
  kmod-nvidia-latest-dkms
)

# -------- functions --------
rpm_installed() { rpm -q "$1" >/dev/null 2>&1; }

check_pkg_list() {
  local -n _pkgs=$1
  local missing=()
  for p in "${_pkgs[@]}"; do
    # Some entries have command substitutions resolved already (kernel-devel-...)
    if ! rpm_installed "$p"; then
      missing+=("$p")
    fi
  done
  printf '%s\n' "${missing[@]:-}"
}

dnf_install() {
  local pkgs=("$@")
  [[ ${#pkgs[@]} -gt 0 ]] || return 0
  if [[ $CHECK_ONLY -eq 1 ]]; then
    info "CHECK-ONLY: would install: ${pkgs[*]}"
    return 0
  fi
  local yflag=""
  [[ $ASSUME_YES -eq 1 ]] && yflag="-y"
  info "Installing: ${pkgs[*]}"
  dnf $yflag install "${pkgs[@]}"
}

detect_nouveau() {
  if lsmod | grep -qi '^nouveau'; then
    warn "Nouveau is loaded. NVIDIA proprietary driver often requires disabling Nouveau + dracut --force + reboot."
  else
    info "Nouveau not loaded (good)."
  fi
}

detect_secure_boot() {
  if have_cmd mokutil; then
    if mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then
      warn "Secure Boot appears ENABLED. NVIDIA kernel modules may fail to load unless signed or Secure Boot disabled."
    else
      info "Secure Boot: not enabled (or not enforced)."
    fi
  else
    warn "mokutil not installed; can't check Secure Boot state."
  fi
}

detect_wayland() {
  # This is a heuristic; actual session selection happens at login.
  if [[ -f /etc/gdm/custom.conf ]] && grep -q 'WaylandEnable=false' /etc/gdm/custom.conf; then
    info "GDM is configured to disable Wayland (WaylandEnable=false)."
  else
    warn "Wayland may be enabled. Resolve often behaves best on Xorg. (You can choose 'GNOME on Xorg' at login.)"
  fi
}

check_nvidia_runtime() {
  if have_cmd nvidia-smi; then
    info "nvidia-smi found:"
    nvidia-smi | head -n 15 | tee -a "$LOG" >&2
  else
    warn "nvidia-smi not found. NVIDIA driver likely not installed or not in PATH."
  fi

  if have_cmd clinfo; then
    info "clinfo found (first lines):"
    clinfo | head -n 30 | tee -a "$LOG" >&2
  else
    warn "clinfo not found (installing deps will add it)."
  fi
}

add_nvidia_repo() {
  have_cmd dnf || die "dnf not available"
  have_cmd dnf-3 || true

  # Ensure config-manager exists
  if ! dnf -q repolist >/dev/null 2>&1; then
    warn "dnf repolist failed; check networking/repos."
  fi

  if ! rpm_installed dnf-plugins-core; then
    dnf_install dnf-plugins-core
  fi

  local arch
  arch="$(uname -i)"
  local repo_url="http://developer.download.nvidia.com/compute/cuda/repos/rhel9/${arch}/cuda-rhel9.repo"

  info "Adding NVIDIA CUDA repo: $repo_url"
  if [[ $CHECK_ONLY -eq 1 ]]; then
    info "CHECK-ONLY: would run dnf config-manager --add-repo $repo_url"
  else
    dnf config-manager --add-repo "$repo_url"
    dnf -y makecache
  fi
}

# -------- run --------
info "Log: $LOG"
: > "$LOG"

info "System checks:"
detect_nouveau
detect_secure_boot
detect_wayland

info "Checking installed packages (Resolve deps)..."
missing_deps=()
while IFS= read -r line; do
  [[ -n "$line" ]] && missing_deps+=("$line")
done < <(check_pkg_list DEPS_PKGS)

if [[ ${#missing_deps[@]} -eq 0 ]]; then
  info "All core Resolve dependency packages appear installed."
else
  warn "Missing core deps (${#missing_deps[@]}): ${missing_deps[*]}"
  dnf_install "${missing_deps[@]}"
fi

info "Installing optional debug tools (recommended)..."
missing_extra=()
while IFS= read -r line; do
  [[ -n "$line" ]] && missing_extra+=("$line")
done < <(check_pkg_list EXTRA_PKGS)

if [[ ${#missing_extra[@]} -eq 0 ]]; then
  info "Optional debug tools already installed."
else
  dnf_install "${missing_extra[@]}"
fi

if [[ $DO_NVIDIA_REPO -eq 1 ]]; then
  info "NVIDIA repo requested..."
  add_nvidia_repo
fi

if [[ $DO_NVIDIA_DRIVER -eq 1 ]]; then
  info "NVIDIA driver install requested..."

  info "Installing NVIDIA build requirements (DKMS)..."
  missing_build=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && missing_build+=("$line")
  done < <(check_pkg_list NVIDIA_BUILD_PKGS)
  dnf_install "${missing_build[@]}"

  info "Installing NVIDIA driver packages..."
  missing_nv=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && missing_nv+=("$line")
  done < <(check_pkg_list NVIDIA_DRIVER_PKGS)

  if [[ ${#missing_nv[@]} -eq 0 ]]; then
    info "NVIDIA driver packages already installed."
  else
    dnf_install "${missing_nv[@]}"
    warn "Driver packages installed. A reboot is usually required."
  fi
fi

info "Runtime verification:"
check_nvidia_runtime

info "Done."
info "Next steps:"
cat <<'EOF' | tee -a "$LOG" >&2
  1) Reboot if you installed NVIDIA driver packages:
       sudo reboot
  2) Verify GPU:
       nvidia-smi
  3) Verify OpenCL:
       clinfo | head -n 50
  4) Install Resolve:
       - download Linux .zip from Blackmagic
       - unzip and run the .run as root
EOF

