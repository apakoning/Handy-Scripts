#!/bin/bash

# Auto-installer for modern CLI tools (RHEL 8/9 compatible)
# Tools: bat, fd, ripgrep (rg), bottom, fzf, dust, tldr, delta

set -e

echo "Updating DNF and enabling CodeReady Builder..."
sudo subscription-manager repos --enable codeready-builder-for-rhel-$(arch)-rpms || true

echo "Installing EPEL repo..."
sudo dnf install -y epel-release

echo "Updating repo cache..."
sudo dnf makecache

echo "Installing CLI tools..."
sudo dnf install -y \
    bat \
    fd-find \
    ripgrep \
    bottom \
    fzf \
    du-dust \
    tldr \
    git-delta

echo "Creating compatibility symlinks..."
[ -f /usr/bin/fdfind ] && sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
[ -f /usr/bin/batcat ] && sudo ln -sf /usr/bin/batcat /usr/local/bin/bat

echo "Initializing tldr cache..."
tldr --update

echo "All tools installed successfully!"
