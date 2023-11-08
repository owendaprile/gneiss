ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-38}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION:-535}"

FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_MAJOR_VERSION}

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-38}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION:-535}"


#
# Add rpmfusion repositories
#

RUN rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm

RUN rpm-ostree install \
        rpmfusion-free-release rpmfusion-nonfree-release \
        --uninstall=rpmfusion-free-release --uninstall=rpmfusion-nonfree-release


#
# Install Nvidia drivers
#

COPY --from=ghcr.io/ublue-os/akmods-nvidia:main-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} /rpms /tmp/akmods-rpms

RUN sed -i "s|enabled=1|enabled=0|g" /etc/yum.repos.d/fedora-{cisco-openh264,modular,updates-modular}.repo

RUN rpm-ostree install /tmp/akmods-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm

RUN source /tmp/akmods-rpms/kmods/nvidia-vars.${NVIDIA_MAJOR_VERSION} && \
    rpm-ostree install \
        /tmp/akmods-rpms/kmods/kmod-${NVIDIA_PACKAGE_NAME}-${KERNEL_VERSION}-${NVIDIA_AKMOD_VERSION}.fc${RELEASE}.rpm

RUN rpm-ostree install \
        nvidia-container-toolkit nvidia-vaapi-driver supergfxctl gnome-shell-extension-supergfxctl-gex

RUN rm /etc/yum.repos.d/{eyecantcu-supergfxctl,nvidia-container-toolkit}.repo


#
# Install additional packages
#

# Visual Studio Code
RUN rpm-ostree install 'https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64'

# 1Password
RUN mkdir /var/opt && \
    rpm -Uvh 'https://downloads.1password.com/linux/rpm/stable/x86_64/1password-latest.rpm' && \
    mv /var/opt/1Password /usr/lib/1password && \
    echo 'L /opt/1Password - - - - ../../usr/lib/1password' > /usr/lib/tmpfiles.d/1password.conf
RUN rm --force /etc/yum.repos.d/1password.repo

# Tailscale
RUN curl --output /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
RUN rpm-ostree install tailscale
RUN rm /etc/yum.repos.d/tailscale.repo
RUN systemctl enable tailscaled.service

# Use ffmpeg libraries from rpmfusion for full video codec support.
RUN rpm-ostree override remove \
        libavutil-free \
        libswresample-free \
        libpostproc-free \
        libswscale-free \
        libavcodec-free \
        libavformat-free \
        libavfilter-free \
        --install=ffmpeg-libs

# Use Mesa VA-API drivers from rpmfusion for full hardware accelerated video on AMD.
RUN rpm-ostree override remove \
        mesa-va-drivers \
        --install=mesa-va-drivers-freeworld \
        --install=mesa-vdpau-drivers-freeworld

# Others
RUN rpm-ostree install \
        gnome-shell-extension-appindicator \
        fish \
        intel-media-driver \
        intelone-mono-fonts

# Remove base packages
RUN rpm-ostree override remove \
        gnome-classic-session \
        gnome-shell-extension-apps-menu \
        gnome-shell-extension-background-logo \
        gnome-shell-extension-launch-new-instance \
        gnome-shell-extension-places-menu \
        gnome-shell-extension-window-list

# Enable automatic updates
RUN sed -i 's|#AutomaticUpdatePolicy=none|AutomaticUpdatePolicy=stage|g' /etc/rpm-ostreed.conf
RUN systemctl enable rpm-ostreed-automatic.timer


RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install


COPY files /


#
# Clean up extra files
#

RUN rm --force --recursive /tmp/*
RUN ostree container commit
