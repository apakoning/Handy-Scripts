#!/bin/bash
for r in $(grep -RhoP '^\[\K[^]]+' /etc/yum.repos.d/*.repo | sort -u); do
  if dnf repolist --enabled 2>/dev/null | awk '{print $1}' | grep -qx "$r"; then
    echo "=== $r ==="
    sudo dnf -v makecache --disablerepo="*" --enablerepo="$r" 2>&1 | egrep -i 'signature not supported|sha1|repo:' | head -30
  fi
done
