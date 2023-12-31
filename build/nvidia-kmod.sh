#!/usr/bin/env bash

set -eoux pipefail

# Install the Nvidia akmod
rpm-ostree install akmod-nvidia

RELEASE=$(rpm -E '%fedora.%_arch')
KERNEL_VERSION="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
NVIDIA_AKMOD_VERSION="$(basename "$(rpm -q akmod-nvidia --queryformat '%{VERSION}-%{RELEASE}')" ".fc${RELEASE%%.*}")"

# Building the kmod requires a linker at `ld`, but `alternatives` doesn't work
# during the build.
ln --force --symbolic --relative /usr/bin/ld.gold /usr/bin/ld
# `akmods` tries to install the built kmods with `dnf`, but we don't need that,
# so we can just fool it.
ln --force --symbolic --relative /usr/bin/true /usr/bin/dnf

# Build the kmod
akmods --force --kernels "$KERNEL_VERSION" --kmod nvidia

# Make sure all modules were built successfully
[ -f /var/cache/akmods/nvidia/kmod-nvidia-${KERNEL_VERSION}-${NVIDIA_AKMOD_VERSION}.fc${RELEASE}.rpm ] ||
  (cat /var/cache/akmods/nvidia/$NVIDIA_AKMOD_VERSION-for-$KERNEL_VERSION.failed.log && exit 1)

mkdir -p /rpms

# Set important variables so the kmod can be installed later.
cat <<EOF > /rpms/nvidia-vars
RELEASE="$RELEASE"
KERNEL_VERSION="$KERNEL_VERSION"
NVIDIA_AKMOD_VERSION="$NVIDIA_AKMOD_VERSION"
EOF

cat /rpms/nvidia-vars

# Copy the built kmod rpms
for RPM in $(find /var/cache/akmods/ -type f -name \*.rpm); do
    cp "$RPM" /rpms;
done
