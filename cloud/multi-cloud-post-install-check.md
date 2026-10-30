# Multi-cloud post-install checklist

These are individual manual checks, not an installation script. Run only the commands for tools you have installed. Account authentication and cluster creation are separate steps you choose explicitly.

## Local CLI checks

```bash
aws --version
az version
gcloud version
kubectl version --client
helm version --short
kind version
minikube version
```

## Optional account checks

After configuring credentials through the provider's normal login process:

```bash
aws sts get-caller-identity
az account show --output table
gcloud auth list
```

These commands can display account identifiers. Do not commit their output or credentials.

## Optional local Kubernetes checks

With a configured container runtime, create a disposable local cluster:

```bash
kind create cluster --name study-lab
kubectl get nodes
# Remove the lab when finished:
kind delete cluster --name study-lab
```

Alternatively use `minikube start` and `minikube delete`. Local clusters consume CPU, memory and disk. Package availability, cloud permissions and runtime configuration are separate from the command-presence checks in this repository.
