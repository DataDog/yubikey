#!/usr/bin/env bash

# Stop on error.
set -e

# shellcheck disable=SC1091
source env.sh

echo "${GREEN}Generating scdaemon.conf."
echo "${RESET}"

if [[ -n "$SCDAEMON_CONF" ]]; then
    backup_conf "$DEFAULT_GPG_SCDAEMON_CONF"
    echo -e "$SCDAEMON_CONF" > "$DEFAULT_GPG_SCDAEMON_CONF"
fi
