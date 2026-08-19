#!/usr/bin/env bash
# Recomputes NCPA_CHECK_SHA256 / NAGIOSTV_SHA256 in Dockerfile.linux-amd64 from the
# NCPA_BRANCH / NAGIOSTV_VERSION currently pinned in that file, and rewrites the ARG
# lines in place. Run this manually whenever you bump NCPA_BRANCH or NAGIOSTV_VERSION,
# then diff-review the result before committing — it re-trusts whatever is downloaded,
# so it must never run unattended as part of the actual image build.
set -euo pipefail

cd "$(dirname "$0")/.."
dockerfile="Dockerfile.linux-amd64"

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

arg_value() {
    grep -m1 "^ARG $1=" "$dockerfile" | cut -d= -f2-
}

set_arg_value() {
    sed -i.bak -E "s|^ARG $1=.*|ARG $1=$2|" "$dockerfile"
    rm -f "$dockerfile.bak"
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ncpa_branch=$(arg_value NCPA_BRANCH)
echo "Fetching check_ncpa.py @ ${ncpa_branch}..."
curl -sL -o "$tmpdir/check_ncpa.py" \
    "https://raw.githubusercontent.com/NagiosEnterprises/ncpa/${ncpa_branch}/client/check_ncpa.py"
ncpa_sha=$(sha256 "$tmpdir/check_ncpa.py")
set_arg_value NCPA_CHECK_SHA256 "$ncpa_sha"
echo "  NCPA_CHECK_SHA256=${ncpa_sha}"

nagiostv_version=$(arg_value NAGIOSTV_VERSION)
echo "Fetching nagiostv-${nagiostv_version}.tar.gz..."
curl -sL -o "$tmpdir/nagiostv.tar.gz" \
    "https://github.com/chriscareycode/nagiostv-react/releases/download/v${nagiostv_version}/nagiostv-${nagiostv_version}.tar.gz"
nagiostv_sha=$(sha256 "$tmpdir/nagiostv.tar.gz")
set_arg_value NAGIOSTV_SHA256 "$nagiostv_sha"
echo "  NAGIOSTV_SHA256=${nagiostv_sha}"

echo "Done. Review with: git diff ${dockerfile}"
