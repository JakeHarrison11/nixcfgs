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
    GIT_REPO="https://github.com/JakeHarrison11/nixcfgs.git"

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

    # === If docker-compose.yml exists, run compose2nix ===
    if [ -f "/etc/nixos/docker-compose.yml" ]; then
        echo "[INFO] Detected docker-compose.yml. Converting to Nix..."
        if ! command -v compose2nix &>/dev/null; then
            echo "[ERROR] compose2nix is not installed. Install it with 'nix-shell -p compose2nix'"
            exit 1
        fi

        compose2nix /etc/nixos/docker-compose.yml > /etc/nixos/docker-compose.nix
        rm /etc/nixos/docker-compose.yml
        echo "[INFO] Converted and replaced docker-compose.yml with docker-compose.nix"
    fi

    # Apply system config
    echo "[INFO] Applying configuration..."
    nixos-rebuild switch

    echo "[SUCCESS] Configuration applied successfully!"

    # Cleanup
    rm -rf "$TMPDIR"
}

# === Entry point ===
require_root "$@"
main "$@"