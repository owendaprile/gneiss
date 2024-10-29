#!/usr/bin/env sh

set -euxo pipefail

# Enable automatic staging of updates
sed -i 's|#AutomaticUpdatePolicy=none|AutomaticUpdatePolicy=stage|g' /etc/rpm-ostreed.conf
systemctl enable rpm-ostreed-automatic.timer
