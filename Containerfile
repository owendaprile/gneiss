ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION:-535}"

FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_MAJOR_VERSION}

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION:-535}"

# Add rpmfusion repositories
RUN rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm


#
# Nvidia drivers
#

COPY --from=ghcr.io/ublue-os/akmods-nvidia:main-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} /rpms /tmp/akmods-rpms

RUN rpm-ostree install /tmp/akmods-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm && \
    source /tmp/akmods-rpms/kmods/nvidia-vars.${NVIDIA_MAJOR_VERSION} && \
    rpm-ostree install \
        /tmp/akmods-rpms/kmods/kmod-${NVIDIA_PACKAGE_NAME}-${KERNEL_VERSION}-${NVIDIA_AKMOD_VERSION}.fc${RELEASE}.rpm \
        nvidia-container-toolkit nvidia-vaapi-driver supergfxctl gnome-shell-extension-supergfxctl-gex && \
    rm --force /etc/yum.repos.d/{eyecantcu-supergfxctl,nvidia-container-toolkit}.repo


#
# Video codecs and hardware acceleration
#

RUN rpm-ostree override remove \
        # ffmpeg
        libavutil-free libswresample-free libpostproc-free libswscale-free libavcodec-free libavformat-free libavfilter-free \
        --install=ffmpeg-libs \
        # VA-API and VDPAU for AMD
        mesa-va-drivers \
        --install=mesa-va-drivers-freeworld --install=mesa-vdpau-drivers-freeworld \
        # VA-API for Intel
        --install=intel-media-driver


#
# Other packages
#

# Remove unwanted packages from base image
RUN rpm-ostree override remove \
        # GNOME Classic session
        gnome-classic-session gnome-shell-extension-apps-menu gnome-shell-extension-background-logo \
        gnome-shell-extension-launch-new-instance gnome-shell-extension-places-menu gnome-shell-extension-window-list \
        # Fedora customizations
        fedora-bookmarks fedora-chromium-config fedora-flathub-remote fedora-third-party fedora-workstation-repositories

# Install 1Password
RUN mkdir --parents /var/opt && \
    rpm-ostree install \
        https://downloads.1password.com/linux/rpm/stable/x86_64/1password-latest.rpm \
        https://downloads.1password.com/linux/rpm/stable/x86_64/1password-cli-latest.x86_64.rpm && \
    rm --force /etc/yum.repos.d/1password.repo && \
    mv /var/opt/1Password /usr/lib/1password && \
    echo "L /opt/1Password - - - - ../../usr/lib/1password" > /usr/lib/tmpfiles.d/1password.conf

# Install Tailscale
RUN curl --output /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    rpm-ostree install tailscale && \
    rm --force /etc/yum.repos.d/tailscale.repo && \
    systemctl enable tailscaled.service

# Install packages in the base image
RUN rpm-ostree install \
        gnome-shell-extension-appindicator fish intelone-mono-fonts \
        https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64


#
# System configuration
#

# Enable automatic updates
RUN sed -i 's|#AutomaticUpdatePolicy=none|AutomaticUpdatePolicy=stage|g' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer

# Disable Fedora Flatpak repo
RUN systemctl disable flatpak-add-fedora-repos.service

# Copy files
COPY files /


#
# Cleanup
#

RUN rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release

RUN rm --force --recursive /tmp/* /var/* && \
    ostree container commit
