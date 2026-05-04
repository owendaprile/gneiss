#!/usr/bin/env sh

set -euxo pipefail

# Add full version of ffmpeg.
rpm-ostree override remove \
    libavutil-free libswresample-free libswscale-free libavcodec-free \
    libavformat-free libavfilter-free libavdevice-free ffmpeg-free \
    --install ffmpeg

# Add hardware decoding for all formats.
rpm-ostree install mesa-va-drivers-freeworld
