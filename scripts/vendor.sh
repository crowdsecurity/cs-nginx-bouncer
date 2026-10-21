#!/bin/bash
#
# Manage the Lua dependencies vendored under vendor/.
#
# Each dependency is pinned in vendor/vendor.conf by tag *and* commit, so a
# moved upstream tag is detected instead of silently pulled in. Only the
# upstream lib/ directory and license are kept.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="${ROOT}/vendor"
MANIFEST="${VENDOR_DIR}/vendor.conf"

usage() {
    cat <<EOF
Usage: $0 <command> [args]

Commands:
    list                    Show pinned dependencies
    sync [name...]          Re-fetch dependencies at their pinned version
    update <name> [tag]     Bump a dependency to <tag> (default: latest release tag)
    outdated                Print "name current latest" for each outdated dependency
    verify                  Check vendor/ matches the pinned upstream sources
    advisories              Print published GitHub security advisories of each upstream
EOF
    exit 1
}

die() {
    echo "error: $*" >&2
    exit 1
}

# Prints "name repo tag commit" lines, skipping comments and blank lines.
entries() {
    grep -Ev '^[[:space:]]*(#|$)' "${MANIFEST}"
}

lookup() {
    local line
    line=$(entries | awk -v n="$1" '$1 == n')
    [ -n "${line}" ] || die "unknown dependency '$1' (see ${MANIFEST})"
    echo "${line}"
}

latest_tag() {
    git ls-remote --tags --refs "$1" \
        | awk '{ sub("refs/tags/", "", $2); print $2 }' \
        | grep -E '^v?[0-9]+(\.[0-9]+)*$' \
        | sort -V \
        | tail -n 1
}

# Resolves a tag to the commit it points to (peeled for annotated tags).
tag_commit() {
    local refs
    refs=$(git ls-remote "$1" "refs/tags/$2" "refs/tags/$2^{}")
    [ -n "${refs}" ] || die "tag $2 not found in $1"
    echo "${refs}" | sort -k2 | tail -n 1 | cut -f1
}

# fetch <repo> <tag> <commit> <dest>
fetch() {
    local repo=$1 tag=$2 commit=$3 dest=$4
    local tmp actual
    tmp=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '${tmp}'" RETURN

    git -c advice.detachedHead=false clone -q --depth 1 -b "${tag}" "${repo}" "${tmp}/src"
    actual=$(git -C "${tmp}/src" rev-parse HEAD)
    [ "${actual}" = "${commit}" ] || die "${repo} ${tag} is at ${actual}, expected ${commit}"

    rm -rf "${dest}"
    mkdir -p "${dest}"
    cp -r "${tmp}/src/lib" "${dest}/"
    cp "${tmp}/src"/LICENSE* "${dest}/"
}

cmd_list() {
    entries | awk '{ printf "%-20s %-12s %s\n", $1, $3, $2 }'
}

cmd_sync() {
    local name repo tag commit
    if [ $# -eq 0 ]; then
        # shellcheck disable=SC2046 # names never contain whitespace
        set -- $(entries | awk '{ print $1 }')
    fi
    for dep in "$@"; do
        read -r name repo tag commit <<< "$(lookup "${dep}")"
        echo "syncing ${name} ${tag}"
        fetch "${repo}" "${tag}" "${commit}" "${VENDOR_DIR}/${name}"
    done
}

cmd_update() {
    [ $# -ge 1 ] || usage
    local name repo tag commit new_tag new_commit
    read -r name repo tag commit <<< "$(lookup "$1")"
    new_tag=${2:-$(latest_tag "${repo}")}
    new_commit=$(tag_commit "${repo}" "${new_tag}")

    echo "updating ${name} ${tag} -> ${new_tag}"
    fetch "${repo}" "${new_tag}" "${new_commit}" "${VENDOR_DIR}/${name}"

    awk -v n="${name}" -v t="${new_tag}" -v c="${new_commit}" \
        '$1 == n { $3 = t; $4 = c } { print }' "${MANIFEST}" > "${MANIFEST}.tmp"
    mv "${MANIFEST}.tmp" "${MANIFEST}"
}

cmd_outdated() {
    local name repo tag commit latest
    while read -r name repo tag commit; do
        latest=$(latest_tag "${repo}")
        if [ -n "${latest}" ] && [ "${latest}" != "${tag}" ] \
            && [ "$(printf '%s\n%s\n' "${tag}" "${latest}" | sort -V | tail -n 1)" = "${latest}" ]; then
            echo "${name} ${tag} ${latest}"
        fi
    done < <(entries)
}

cmd_verify() {
    local name repo tag commit tmp failed=0
    tmp=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '${tmp}'" EXIT

    while read -r name repo tag commit; do
        fetch "${repo}" "${tag}" "${commit}" "${tmp}/${name}"
        if diff -r "${tmp}/${name}" "${VENDOR_DIR}/${name}"; then
            echo "${name} ${tag}: ok"
        else
            echo "${name} ${tag}: vendored files differ from upstream" >&2
            failed=1
        fi
    done < <(entries)

    # Anything in vendor/ that is not in the manifest is unaccounted for.
    for dir in "${VENDOR_DIR}"/*/; do
        name=$(basename "${dir}")
        if ! entries | awk '{ print $1 }' | grep -qx "${name}"; then
            echo "vendor/${name} is not listed in ${MANIFEST}" >&2
            failed=1
        fi
    done
    return ${failed}
}

cmd_advisories() {
    local name repo tag commit slug
    while read -r name repo tag commit; do
        slug=${repo#https://github.com/}
        slug=${slug%.git}
        [ "${slug}" != "${repo}" ] || { echo "${name}: not hosted on GitHub, skipping"; continue; }
        gh api "repos/${slug}/security-advisories?state=published" \
            --jq ".[] | \"${name} (pinned ${tag}): \(.ghsa_id) [\(.severity)] \(.summary) — affected: \([.vulnerabilities[].vulnerable_version_range] | join(\", \")) — \(.html_url)\""
    done < <(entries)
}

[ $# -ge 1 ] || usage
command=$1
shift
case "${command}" in
    list|sync|update|outdated|verify|advisories) "cmd_${command}" "$@" ;;
    *) usage ;;
esac
