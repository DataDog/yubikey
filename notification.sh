#!/usr/bin/env bash

source env.sh

echo -e "$NOTIFICATION_CMD" > "$NOTIFICATION_SCRIPT_PATH"
chmod u+x "$NOTIFICATION_SCRIPT_PATH"

$GIT config --global --add gpg.program "$NOTIFICATION_SCRIPT_PATH"
