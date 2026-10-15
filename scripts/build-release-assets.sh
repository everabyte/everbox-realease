#!/usr/bin/env bash
#
# build-release-assets.sh — stage the GitHub-release assets for ONE version
# tag (<version>+<build>, NO "v" prefix) into dist/.
#
# Usage (from the repository root):
#   bash scripts/build-release-assets.sh 1.1.2+13
#
# Inputs — the tag names the version; the packages to stage are looked up
# in the CHECKED-OUT tree under either of the supported layouts (per
# platform+arch, first existing directory wins):
#   <platform>/<arch>/stable/<tag>/       ← layout written by the agent-backup
#   <platform>/<arch>/stable/<version>/     publisher (version, no build)
#   <platform>/stable/<tag>/              ← manual drops (no arch segment,
#   <platform>/stable/<version>/            folder named version or tag)
# plus the root CHANGELOG.json (release notes feed).
#
# Outputs (dist/):
#   EverBox-Setup-x64.exe      ← STABLE, version-independent asset names, so
#   EverBox-macOS-arm64.dmg      https://github.com/everabyte/everbox-realease/releases/latest/download/<asset>
#   EverBox-Linux-amd64.deb      ALWAYS serves the newest build (site links)
#   EverBox-Linux-amd64.rpm    ← every installer found under
#   EverBox-Linux-amd64.AppImage linux/<arch>/stable/<version>/ is picked up
#                                automatically (deb, rpm, AppImage — whichever
#                                formats were built for the version)
#   SHA256SUMS.txt             ← checksums of every installer in this release
#   release-notes.md           ← body of the GitHub release (CHANGELOG.json)
#   release-title.txt          ← "EverBox <version> (build <build>)"
#
# Requires jq + sha256sum (both preinstalled on GitHub ubuntu runners).

set -euo pipefail

die() { echo "build-release-assets: ERROR: $*" >&2; exit 1; }
warn() { echo "build-release-assets: WARNING: $*" >&2; }

tag="${1:-}"
[ -n "$tag" ] || die "usage: build-release-assets.sh <version>+<build> (e.g. 1.1.2+13)"
case "$tag" in
  v*) die "tag must NOT carry the 'v' prefix (owner convention) — got '$tag'" ;;
esac
case "$tag" in
  *+*) version="${tag%%+*}"; build="${tag##*+}" ;;
  *) die "tag must be <version>+<build> (e.g. 1.1.2+13) — got '$tag'" ;;
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

found=0
seen_platforms=""

# stage_dir <platform> <arch> <dir> — copy every installer found in <dir>
# under its stable asset name. Returns 0 when at least one file was staged.
stage_dir() {
  local platform="$1" arch="$2" dir="$3" file name count=0
  [ -d "$dir" ] || return 1
  shopt -s nullglob
  local files=("$dir"/*)
  shopt -u nullglob
  for file in "${files[@]}"; do
    [ -f "$file" ] || continue
    case "$(basename "$file")" in
      README.md|*.json) continue ;; # documentation / channel manifests
    esac
    name="$(stable_name "$platform" "$arch" "$file")"
    [ -e "dist/$name" ] && die "duplicate asset name '$name' (two source directories carry the same platform/arch/format: $dir)"
    cp "$file" "dist/$name"
    echo "asset  $name  <-  $file"
    count=$((count + 1))
    found=$((found + 1))
  done
  [ "$count" -gt 0 ]
}

# Platform/arch search plan. The combo marked "default" also tries the
# arch-less manual layout under its arch name — never two arches for the
# same arch-less directory. Both Linux formats (.deb, .rpm, AppImage) and
# every macOS arch are picked up automatically WHENEVER they exist.
combos=(
  "windows x64 default"
  "macos arm64 default"
  "macos x64"
  "linux amd64 default"
  "linux arm64"
)

for combo in "${combos[@]}"; do
  read -r platform arch kind <<<"$combo"
  dir="${platform}/${arch}/stable/${tag}"
  staged=no
  if stage_dir "$platform" "$arch" "$dir"; then
    staged=yes
  elif stage_dir "$platform" "$arch" "${platform}/${arch}/stable/${version}"; then
    staged=yes
  elif [ "$kind" = "default" ]; then
    # Arch-less manual layout (e.g. linux/stable/<tag>/everbox.deb).
    if stage_dir "$platform" "$arch" "${platform}/stable/${tag}"; then
      staged=yes
    elif stage_dir "$platform" "$arch" "${platform}/stable/${version}"; then
      staged=yes
    fi
  fi
  if [ "$staged" = yes ]; then
    case " $seen_platforms " in
      *" $platform "*) ;;
      *) seen_platforms="$seen_platforms $platform" ;;
    esac
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
