#!/usr/bin/env bash

# Exit on any error
set -e

# === Function: Ensure script is run as root ===
require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root. Trying sudo..."
        exec sudo "$0" "$@"
    fi
}

# === Function: Main ===
main() {
    # Set your Git repo URL here
    GIT_REPO="git@github.com:yourusername/nixos-configs.git"

    # Get hostname
    HOSTNAME=$(hostname)

    echo "[INFO] Hostname is: $HOSTNAME"

    # Create temporary directory for cloning
    TMPDIR=$(mktemp -d)

    echo "[INFO] Cloning repo to $TMPDIR"
    git clone "$GIT_REPO" "$TMPDIR"

    # Verify hostname folder exists in the repo
    if [ ! -d "$TMPDIR/$HOSTNAME" ]; then
        echo "[ERROR] No config folder found for hostname '$HOSTNAME' in the repo."
        exit 1
    fi

    # Copy files to /etc/nixos (backup first if needed)
    echo "[INFO] Copying config from $TMPDIR/$HOSTNAME to /etc/nixos/"
    cp -rT "$TMPDIR/$HOSTNAME" /etc/nixos/

    # Optional: show diff?
    echo "[INFO] Applying configuration..."
    nixos-rebuild switch

    echo "[SUCCESS] Configuration applied successfully!"

    # Cleanup
    rm -rf "$TMPDIR"
}

# === Entry point ===
require_root "$@"
main "$@"