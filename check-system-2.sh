#!/bin/bash

tools=(
    aws az terraform packer ansible kubectl kubeadm helm
    docker podman buildah skopeo minikube kind
    jenkins git mvn node npm python3 pip3
    crio crictl pinns containerd jq yq kubectx kubens
)

declare -A packages=(
    [aws]=awscli
    [az]=azure-cli
    [kubectl]=kubernetes-client
    [mvn]=maven
    [node]=nodejs
    [pip3]=python3-pip
    [crio]=cri-o
    [crictl]=cri-tools
)

missing=()

printf '\nRHEL 9 System Readiness Check\n'
printf '%s\n' '------------------------------------'

for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        printf '%-15s Installed\n' "$tool"
    else
        printf '%-15s Missing\n' "$tool"
        missing+=("$tool")
    fi
done

if ((${#missing[@]})); then
    printf '\nSuggested installation commands:\n'
    printf '%s\n' '------------------------------------'

    for tool in "${missing[@]}"; do
        package=${packages[$tool]:-$tool}
        printf '%-15s sudo dnf install -y %s\n' "$tool" "$package"
    done
else
    printf '\nAll required tools are installed!\n'
fi

printf '\nInstalled: %d | Missing: %d | Total: %d\n\n' \
    "$((${#tools[@]} - ${#missing[@]}))" \
    "${#missing[@]}" \
    "${#tools[@]}"
