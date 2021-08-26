#!/usr/bin/env bash

# Create default directories.
mkdir -p "$DEFAULT_GPG_HOMEDIR"
chmod 700 "$DEFAULT_GPG_HOMEDIR"

# Backup GPG agent configuration in default GPG homedir, if it exists.
backup_conf "$DEFAULT_GPG_AGENT_CONF"
