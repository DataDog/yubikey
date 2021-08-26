#!/usr/bin/env bash

# Overwrite default GPG agent configuration with our own.
# We want to replace the pinentry-tty with the pinentry-mac.
cat << EOF > "$DEFAULT_GPG_AGENT_CONF"
# https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
pinentry-program /usr/local/bin/pinentry-mac
# For usability while balancing security, cache User PIN for at most a day.
default-cache-ttl 86400
max-cache-ttl 86400
EOF

