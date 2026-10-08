#!/usr/bin/env bash
#
# create-release.sh — create (or complete) the PUBLIC GitHub release for a
# version tag, uploading the assets staged by build-release-assets.sh.
#
# Usage:
#   bash scripts/create-release.sh 1.1.2+13 [--repo everabyte/everbox-realease]
#
# - CI (workflow .github/workflows/github-release.yml): uses GH_TOKEN and
#   --repo, no git credentials involved.
# - Locally: requires the gh CLI, authenticated ("gh auth login"); --repo
#   is only needed outside a clone with an origin remote.
# - Idempotent: re-running for the same tag uploads missing platforms into
#   the EXISTING release (--clobber refreshes same-named assets) — that is
#   how a macOS or Linux build published later joins a Windows release.
# - The release is marked latest: the permanent everabyte.com links
#   (/releases/latest/download/<asset>) follow it automatically.

set -euo pipefail

die() { echo "create-release: ERROR: $*" >&2; exit 1; }

tag="${1:-}"
[ -n "$tag" ] || die "usage: create-release.sh <version>+<build> [--repo owner/name]"
shift || true
repo_flag=()
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo_flag=(--repo "$2"); shift 2 ;;
    *) die "unknown argument: $1" ;;
  esac
done

command -v gh >/dev/null 2>&1 \
  || die "gh CLI required — https://cli.github.com/ (preinstalled on GitHub runners)"
if [ -z "${GH_TOKEN:-}" ] && [ -z "${GITHUB_TOKEN:-}" ]; then
  gh auth status >/dev/null 2>&1 \
    || die "no GitHub credentials — 'gh auth login' or set GH_TOKEN"
fi

here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/build-release-assets.sh" "$tag"

title="$(cat dist/release-title.txt)"
mapfile -t assets < <(find dist -maxdepth 1 -type f \( -name 'EverBox-*' -o -name 'SHA256SUMS.txt' \) | sort)
[ "${#assets[@]}" -gt 0 ] || die "no staged assets — internal error (build-release-assets.sh)"

if gh release view "$tag" "${repo_flag[@]}" >/dev/null 2>&1; then
  echo "release $tag already exists — uploading/refreshing ${#assets[@]} asset(s) into it"
  gh release upload "$tag" "${assets[@]}" --clobber "${repo_flag[@]}"
  gh release edit "$tag" --notes-file dist/release-notes.md "${repo_flag[@]}"
else
  echo "creating release $tag — ${#assets[@]} asset(s)"
  gh release create "$tag" "${assets[@]}" \
    --title "$title" \
    --notes-file dist/release-notes.md \
    --latest \
    "${repo_flag[@]}"
fi

echo "done: https://github.com/everabyte/everbox-realease/releases/tag/$tag"
