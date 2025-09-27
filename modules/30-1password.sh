#!/usr/bin/env sh

set -euxo pipefail

chmod +x /tmp/1password.sh
/tmp/1password.sh
rm --force --recursive --verbose /tmp/1password.sh
sed --in-place "s/^L/L+/g" /usr/lib/tmpfiles.d/onepassword.conf
