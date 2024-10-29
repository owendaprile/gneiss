#
# Containerfile
# Build the Gneiss container image.
#

ARG FEDORA_MAJOR_VERSION

FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_MAJOR_VERSION}

ARG FEDORA_MAJOR_VERSION

# Add RPM Fusion repositories.
RUN rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm && \
    ostree container commit

# Prepare 1Password module.
COPY --from=ghcr.io/blue-build/modules /modules/bling/installers/1password.sh /tmp/1password.sh

# Run all modules.
COPY ./modules /modules
RUN for module in $(find /modules -type f -executable); do \
        echo "---> Running \`$module\`"; \
        $module || exit $?; \
    done && \
    rm --force --recursive --verbose /modules && \
    ostree container commit

# Remove RPM Fusion repositories
RUN rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release && \
    ostree container commit

# Clean up image
RUN rm --force --recursive --verbose /tmp/* /var/* && \
    ostree container commit
