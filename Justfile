IMAGE_NAME := 'localhost/gneiss'
DEFAULT_MAJOR_VERSION := '43'
DATE := `date +'%Y%m%d'`

default:
    @just --list

build-image MAJOR_VERSION=DEFAULT_MAJOR_VERSION:
    podman build \
        --pull=always \
        --build-arg FEDORA_MAJOR_VERSION={{ MAJOR_VERSION }} \
        --tag "{{ IMAGE_NAME }}:{{ MAJOR_VERSION }}" \
        --tag "{{ IMAGE_NAME }}:{{ MAJOR_VERSION }}.{{ DATE }}" \
        --file ./Containerfile
