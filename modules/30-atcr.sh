#!/usr/bin/env sh

set -euxo pipefail

# Install atcr credential helper
curl -fsSL atcr.io/static/install.sh | INSTALL_DIR="/usr/bin" bash
