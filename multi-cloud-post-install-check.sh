1) One-shot sanity checks

bash

aws --version
az version | head -n1
gcloud version | head -n1
kubectl version --client --short
helm version --short
kind version || true
minikube version || true



2) First-time logins & defaults

bash

# AWS
aws configure
# (enter AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, region e.g. us-east-1, output json)

# Azure
az login
az account set --subscription "<SUBSCRIPTION_NAME_OR_ID>"

# GCP
gcloud init
# - Log in, pick/create project
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a




3) Quick local K8s spin-up (pick one)

bash

# kind (super fast)
sudo kind-up        # or: sudo kind-up mycluster
kubectl get nodes

# Minikube (add-ons enabled)
sudo mk-up          # or: sudo mk-up myprofile
kubectl get nodes



4) Cloud CLIs + K8s interop smoke tests

bash

# AWS ECR auth (no push; just proves the CLI + Podman)
aws sts get-caller-identity
aws ecr get-login-password --region us-east-1 | podman login --username AWS --password-stdin "$(aws sts get-caller-identity >/dev/null 2>&1 && echo <your_ecr_registry_here> || echo example.com)"

# Azure whoami
az account show --output table

# GCP whoami
gcloud auth list



5) Nice-to-have aliases (optional)

bash

alias k=kubectl
alias tf="terraform"
alias kc="kubectl config current-context"


