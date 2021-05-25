#!/usr/bin/env bash

# Stop on error.
set -e

# shellcheck disable=SC1091
source env.sh

echo "${GREEN}Generating scdaemon.conf.${RESET}"

# Sometimes on macOS, a gpg update make the yubikey detection flaky or completely impossible
# So we enforce the scdaemon.conf configuration to detect the YubiKey as it is on macOS only
# cf env.sh
# https://gpgtools.tenderapp.com/discussions/problems/58454-after-updating-to-gpgtools-20171-yubikey-no-longer-functions-properly-both-in-mail-gpg2-card-edit/page/1
if [[ -n "$SCDAEMON_CONF" ]]; then
    backup_conf "$DEFAULT_GPG_SCDAEMON_CONF"
    echo -e "$SCDAEMON_CONF" > "$DEFAULT_GPG_SCDAEMON_CONF"
fi
