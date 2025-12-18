FEDORA_MAJOR_VERSION := "43"

default:
    @just --list

build-image:
    podman build \
        --pull=always \
        --build-arg FEDORA_MAJOR_VERSION={{ FEDORA_MAJOR_VERSION }} \
        --tag localhost/gneiss:{{ FEDORA_MAJOR_VERSION }} \
        --file ./Containerfile
