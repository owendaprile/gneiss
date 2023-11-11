##
## Build the Nvidia kmod
##

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"

FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_MAJOR_VERSION} AS nvidia-builder

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"

COPY build/nvidia-kmod.sh .

RUN rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm && \
    ./nvidia-kmod.sh


##
## Build the system image
##

FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_MAJOR_VERSION}

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"

# Add rpmfusion repositories
RUN rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm


#
# Nvidia driver
#

COPY --from=nvidia-builder /rpms /tmp/akmods-rpms

# Install Nvidia kmod and VA-API driver
RUN source /tmp/akmods-rpms/nvidia-vars && \
    rpm-ostree install \
        /tmp/akmods-rpms/kmod-nvidia-$KERNEL_VERSION-$NVIDIA_AKMOD_VERSION.fc$RELEASE.rpm \
        libva-nvidia-driver && \
    # Remove the nvidia-settings launcher
    rm --force /usr/share/applications/nvidia-settings.desktop


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
        # GNOME Terminal
        gnome-terminal gnome-terminal-nautilus \
        # GNOME Classic session
        gnome-classic-session gnome-shell-extension-apps-menu gnome-shell-extension-background-logo \
        gnome-shell-extension-launch-new-instance gnome-shell-extension-places-menu gnome-shell-extension-window-list \
        # Fedora customizations
        fedora-bookmarks fedora-chromium-config fedora-flathub-remote fedora-third-party fedora-workstation-backgrounds \
        fedora-workstation-repositories \
        # Others
        gnome-tour yelp

# Install yafti
RUN rpm-ostree install python3-pip libadwaita && \
    pip install --prefix=/usr yafti && \
    rpm-ostree uninstall python3-pip

# Install 1Password
COPY --from=ghcr.io/ublue-os/bling /modules/bling/installers/1password.sh /tmp
RUN chmod +x /tmp/1password.sh && \
        /tmp/1password.sh && \
        rm --force /tmp/1password.sh && \
        # Force the symlink '/opt/1Password -> /usr/lib/1Password' to be created
        sed --in-place "s|^L|L+|g" /usr/lib/tmpfiles.d/onepassword.conf

# Install Tailscale
RUN curl --output /etc/yum.repos.d/tailscale.repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    rpm-ostree install tailscale && \
    rm --force /etc/yum.repos.d/tailscale.repo && \
    systemctl enable tailscaled.service

# Install Insync
RUN echo -e "[insync]\nbaseurl=http://yum.insync.io/fedora/\$releasever/\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key" >> /etc/yum.repos.d/insync.repo && \
    rpm-ostree install insync && \
    rm --force /etc/yum.repos.d/insync.repo

# Install packages in the base image
RUN rpm-ostree install \
        # GNOME
        gnome-console gnome-shell-extension-appindicator gnome-tweaks \
        # Fonts
        intelone-mono-fonts \
        # Other
        android-tools fish langpacks-en steam-devices \
        'https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64'


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

RUN tree /opt /var/opt ; exit 0

RUN rm --force --recursive /tmp/* /var/* && \
    ostree container commit
