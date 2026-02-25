#!/usr/bin/env sh

set -euxo pipefail

# Add full version of ffmpeg.
rpm-ostree override remove \
    libavutil-free libswresample-free libpostproc-free libswscale-free libavcodec-free \
    libavformat-free libavfilter-free libavdevice-free ffmpeg-free \
    --install ffmpeg

# Add hardware decoding for all formats.
rpm-ostree override remove \
    mesa-va-drivers \
    --install mesa-va-drivers-freeworld #\
    # --install mesa-vdpau-drivers-freeworld
