#!/usr/bin/env sh

set -euxo pipefail

# Remove packages from image.
rpm-ostree override remove \
    gnome-classic-session gnome-shell-extension-apps-menu gnome-shell-extension-background-logo \
    gnome-shell-extension-launch-new-instance gnome-shell-extension-places-menu \
    gnome-shell-extension-window-list

# Add packages to image.
rpm-ostree install \
    gnome-shell-extension-appindicator \
    ptyxis fish \
    intel-one-mono-fonts jetbrains-mono-fonts \
    steam-devices \
    android-tools
