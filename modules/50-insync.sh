#!/usr/bin/env sh

set -euxo pipefail

# TODO: Add $releasever back.
echo -e "[insync]\nbaseurl=http://yum.insync.io/fedora/40/\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key" >> /etc/yum.repos.d/insync.repo
rpm-ostree install insync
rm --force /etc/yum.repos.d/insync.repo
