#!/usr/bin/env bash
#
# build-release-assets.sh — stage the GitHub-release assets for ONE version
# tag (v<version>+<build>) into dist/.
#
# Usage (from the repository root):
#   bash scripts/build-release-assets.sh v1.1.2+13
#
# Inputs — the tag must point at a commit whose tree contains the packages
# published by the agent-backup tool under:
#   windows/<arch>/stable/<version>/    macos/<arch>/stable/<version>/
#   linux/<arch>/stable/<version>/
# plus the root CHANGELOG.json (release notes feed).
#
# Outputs (dist/):
#   EverBox-Setup-x64.exe      ← STABLE, version-independent asset names, so
#   EverBox-macOS-arm64.dmg      https://github.com/everabyte/everbox-realease/releases/latest/download/<asset>
#   EverBox-Linux-amd64.deb      ALWAYS serves the newest build (site links)
#   SHA256SUMS.txt             ← checksums of every installer in this release
#   release-notes.md           ← body of the GitHub release (CHANGELOG.json)
#   release-title.txt          ← "EverBox <version> (build <build>)"
#
# The AUTO-UPDATE channel is NOT touched by this script: latest.json keeps
# pointing at raw.githubusercontent.com (same-host pin enforced by the app).
#
# Requires jq + sha256sum (both preinstalled on GitHub ubuntu runners).

set -euo pipefail

die() { echo "build-release-assets: ERROR: $*" >&2; exit 1; }
warn() { echo "build-release-assets: WARNING: $*" >&2; }

tag="${1:-}"
[ -n "$tag" ] || die "usage: build-release-assets.sh v<version>+<build>"
case "$tag" in
  v*) ;;
  *) die "tag must start with 'v' — got '$tag'" ;;
esac

full="${tag#v}"
case "$full" in
  *+*) version="${full%%+*}"; build="${full##*+}" ;;
  *) die "tag must be v<version>+<build> (e.g. v1.1.2+13) — got '$tag'" ;;
esac
[ -n "$version" ] && [ -n "$build" ] || die "empty version or build in '$tag'"
case "$build" in
  ''|*[!0-9]*) die "build must be numeric in '$tag'" ;;
esac

command -v jq >/dev/null 2>&1 || die "jq is required (preinstalled on GitHub runners)"
[ -f CHANGELOG.json ] || die "CHANGELOG.json not found — run from the repository root"

# The tag must match the changelog feed: same version, same build number.
jq -e --arg v "$version" --argjson b "$build" \
  '.releases[$v].build == $b' CHANGELOG.json >/dev/null \
  || die "CHANGELOG.json has no '$version' entry with build $build — publish with the agent-backup tool first (dart run tool/publish_release.dart)"

rm -rf dist
mkdir -p dist

stable_name() { # <platform> <arch> <file> → stable asset name (extension kept)
  local platform="$1" arch="$2" file="$3" base ext
  base="$(basename "$file")"
  ext="${base##*.}"
  case "$platform" in
    windows) echo "EverBox-Setup-${arch}.${ext}" ;;
    macos)   echo "EverBox-macOS-${arch}.${ext}" ;;
    linux)   echo "EverBox-Linux-${arch}.${ext}" ;;
    *)       die "unknown platform '$platform'" ;;
  esac
}

# platform  arch    a COMPLETE release carries
combos=(
  "windows x64   windows"
  "macos   arm64 macos"
  "macos   x64   macos"
  "linux   amd64 linux"
  "linux   arm64 linux"
)

found=0
seen_platforms=""
for combo in "${combos[@]}"; do
  read -r platform arch family <<<"$combo"
  dir="${platform}/${arch}/stable/${version}"
  shopt -s nullglob
  files=("$dir"/*)
  shopt -u nullglob
  count=0
  for file in "${files[@]}"; do
    [ -f "$file" ] || continue
    case "$(basename "$file")" in
      README.md|*.json) continue ;; # documentation / channel manifests
    esac
    name="$(stable_name "$platform" "$arch" "$file")"
    [ -e "dist/$name" ] && die "duplicate asset name '$name'"
    cp "$file" "dist/$name"
    echo "asset  $name  <-  $file"
    count=$((count + 1))
    found=$((found + 1))

    # Consistency guard: when this combo's channel manifest already
    # publishes THIS version, it must describe the SAME package bytes.
    if [ "$count" -eq 1 ] && [ -f "$dir/latest.json" ]; then
      manifest_version="$(jq -r '.version' "$dir/latest.json")"
      if [ "$manifest_version" = "$version" ]; then
        manifest_sha="$(jq -r '.sha256' "$dir/latest.json")"
        asset_sha="$(sha256sum "dist/$name" | cut -d' ' -f1)"
        [ "$manifest_sha" = "$asset_sha" ] \
          || warn "$dir/latest.json sha256 != staged $name — channel manifest and release asset diverge"
      fi
    fi
  done
  if [ "$count" -gt 0 ]; then
    seen_platforms="$seen_platforms $family"
  else
    [ -d "$dir" ] || warn "no $family/${arch} packages (${dir}/ absent)"
  fi
done

[ "$found" -gt 0 ] || die "no installers found for version $version — nothing to release"

case "$seen_platforms" in
  *windows*) ;;
  *) warn "this release carries NO Windows package" ;;
esac
case "$seen_platforms" in
  *macos*) ;;
  *) warn "this release carries NO macOS package" ;;
esac
case "$seen_platforms" in
  *linux*) ;;
  *) warn "this release carries NO Linux package" ;;
esac

(
  cd dist
  sha256sum EverBox-* > SHA256SUMS.txt
)

jq -r --arg v "$version" --argjson b "$build" '
  "EverBox \($v) (build \($b)) — published \(.releases[$v].date)\n\n" +
  (.releases[$v].changes | map("- **\(.type)**: \(.description)") | join("\n"))
' CHANGELOG.json > dist/release-notes.md

echo "EverBox ${version} (build ${build})" > dist/release-title.txt

echo "staged $found installer(s) for $tag:"
ls -1 dist
