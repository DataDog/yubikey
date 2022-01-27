#!/usr/bin/env bash

# Install required dependencies.
echo "${YELLOW}You need to have $(join ',' "${DEPS[@]}") installed on your device."
read -rp "Do you want us to install them for you ? (y/n)${RESET}" answer
case "$answer" in
    yes|YES|y|Y|Yes)
        # install required tools
        echo "Installing or upgrading required tools..."
        eval "$PKG_MANAGER_ENV" "$PKG_MANAGER" "$PKG_MANAGER_UPDATE"
        for pkg in "${DEPS[@]}"; do
            install_or_upgrade "$pkg"
        done
        ;;
    *)
        echo "Skipping install or upgrade of required tools"
        for pkg in "${DEPS[@]}"; do
            check_presence "$pkg"
        done
        ;;
esac
echo

