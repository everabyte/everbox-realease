#!/usr/bin/env bash
#
# tag-release.sh — validate a release and create its immutable Git tag.
#
# Usage (from the repository root):
#   bash scripts/tag-release.sh 1.2.0+16 [--push]
#
# The tag must be created only after the versioned packages and CHANGELOG.json
# are committed. With --push, GitHub Actions receives the tag and creates (or
# refreshes) the corresponding GitHub release, marked as the latest release.

set -euo pipefail

die() { echo "tag-release: ERROR: $*" >&2; exit 1; }

tag="${1:-}"
[ -n "$tag" ] || die "usage: tag-release.sh <version>+<build> [--push]"
shift || true

push=false
while [ $# -gt 0 ]; do
  case "$1" in
    --push) push=true; shift ;;
    *) die "unknown argument: $1" ;;
  esac
done

case "$tag" in
  v*) die "tag must not have a 'v' prefix — use 1.2.0+16, not $tag" ;;
  *+*) version="${tag%%+*}"; build="${tag##*+}" ;;
  *) die "tag must be <version>+<build> (for example 1.2.0+16)" ;;
esac
[ -n "$version" ] && [ -n "$build" ] || die "tag has an empty version or build"
case "$build" in
  *[!0-9]*|'') die "build must be numeric" ;;
esac

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "run this script from the everbox-realease repository"
git diff --quiet || die "working tree has unstaged changes; commit them before tagging"
git diff --cached --quiet || die "index has staged changes; commit them before tagging"
[ -z "$(git ls-files --others --exclude-standard)" ] \
  || die "working tree has untracked files; commit or remove them before tagging"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null \
  && die "tag '$tag' already exists locally"

here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/build-release-assets.sh" "$tag"

git tag -a "$tag" -m "EverBox $version (build $build)"
echo "created tag $tag at $(git rev-parse --short HEAD)"

if [ "$push" = true ]; then
  git remote get-url origin >/dev/null 2>&1 \
    || die "the origin remote is required to push the tag"
  git push origin "$tag"
  echo "pushed $tag — GitHub Actions will publish the latest release"
else
  echo "review the tag, then publish it with: git push origin $tag"
fi
