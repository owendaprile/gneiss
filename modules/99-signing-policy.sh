#!/usr/bin/env sh

set -euxo pipefail

REPO="ghcr.io/owendaprile/gneiss"
KEY_PATH="/etc/pki/containers/gneiss.pub"

jq '.default = [{"type": "reject"}]' /etc/containers/policy.json > /tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json

for transport in atomic containers-storage dir docker docker-archive docker-daemon oci oci-archive sif tarball; do
    jq --arg t "$transport" \
       '.transports[$t] = (.transports[$t] // {}) | .transports[$t][""] = [{"type": "insecureAcceptAnything"}]' \
       /etc/containers/policy.json > /tmp/policy.json
    mv /tmp/policy.json /etc/containers/policy.json
done

jq --arg repo "$REPO" --arg key "$KEY_PATH" \
   '.transports.docker[$repo] = [{"type": "sigstoreSigned", "keyPath": $key, "signedIdentity": {"type": "matchRepository"}}]' \
   /etc/containers/policy.json > /tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json


PUBLIC_KEY=$(cat <<EOF
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAENGyGEm+rHEIrDifFCWZaV2IefH24
1dJwHe33bwEv4yG0WW9bsOuiRe1acROFb0PtCkdkPdK1eSv2ZliaPvkIUA==
-----END PUBLIC KEY-----
EOF
)

mkdir --parents $(dirname "$KEY_PATH")
echo -n "$PUBLIC_KEY" > "$KEY_PATH"
