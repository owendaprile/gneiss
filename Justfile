# Default recipe
default:
    @just --list

build-image:
    podman build --build-arg=FEDORA_MAJOR_VERSION=40 --tag=localhost/gneiss:40$(date +'%Y%m%d').0 --file=Containerfile