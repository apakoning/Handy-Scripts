# --- yq (Mike Farah) upstream binary ---
curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /tmp/yq \
  && sudo install /tmp/yq /usr/local/bin/yq

# --- Java 17 + Java 8 (side-by-side; 17 default) ---
sudo dnf install -y java-17-openjdk java-1.8.0-openjdk
sudo alternatives --set java  /usr/lib/jvm/jre-17/bin/java  || true
sudo alternatives --set javac /usr/lib/jvm/java-17/bin/javac || true

# --- .NET 8 SDK (Microsoft repo) ---
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm || true
sudo dnf install -y dotnet-sdk-8.0

# --- Helm (repo if available; else upstream) ---
sudo dnf install -y helm || { \
  HV=$(curl -sL https://api.github.com/repos/helm/helm/releases/latest | grep -Po '"tag_name":\s*"v\K[^"]+'); \
  curl -L "https://get.helm.sh/helm-v${HV}-linux-amd64.tar.gz" -o /tmp/helm.tgz; \
  tar -xzf /tmp/helm.tgz -C /tmp; \
  sudo install /tmp/linux-amd64/helm /usr/local/bin/helm; }

# --- k9s (upstream) ---
if ! command -v k9s >/dev/null; then
  K9S_VER=$(curl -sL https://api.github.com/repos/derailed/k9s/releases/latest | grep -Po '"tag_name":\s*"v\K[^"]+')
  curl -L "https://github.com/derailed/k9s/releases/download/v${K9S_VER}/k9s_Linux_amd64.tar.gz" -o /tmp/k9s.tgz
  tar -xzf /tmp/k9s.tgz -C /tmp k9s && sudo install /tmp/k9s /usr/local/bin/k9s
fi

# --- kustomize (standalone or wrapper) ---
if ! command -v kustomize >/dev/null; then
  curl -sSLo /tmp/kustomize_installer.sh https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh
  bash /tmp/kustomize_installer.sh || true
  [ -f ./kustomize ] && sudo install ./kustomize /usr/local/bin/kustomize || {
    printf '#!/usr/bin/env bash\nexec kubectl kustomize "$@"\n' | sudo tee /usr/local/bin/kustomize >/dev/null
    sudo chmod +x /usr/local/bin/kustomize
  }
fi

# --- HashiCorp (only if missing) ---
for t in terraform packer vault; do
  if ! command -v "$t" >/dev/null; then
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo || true
    sudo dnf install -y "$t"
  fi
done

# --- Version summary (robust flags) ---
for c in java javac dotnet git ansible docker podman buildah skopeo kubectl helm kustomize k9s terraform jq yq packer vault; do
  if command -v "$c" >/dev/null 2>&1; then
    case "$c" in
      java) "$c" -version 2>&1 | head -n1 ;;
      javac) "$c" -version 2>&1 | head -n1 ;;
      kubectl) "$c" version --client --short ;;
      helm) "$c" version --short ;;
      *) "$c" --version 2>&1 | head -n1 ;;
    esac
  else
    echo "$c MISSING"
  fi
done

