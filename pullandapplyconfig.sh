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

    # Path to host-specific config in the repo
    HOSTCFG="$TMPDIR/$HOSTNAME"

    # Verify hostname folder exists
    if [ ! -d "$HOSTCFG" ]; then
        echo "[ERROR] No config folder found for hostname '$HOSTNAME' in the repo."
        exit 1
    fi

    # === Convert docker-compose.yml to docker-compose.nix if it exists ===
    if [ -f "$HOSTCFG/docker-compose.yml" ]; then
        echo "[INFO] Detected docker-compose.yml in host config. Converting..."

        if ! command -v compose2nix &>/dev/null; then
            echo "[ERROR] compose2nix is not installed. Run: nix-shell -p compose2nix"
            exit 1
        fi

        pushd "$HOSTCFG" > /dev/null
        compose2nix > docker-compose.nix
        rm docker-compose.yml
        popd > /dev/null

        echo "[INFO] Converted to docker-compose.nix"
    fi

    # === Copy host config to /etc/nixos ===
    echo "[INFO] Copying config from $HOSTCFG to /etc/nixos/"
    cp -rT "$HOSTCFG" /etc/nixos/

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