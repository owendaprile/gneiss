#!/usr/bin/env sh

set -euxo pipefail

curl --output /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
rpm-ostree install tailscale
rm --force /etc/yum.repos.d/tailscale.repo
systemctl enable tailscaled.service
