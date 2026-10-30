#!/usr/bin/env bash
# Compatibility entry point for the renamed repository diagnostic.
exec bash "$(dirname -- "${BASH_SOURCE[0]}")/check-dnf-repo-signatures.sh" "$@"
