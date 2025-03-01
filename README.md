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
2. Run `rpm-ostree rebase ostree-unverified-registry:ghcr.io/owendaprile/gneiss:<version>`
3. Reboot your system