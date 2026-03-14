IMAGE_NAME := 'gneiss'
IMAGE_REGISTRY := env('IMAGE_REGISTRY', 'localhost')
DEFAULT_MAJOR_VERSION := '43'
DATE := `date +'%Y%m%d'`
BUILD_COUNT := env('BUILD_COUNT', '0')

default:
    @just --list

# Build the container image
build MAJOR_VERSION=DEFAULT_MAJOR_VERSION:
    podman build \
        --pull=always \
        --format docker \
        --build-arg FEDORA_MAJOR_VERSION={{ MAJOR_VERSION }} \
        --label "org.opencontainers.image.title={{ IMAGE_NAME }}" \
        --label "org.opencontainers.image.version={{ MAJOR_VERSION }}.{{ DATE }}.{{ BUILD_COUNT }}" \
        --tag "{{ IMAGE_REGISTRY }}/{{ IMAGE_NAME }}:{{ MAJOR_VERSION }}" \
        --tag "{{ IMAGE_REGISTRY }}/{{ IMAGE_NAME }}:{{ MAJOR_VERSION }}.{{ DATE }}.{{ BUILD_COUNT }}" \
        --file ./Containerfile

# Push the image to the registry.
# Requires: REGISTRY_USER and REGISTRY_PASSWORD env vars; cosign.key and cosign.pwd files.
push MAJOR_VERSION=DEFAULT_MAJOR_VERSION:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo mkdir -p /etc/containers/registries.d
    printf 'default-docker:\n  use-sigstore-attachments: true\n' \
        | sudo tee /etc/containers/registries.d/sigstore.yaml > /dev/null
    podman push \
        --sign-by-sigstore-private-key=cosign.key \
        --sign-passphrase-file=cosign.pwd \
        --creds "${REGISTRY_USER}:${REGISTRY_PASSWORD}" \
        "{{ IMAGE_REGISTRY }}/{{ IMAGE_NAME }}:{{ MAJOR_VERSION }}"
    podman push \
        --sign-by-sigstore-private-key=cosign.key \
        --sign-passphrase-file=cosign.pwd \
        --creds "${REGISTRY_USER}:${REGISTRY_PASSWORD}" \
        "{{ IMAGE_REGISTRY }}/{{ IMAGE_NAME }}:{{ MAJOR_VERSION }}.{{ DATE }}.{{ BUILD_COUNT }}"
