#!/usr/bin/env bash
# Recomputes the pinned artifact checksums in Dockerfile.linux-amd64/-arm64 from the
# versions/commits currently pinned in each file, and rewrites the ARG lines in place.
# Run this manually whenever you bump one of those versions/commits, then diff-review
# the result before committing — it re-trusts whatever is downloaded, so it must never
# run unattended as part of the actual image build.
set -euo pipefail

cd "$(dirname "$0")/.."
dockerfiles=(Dockerfile.linux-amd64 Dockerfile.linux-arm64)

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

arg_value() {
    grep -m1 "^ARG $2=" "$1" | cut -d= -f2-
}

set_arg_value() {
    sed -i.bak -E "s|^ARG $2=.*|ARG $2=$3|" "$1"
    rm -f "$1.bak"
}

has_arg() {
    grep -q "^ARG $2=" "$1"
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for dockerfile in "${dockerfiles[@]}"; do
    echo "== ${dockerfile} =="

    ncpa_branch=$(arg_value "$dockerfile" NCPA_BRANCH)
    echo "Fetching check_ncpa.py @ ${ncpa_branch}..."
    curl -sL -o "$tmpdir/check_ncpa.py" \
        "https://raw.githubusercontent.com/NagiosEnterprises/ncpa/${ncpa_branch}/client/check_ncpa.py"
    ncpa_sha=$(sha256 "$tmpdir/check_ncpa.py")
    set_arg_value "$dockerfile" NCPA_CHECK_SHA256 "$ncpa_sha"
    echo "  NCPA_CHECK_SHA256=${ncpa_sha}"

    nagiostv_version=$(arg_value "$dockerfile" NAGIOSTV_VERSION)
    echo "Fetching nagiostv-${nagiostv_version}.tar.gz..."
    curl -sL -o "$tmpdir/nagiostv.tar.gz" \
        "https://github.com/chriscareycode/nagiostv-react/releases/download/v${nagiostv_version}/nagiostv-${nagiostv_version}.tar.gz"
    nagiostv_sha=$(sha256 "$tmpdir/nagiostv.tar.gz")
    set_arg_value "$dockerfile" NAGIOSTV_SHA256 "$nagiostv_sha"
    echo "  NAGIOSTV_SHA256=${nagiostv_sha}"

    # arm64-only: config.guess/config.sub replacements needed for aarch64 autotools detection.
    if has_arg "$dockerfile" GNUCONFIG_COMMIT; then
        gnuconfig_commit=$(arg_value "$dockerfile" GNUCONFIG_COMMIT)
        echo "Fetching gnuconfig @ ${gnuconfig_commit}..."
        curl -sL -o "$tmpdir/config.guess" \
            "https://raw.githubusercontent.com/spack/gnuconfig/${gnuconfig_commit}/config.guess"
        curl -sL -o "$tmpdir/config.sub" \
            "https://raw.githubusercontent.com/spack/gnuconfig/${gnuconfig_commit}/config.sub"
        guess_sha=$(sha256 "$tmpdir/config.guess")
        sub_sha=$(sha256 "$tmpdir/config.sub")
        set_arg_value "$dockerfile" GNUCONFIG_GUESS_SHA256 "$guess_sha"
        set_arg_value "$dockerfile" GNUCONFIG_SUB_SHA256 "$sub_sha"
        echo "  GNUCONFIG_GUESS_SHA256=${guess_sha}"
        echo "  GNUCONFIG_SUB_SHA256=${sub_sha}"
    fi
done

echo "Done. Review with: git diff ${dockerfiles[*]}"
