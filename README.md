# Gneiss
Gneiss is my custom build of Fedora Silverblue.

## Features
- Removes unwanted packages from the base image
- Adds additional packages from the official repositories
- Adds additional packages from rpmfusion and other third-party repositories
- Enables automatic updates using rpm-ostree
- Builds new images weekly using GitHub Actions
- And more!

## Installation
1. Install [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/)
  - Ensure your boot partition is at least 2 GB.
2. Run `rpm-ostree rebase ostree-unverified-registry:ghcr.io/owendaprile/gneiss:<version>`
3. Reboot your system
4. (Optional) If your system does not have any Intel or NVIDIA GPUs and your
  boot partition is below 2 GB, run the following command to exclude those
  drivers from your initramfs.
```sh
rpm-ostree initramfs --enable --arg=/usr/lib/dracut/dracut.conf.d/60-amd-only.conf
```
