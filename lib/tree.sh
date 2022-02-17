#!/usr/bin/env bash

# Figure out whether we need to write GPG keys to a tempdir.
# This is useful when you need to generate keys for someone else w/o adding to your own keystore.
if [[ -z "$TEMPDIR" ]]
then
  GPG_HOMEDIR=$DEFAULT_GPG_HOMEDIR
  echo "Using *default* GPG homedir: $GPG_HOMEDIR"
else
  GPG_HOMEDIR=$(mktemp -d)
  echo "Using *temp* GPG homedir: $GPG_HOMEDIR"
fi
echo

# Create default directories.
mkdir -p "$GPG_HOMEDIR"
chmod 700 "$GPG_HOMEDIR"

# Backup GPG agent configuration in default GPG homedir, if it exists.
backup_conf "$DEFAULT_GPG_AGENT_CONF"
