#!/bin/bash

echo -e "\n🔎 **RHEL 9 System Readiness Check for AWS, Azure, DevOps, RHCSA**\n"

# Define required tools
TOOLS=(
  "aws" "az" "terraform" "packer" "ansible" "kubectl" "kubeadm" "helm"
  "docker" "podman" "buildah" "skopeo" "minikube" "kind"
  "jenkins" "git" "mvn" "node" "npm" "python3" "pip3"
  "crio" "crictl" "pinns" "containerd" "jq" "yq" "kubectx" "kubens"
)

# Check installed tools
echo -e "🔍 Checking installed tools...\n"
MISSING_TOOLS=()
for tool in "${TOOLS[@]}"; do
  if command -v "$tool" &>/dev/null; then
    echo -e "✅ $tool is installed"
  else
    echo -e "❌ $tool is missing"
    MISSING_TOOLS+=("$tool")
  fi
done

# List missing tools
if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
  echo -e "\n⚠️ The following tools are missing:"
  echo "${MISSING_TOOLS[@]}"
  
  # Provide install suggestions
  echo -e "\n💡 Suggested installation commands:\n"
  
  for tool in "${MISSING_TOOLS[@]}"; do
    case $tool in
      aws) echo "👉 Install AWS CLI: sudo dnf install -y awscli" ;;
      az) echo "👉 Install Azure CLI: sudo dnf install -y azure-cli" ;;
      terraform) echo "👉 Install Terraform: sudo dnf install -y terraform" ;;
      packer) echo "👉 Install Packer: sudo dnf install -y packer" ;;
      ansible) echo "👉 Install Ansible: sudo dnf install -y ansible" ;;
      kubectl) echo "👉 Install kubectl: sudo dnf install -y kubernetes-client" ;;
      kubeadm) echo "👉 Install kubeadm: sudo dnf install -y kubeadm" ;;
      helm) echo "👉 Install Helm: sudo dnf install -y helm" ;;
      docker) echo "👉 Install Docker: sudo dnf install -y docker" ;;
      podman) echo "👉 Install Podman: sudo dnf install -y podman" ;;
      buildah) echo "👉 Install Buildah: sudo dnf install -y buildah" ;;
      skopeo) echo "👉 Install Skopeo: sudo dnf install -y skopeo" ;;
      minikube) echo "👉 Install Minikube: sudo dnf install -y minikube" ;;
      kind) echo "👉 Install Kind: sudo dnf install -y kind" ;;
      jenkins) echo "👉 Install Jenkins: sudo dnf install -y jenkins" ;;
      git) echo "👉 Install Git: sudo dnf install -y git" ;;
      mvn) echo "👉 Install Maven: sudo dnf install -y maven" ;;
      node) echo "👉 Install Node.js: sudo dnf install -y nodejs" ;;
      npm) echo "👉 Install NPM: sudo dnf install -y npm" ;;
      python3) echo "👉 Install Python3: sudo dnf install -y python3" ;;
      pip3) echo "👉 Install pip3: sudo dnf install -y python3-pip" ;;
      crio) echo "👉 Install CRI-O: sudo dnf install -y cri-o" ;;
      crictl) echo "👉 Install crictl: sudo dnf install -y cri-tools" ;;
      pinns) echo "👉 Manually install pinns: curl -LO https://github.com/cri-o/cri-o/raw/main/bin/pinns && sudo mv pinns /usr/local/bin/pinns && sudo chmod +x /usr/local/bin/pinns" ;;
      containerd) echo "👉 Install Containerd: sudo dnf install -y containerd" ;;
      jq) echo "👉 Install jq: sudo dnf install -y jq" ;;
      yq) echo "👉 Install yq: sudo dnf install -y yq" ;;
      kubectx) echo "👉 Install kubectx: sudo dnf install -y kubectx" ;;
      kubens) echo "👉 Install kubens: sudo dnf install -y kubens" ;;
      *) echo "⚠️ No installation command found for $tool" ;;
    esac
  done
else
  echo -e "\n🎉 All required tools are installed!"
fi

echo -e "\n✅ System readiness check complete!\n"
