#!/bin/bash

tools=(
    inxi neofetch btop htop nvtop glances
    lsblk lshw lsusb lspci dmidecode smartctl
    dstat ip ss nmap tcpdump mtr iperf3
    ncdu ethtool bat exa rg fd gpg pwgen
    hashdeep chkrootkit nethogs fzf tldr
    bottom taskwarrior aria2c curlie jq yq
    ranger vifm mc fdupes xxd trash
)

printf "\nChecking for installed CLI tools...\n"
printf "------------------------------------\n"

for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        printf "%-15s Installed\n" "$tool"
    else
        printf "%-15s Missing\n" "$tool"
    fi
done
