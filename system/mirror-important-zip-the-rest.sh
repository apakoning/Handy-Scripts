#!/bin/bash

# Set storage path to ~/storage/downloads/Mirrors/DevOps
STORAGE_PATH="$HOME/storage/downloads/Mirrors/DevOps"

# Create directory if it doesn't exist
mkdir -p "$STORAGE_PATH"

# Move to the storage directory
cd "$STORAGE_PATH" || exit

echo "🔄 Starting Hybrid Repository Downloads in $STORAGE_PATH..."

### 1️⃣ Git Mirror (For Version Control & Updates)
declare -a MIRROR_REPOS=(
  # AWS
  "https://github.com/aws/aws-cli.git"
  "https://github.com/boto/boto3.git"
  "https://github.com/aws/aws-sdk-go.git"
  "https://github.com/aws/aws-sdk-js.git"
  "https://github.com/localstack/localstack.git"

  # Azure
  "https://github.com/Azure/azure-cli.git"
  "https://github.com/Azure/azure-sdk-for-python.git"
  "https://github.com/Azure/azure-sdk-for-go.git"
  "https://github.com/Azure/azure-sdk-for-java.git"
  "https://github.com/Azure/Azurite.git"

  # DevOps Tools
  "https://github.com/kubernetes/kubernetes.git"
  "https://github.com/kubernetes/kubectl.git"
  "https://github.com/kubernetes-sigs/kind.git"
  "https://github.com/docker/cli.git"
  "https://github.com/moby/moby.git"
  "https://github.com/containerd/containerd.git"
  "https://github.com/helm/helm.git"
  "https://github.com/hashicorp/terraform.git"
  "https://github.com/hashicorp/packer.git"

  # RHEL 9 & CentOS Streams
  "https://gitlab.com/redhat/centos-stream.git"
  "https://github.com/CentOS/sig-core-packages.git"

  # CI/CD & Automation
  "https://github.com/jenkinsci/jenkins.git"
  "https://gitlab.com/gitlab-org/gitlab.git"
  "https://github.com/actions/runner.git"
  "https://github.com/argoproj/argo-cd.git"

  # Security & Monitoring
  "https://github.com/prometheus/prometheus.git"
  "https://github.com/grafana/grafana.git"
  "https://github.com/elastic/elasticsearch.git"
  "https://github.com/aquasecurity/trivy.git"
  "https://github.com/falcosecurity/falco.git"
)

for repo in "${MIRROR_REPOS[@]}"; do
  REPO_NAME=$(basename "$repo" .git)
  echo "📥 Cloning: $REPO_NAME"
  git clone --mirror "$repo" "$REPO_NAME"
done

### 2️⃣ Download ZIP Files (For Large Repos Where History Isn’t Needed)
declare -a ZIP_REPOS=(
  # AWS Docs
  "https://docs.aws.amazon.com/AmazonS3/latest/API/API_Operations.pdf aws-s3-api.pdf"
  "https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM_Overview.pdf aws-iam-guide.pdf"

  # Azure Docs
  "https://docs.microsoft.com/en-us/azure/architecture/framework/resiliency/resiliency-overview.pdf azure-resiliency.pdf"
  "https://docs.microsoft.com/en-us/azure/architecture/guide/architecture-guide.pdf azure-architecture.pdf"

  # Kubernetes Tools
  "https://github.com/kubernetes-sigs/kind/archive/refs/heads/main.zip kind.zip"
  "https://github.com/k3s-io/k3s/archive/refs/heads/main.zip k3s.zip"

  # CI/CD
  "https://github.com/tektoncd/pipeline/archive/refs/heads/main.zip tekton-pipeline.zip"
)

for repo in "${ZIP_REPOS[@]}"; do
  IFS=' ' read -r URL FILENAME <<< "$repo"
  echo "📥 Downloading: $FILENAME"
  wget -c "$URL" -O "$FILENAME"
done

echo "✅ All repositories and documentation downloaded successfully in $STORAGE_PATH!"