#!/usr/bin/env bash
set -euo pipefail

# ===== Helpers =====
need_cmd() { command -v "$1" >/dev/null 2>&1; }
as_root()  { if [ "$EUID" -ne 0 ]; then sudo "$@"; else "$@"; fi; }
install_pkgs() { as_root dnf install -y "$@"; }

# ===== Repos / Basics =====
install_pkgs dnf-plugins-core epel-release curl tar unzip git make python3-pip

# ===== Core toolchain (RHEL/EPEL) =====
install_pkgs podman buildah skopeo jq golang nodejs ansible

# ===== yq (upstream; not in RHEL repos reliably) =====
if ! need_cmd yq; then
  echo "[*] Installing yq (upstream binary)..."
  curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /tmp/yq
  as_root install /tmp/yq /usr/local/bin/yq
fi

# ===== Java 17 + Java 8 (side-by-side) =====
install_pkgs java-17-openjdk java-1.8.0-openjdk
# set java 17 as default, but keep 8 available
as_root alternatives --set java  /usr/lib/jvm/jre-17/bin/java  || true
as_root alternatives --set javac /usr/lib/jvm/java-17/bin/javac || true

# ===== .NET (8 LTS) via Microsoft repo =====
if ! need_cmd dotnet; then
  if ! rpm -q packages-microsoft-prod >/dev/null 2>&1; then
    as_root rpm -Uvh https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
  fi
  install_pkgs dotnet-sdk-8.0 || true
fi

# ===== kubectl (upstream, if missing) =====
if ! need_cmd kubectl; then
  echo "[*] Installing kubectl..."
  KVER="$(curl -fsSL https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
  curl -fsSL -o /tmp/kubectl "https://storage.googleapis.com/kubernetes-release/release/${KVER}/bin/linux/amd64/kubectl"
  chmod +x /tmp/kubectl
  as_root mv /tmp/kubectl /usr/local/bin/kubectl
fi

# ===== Helm (dnf if available; else upstream) =====
if ! need_cmd helm; then
  if as_root dnf info helm >/dev/null 2>&1; then
    install_pkgs helm
  else
    echo "[*] Installing Helm from upstream..."
    HV="$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest | grep -Po '"tag_name":\s*"v\K[^"]+')"
    curl -fsSL "https://get.helm.sh/helm-v${HV}-linux-amd64.tar.gz" -o /tmp/helm.tgz
    tar -xzf /tmp/helm.tgz -C /tmp
    as_root install /tmp/linux-amd64/helm /usr/local/bin/helm
  fi
fi

# ===== k9s (TUI for Kubernetes) =====
if ! need_cmd k9s; then
  echo "[*] Installing k9s..."
  K9S_VER="$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | grep -Po '"tag_name":\s*"v\K[^"]+')"
  curl -fsSL "https://github.com/derailed/k9s/releases/download/v${K9S_VER}/k9s_Linux_amd64.tar.gz" -o /tmp/k9s.tgz
  tar -xzf /tmp/k9s.tgz -C /tmp k9s
  as_root install /tmp/k9s /usr/local/bin/k9s
fi

# ===== kustomize (prefer standalone; fallback to kubectl kustomize) =====
if ! need_cmd kustomize; then
  echo "[*] Installing kustomize..."
  curl -fsSLo /tmp/kustomize_installer.sh https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh
  bash /tmp/kustomize_installer.sh || true
  if [ -f ./kustomize ]; then
    as_root install ./kustomize /usr/local/bin/kustomize
  else
    # fallback: wrapper for `kubectl kustomize`
    cat <<'EOF' | as_root tee /usr/local/bin/kustomize >/dev/null
#!/usr/bin/env bash
exec kubectl kustomize "$@"
EOF
    as_root chmod +x /usr/local/bin/kustomize
  fi
fi

# ===== HashiCorp (Terraform/Packer/Vault) =====
if ! grep -q hashicorp /etc/yum.repos.d/* 2>/dev/null; then
  as_root dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
fi
install_pkgs terraform packer vault

# ===== AWS CLI v2 =====
if ! need_cmd aws; then
  echo "[*] Installing AWS CLI v2..."
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  as_root /tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin
fi

# ===== Azure CLI =====
if ! need_cmd az; then
  echo "[*] Installing Azure CLI..."
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  as_root dnf install -y https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
  install_pkgs azure-cli
fi

# ===== Google Cloud SDK (gcloud) =====
if ! need_cmd gcloud; then
  echo "[*] Installing gcloud SDK..."
  # Set up repo
  cat <<'EOF' | as_root tee /etc/yum.repos.d/google-cloud-sdk.repo >/dev/null
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

  # Try DNF with conservative networking settings, else fall back to tarball
  if ! as_root dnf -y --setopt=retries=10 --setopt=timeout=300 \
        --setopt=max_parallel_downloads=1 --setopt=fastestmirror=False \
        install google-cloud-sdk; then
    echo "[!] Repo failed; falling back to official tarball..."
    curl -fsSL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz -o /tmp/gcloud.tgz
    as_root mkdir -p /opt && as_root tar -xzf /tmp/gcloud.tgz -C /opt
    as_root /opt/google-cloud-sdk/install.sh --quiet
    as_root ln -sf /opt/google-cloud-sdk/bin/gcloud  /usr/local/bin/gcloud
    as_root ln -sf /opt/google-cloud-sdk/bin/gsutil  /usr/local/bin/gsutil
    as_root ln -sf /opt/google-cloud-sdk/bin/bq      /usr/local/bin/bq
  fi
fi


# ===== Local Kubernetes: kind (with Podman) & Minikube =====
echo
echo "[*] Installing local Kubernetes tools (kind + Minikube)..."

# kind (Podman provider)
if ! need_cmd kind; then
  curl -fsSL -o /tmp/kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
  as_root install /tmp/kind /usr/local/bin/kind
fi

# Minikube (Podman driver)
if ! need_cmd minikube; then
  curl -fsSL -o /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  as_root install /tmp/minikube /usr/local/bin/minikube
fi

# Helper wrappers: create/destroy clusters quickly
as_root mkdir -p /usr/local/sbin

# kind-up
cat <<'EOF' | as_root tee /usr/local/sbin/kind-up >/dev/null
#!/usr/bin/env bash
set -euo pipefail
export KIND_EXPERIMENTAL_PROVIDER=podman
CLUSTER_NAME="${1:-dev}"
TMPCFG="$(mktemp)"
cat >"$TMPCFG"<<'YAML'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
    protocol: TCP
  - containerPort: 30443
    hostPort: 8443
    protocol: TCP
YAML
kind create cluster --name "$CLUSTER_NAME" --config "$TMPCFG"
echo "Kubeconfig merged. Try: kubectl get nodes"
EOF
as_root chmod +x /usr/local/sbin/kind-up

# kind-down
cat <<'EOF' | as_root tee /usr/local/sbin/kind-down >/dev/null
#!/usr/bin/env bash
set -euo pipefail
export KIND_EXPERIMENTAL_PROVIDER=podman
CLUSTER_NAME="${1:-dev}"
kind delete cluster --name "$CLUSTER_NAME" || true
EOF
as_root chmod +x /usr/local/sbin/kind-down

# mk-up
cat <<'EOF' | as_root tee /usr/local/sbin/mk-up >/dev/null
#!/usr/bin/env bash
set -euo pipefail
PROFILE="${1:-dev}"
minikube start -p "$PROFILE" --driver=podman --container-runtime=containerd
minikube -p "$PROFILE" addons enable metrics-server
minikube -p "$PROFILE" addons enable ingress
echo "Kubeconfig set for profile '$PROFILE'. Try: kubectl get nodes"
EOF
as_root chmod +x /usr/local/sbin/mk-up

# mk-down
cat <<'EOF' | as_root tee /usr/local/sbin/mk-down >/dev/null
#!/usr/bin/env bash
set -euo pipefail
PROFILE="${1:-dev}"
minikube delete -p "$PROFILE" || true
EOF
as_root chmod +x /usr/local/sbin/mk-down

# ===== Version summary =====
echo
echo "===== Tool Versions ====="
print_ver() {
  cmd="$1"
  if ! need_cmd "$cmd"; then printf "%-10s  %s\n" "$cmd" "MISSING"; return; fi
  case "$cmd" in
    java)        "$cmd" -version 2>&1 | head -n1 ;;
    javac)       "$cmd" -version 2>&1 | head -n1 ;;
    dotnet)      "$cmd" --info 2>&1 | head -n1 ;;
    kubectl)     "$cmd" version --client --short ;;
    helm)        "$cmd" version --short ;;
    k9s)         "$cmd" version --short || "$cmd" version ;;
    terraform)   "$cmd" version | head -n1 ;;
    aws)         "$cmd" --version ;;
    az)          "$cmd" version | head -n1 ;;
    gcloud)      "$cmd" version | head -n1 ;;
    *)           "$cmd" --version 2>&1 | head -n1 ;;
  esac
}
for c in java javac dotnet git ansible podman buildah skopeo kubectl helm kustomize k9s terraform jq yq packer vault aws az gcloud kind minikube; do
  print_ver "$c" || true
done

echo
echo "Done. Your RHEL box is now a full DevOps lab."
echo "Tip: use 'alternatives --config java|javac' to switch between Java 8 and 17."
echo "Local clusters: 'kind-up'/'kind-down' or 'mk-up'/'mk-down'."



