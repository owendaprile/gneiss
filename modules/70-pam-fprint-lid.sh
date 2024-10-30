#!/usr/bin/env sh

set -euxo pipefail

awk \
    --include=inplace \
    '/pam_fprintd.so/{print "auth        [success=ignore default=1]                   pam_exec.so quiet /usr/libexec/pam-fprint-lid-helper   {include if \"with-fingerprint\"}"}1' \
    /usr/share/authselect/default/local/system-auth
