#!/usr/bin/env bash
# Refreshes every pin in Dockerfile.linux-amd64/-arm64 and rewrites the ARG lines in place:
#   - *_COMMIT for each git-fetch-commit source: the commit its tag points at (tagged sources)
#     or the latest commit on its default branch (everything else)
#   - BASE_IMAGE: the current multi-arch digest of its tag
#   - download checksums for NCPA, NagiosTV and (arm64) gnuconfig
# Version bumps stay manual: edit *_VERSION, then run this to re-pin.
# It re-trusts whatever upstream serves, so review the diff (or the PR it feeds) before merging,
# and never run it as part of the image build itself. Needs git, curl and docker buildx.
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

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
changes="$tmpdir/changes"
warnings="$tmpdir/warnings"
touch "$changes" "$warnings"

set_arg_value() {
    local old
    old=$(arg_value "$1" "$2")
    if [ "$old" != "$3" ]; then
        sed -i.bak -E "s|^ARG $2=.*|ARG $2=$3|" "$1"
        rm -f "$1.bak"
        echo "$2: $old -> $3" >> "$changes"
    fi
}

has_arg() {
    grep -q "^ARG $2=" "$1"
}

# Expands a single ${VAR} in $2 using that ARG's value from Dockerfile $1
expand_arg() {
    local text=$2 var
    var=$(printf '%s' "$text" | sed -nE 's/.*\$\{([A-Z0-9_]+)\}.*/\1/p')
    if [ -n "$var" ]; then
        text="${text%%\$\{*}$(arg_value "$1" "$var")${text#*\}}"
    fi
    printf '%s' "$text"
}

for dockerfile in "${dockerfiles[@]}"; do
    echo "== ${dockerfile} =="

    grep -oE 'git-fetch-commit [^ ]+ \$\{[A-Z0-9_]+\} [^ ]+( [^ &\\]+)?' "$dockerfile" |
    while read -r _ url commit_ref _ tag; do
        commit_arg=${commit_ref#\$\{}
        commit_arg=${commit_arg%\}}
        if [ -n "${tag:-}" ]; then
            tag=$(expand_arg "$dockerfile" "$tag")
            commit=$(git ls-remote "$url" "refs/tags/$tag" "refs/tags/$tag^{}" | tail -1 | cut -f1)
            source="tag $tag"
        else
            commit=$(git ls-remote "$url" HEAD | cut -f1)
            source="default branch"
        fi
        if [ -z "$commit" ]; then
            echo "Could not resolve $source of $url" >&2
            exit 1
        fi
        # Same *_VERSION as the committed file but a different commit means upstream moved the tag
        if [ -n "${tag:-}" ] && [ "$commit" != "$(arg_value "$dockerfile" "$commit_arg")" ]; then
            version_arg=${commit_arg%_COMMIT}_VERSION
            committed_version=$(git show "HEAD:$dockerfile" 2>/dev/null | grep -m1 "^ARG ${version_arg}=" | cut -d= -f2- || true)
            if [ -n "$committed_version" ] && [ "$committed_version" = "$(arg_value "$dockerfile" "$version_arg")" ]; then
                echo "WARNING: $url tag $tag was moved: now $commit, pinned $(arg_value "$dockerfile" "$commit_arg")" >> "$warnings"
            fi
        fi
        echo "  ${commit_arg} (${source}) = ${commit}"
        set_arg_value "$dockerfile" "$commit_arg" "$commit"
    done

    base_image=$(arg_value "$dockerfile" BASE_IMAGE)
    base_ref=${base_image%@*}
    digest=$(docker buildx imagetools inspect "$base_ref" | awk '/^Digest:/ {print $2; exit}')
    if [ -z "$digest" ]; then
        echo "Could not resolve digest of $base_ref" >&2
        exit 1
    fi
    echo "  BASE_IMAGE (${base_ref}) = ${digest}"
    set_arg_value "$dockerfile" BASE_IMAGE "${base_ref}@${digest}"

    ncpa_version=$(arg_value "$dockerfile" NCPA_VERSION)
    curl -fsSL -o "$tmpdir/check_ncpa.py" \
        "https://raw.githubusercontent.com/NagiosEnterprises/ncpa/v${ncpa_version}/client/check_ncpa.py"
    ncpa_sha=$(sha256 "$tmpdir/check_ncpa.py")
    echo "  NCPA_CHECK_SHA256 (check_ncpa.py v${ncpa_version}) = ${ncpa_sha}"
    set_arg_value "$dockerfile" NCPA_CHECK_SHA256 "$ncpa_sha"

    nagiostv_version=$(arg_value "$dockerfile" NAGIOSTV_VERSION)
    curl -fsSL -o "$tmpdir/nagiostv.tar.gz" \
        "https://github.com/chriscareycode/nagiostv-react/releases/download/v${nagiostv_version}/nagiostv-${nagiostv_version}.tar.gz"
    nagiostv_sha=$(sha256 "$tmpdir/nagiostv.tar.gz")
    echo "  NAGIOSTV_SHA256 (nagiostv-${nagiostv_version}.tar.gz) = ${nagiostv_sha}"
    set_arg_value "$dockerfile" NAGIOSTV_SHA256 "$nagiostv_sha"

    # arm64-only: config.guess/config.sub replacements needed for aarch64 autotools detection.
    if has_arg "$dockerfile" GNUCONFIG_COMMIT; then
        gnuconfig_commit=$(arg_value "$dockerfile" GNUCONFIG_COMMIT)
        curl -fsSL -o "$tmpdir/config.guess" \
            "https://raw.githubusercontent.com/spack/gnuconfig/${gnuconfig_commit}/config.guess"
        curl -fsSL -o "$tmpdir/config.sub" \
            "https://raw.githubusercontent.com/spack/gnuconfig/${gnuconfig_commit}/config.sub"
        guess_sha=$(sha256 "$tmpdir/config.guess")
        sub_sha=$(sha256 "$tmpdir/config.sub")
        echo "  GNUCONFIG_GUESS_SHA256 / GNUCONFIG_SUB_SHA256 (gnuconfig ${gnuconfig_commit:0:12}) = ${guess_sha:0:12}… / ${sub_sha:0:12}…"
        set_arg_value "$dockerfile" GNUCONFIG_GUESS_SHA256 "$guess_sha"
        set_arg_value "$dockerfile" GNUCONFIG_SUB_SHA256 "$sub_sha"
    fi
done

echo
if [ -s "$warnings" ]; then
    sort -u "$warnings"
    echo
fi
if [ -s "$changes" ]; then
    echo "Changed pins:"
    sort -u "$changes" | sed 's/^/  /'
    echo
    echo "Review with: git diff ${dockerfiles[*]}"
else
    echo "All pins are already current."
fi
