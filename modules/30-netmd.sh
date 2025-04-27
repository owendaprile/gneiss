#!/usr/bin/env sh
set -euxo pipefail

# Add rules from Web MiniDisc Pro project.
curl --output '/usr/lib/udev/rules.d/60-netmd.rules' 'https://raw.githubusercontent.com/asivery/webminidisc/refs/heads/master/extra/70-netmd.rules'
