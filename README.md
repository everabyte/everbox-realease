# EverBox Desktop

The official Everabyte backup application for Windows, macOS and Linux.

![EverBox login screen](./screenshot_login.png)

EverBox protects your computer folders by running the backup jobs configured
in your Everabyte account. Files are processed through Everabyte's encrypted
storage pipeline, while incremental backups avoid transferring unchanged
files again.

EverBox is part of the [Everabyte](https://everabyte.com) ecosystem, a cloud
storage platform designed for individuals, teams and businesses.

## Features

- scheduled backups and manual job execution;
- incremental backups based on file content;
- recovery after network interruptions and a persistent upload queue;
- single-process operation, with no separate system service or daemon;
- background operation from the Windows/Linux system tray or macOS menu bar;
- credentials stored in the operating system's native secure store:
  Credential Manager, Keychain or Secret Service;
- execution history, activity logs and sanitized diagnostics;
- support for Windows 10/11, macOS and Linux.

## Requirements

1. An active Everabyte account.
2. An Everabyte API key pair authorized to read buckets, folders and files,
   and to write to the backup scope.
3. A computer compatible with the target operating system.

The **Full Access** preset is recommended for the initial setup. A key limited
to file access cannot create or browse subfolders; in that case, the backup
must target the root of a bucket.

## Downloads — one release, every platform

Every version is published as **one GitHub release** carrying the Windows,
macOS and Linux packages together, plus a `SHA256SUMS.txt` covering them
all. Assets keep **stable, version-independent names**, so the permanent
"latest" links below always serve the newest published build — these are
the links used on [everabyte.com](https://everabyte.com):

| Package | Permanent download link (always the latest release) |
| --- | --- |
| All packages | <https://github.com/everabyte/everbox-realease/releases/latest> |
| Windows (x64) | <https://github.com/everabyte/everbox-realease/releases/latest/download/EverBox-Setup-x64.exe> |
| macOS (Apple Silicon) | <https://github.com/everabyte/everbox-realease/releases/latest/download/EverBox-macOS-arm64.dmg> |
| macOS (Intel) | <https://github.com/everabyte/everbox-realease/releases/latest/download/EverBox-macOS-x64.dmg> |
| Linux (amd64, .deb) | <https://github.com/everabyte/everbox-realease/releases/latest/download/EverBox-Linux-amd64.deb> |
| Linux (amd64, AppImage) | <https://github.com/everabyte/everbox-realease/releases/latest/download/EverBox-Linux-amd64.AppImage> |
| Linux (arm64, .deb) | <https://github.com/everabyte/everbox-realease/releases/latest/download/EverBox-Linux-arm64.deb> |
| Checksums | <https://github.com/everabyte/everbox-realease/releases/latest/download/SHA256SUMS.txt> |

A platform that has no build yet simply has no asset under that name until
its first build; adding a platform to an **existing** release is supported
(see "Publishing a release" below). Verify downloads against
`SHA256SUMS.txt`.

## Installation and first backup

1. Download the package for your operating system from
   [releases/latest](https://github.com/everabyte/everbox-realease/releases/latest)
   or from the Everabyte download page.
2. Verify the signature and checksum published with the package before
   installing it.
3. Launch EverBox and enter the Everabyte endpoint and your API key pair. The
   key is validated before it is stored.
4. Select an authorized bucket and target path.
5. Map local folders to the jobs configured in your Everabyte account, then
   let EverBox follow the schedule.

Closing the window hides the application in the system tray or menu bar; it
does not stop a backup in progress. Use **Quit EverBox** to stop the
application completely. Queue state is preserved so that work can resume at
the next launch.

## Security model

EverBox communicates only with Everabyte. Credentials for third-party storage
providers — such as S3, Wasabi, iDrive or Backblaze — are not used by the
application.

Secrets are stored in the operating system's secure store and are never
written in plain text to a configuration file or displayed in logs. Network
connections use HTTPS. Paths, errors and diagnostic data are validated or
sanitized before they are sent or exported.

Everabyte documents a zero-knowledge storage architecture: encryption keys
are not held by Everabyte, and the platform cannot read the content of
encrypted files. See the [Terms and
Conditions](https://everabyte.com/en/terms-and-conditions) and the [security
documentation](https://everabyte.com/en/help/privacy-compliance) for the
service commitments and applicable limitations.

## Published version

This release corresponds to **EverBox Desktop 1.1.2 (build 13)**. Release
notes and fixes are published with each distributed package — see
[releases](https://github.com/everabyte/everbox-realease/releases) and the
changelog feed ([`CHANGELOG.json`](./CHANGELOG.json)).

Stable asset names per platform (identical in every release):

| Operating system | Asset name |
| --- | --- |
| Windows (x64) | `EverBox-Setup-x64.exe` |
| macOS (Apple Silicon / Intel) | `EverBox-macOS-arm64.dmg` / `EverBox-macOS-x64.dmg` |
| Linux (amd64 / arm64) | `EverBox-Linux-amd64.deb`, `EverBox-Linux-amd64.AppImage`, `EverBox-Linux-arm64.deb` |

## Publishing a release

One version = **one GitHub release** (`v<version>+<build>`, marked latest)
carrying **every platform built for that version**. Publishing runs in two
layers that never interfere:

1. **Public download layer (GitHub Releases)** — the release workflow
   [`.github/workflows/github-release.yml`](.github/workflows/github-release.yml)
   collects the installers from the tagged commit, renames them to the
   stable asset names, generates `SHA256SUMS.txt` and the release notes
   (from `CHANGELOG.json`), then creates the release:

   ```bash
   git tag v1.1.2+13
   git push origin v1.1.2+13        # ← the workflow creates the release
   ```

   A platform built later (macOS, Linux) joins the **same** release: publish
   its package, then re-run the workflow (Actions → github-release → Run
   workflow, same tag) — missing assets are uploaded into the existing
   release. Locally the same result is one command:
   `bash scripts/create-release.sh v1.1.2+13` (requires the `gh` CLI).

2. **Auto-update layer (raw.githubusercontent.com)** — unchanged: the app
   checks `<base>/<platform>/<arch>/stable/latest.json` on the `main`
   branch and pins the download to that same host, so the channel keeps
   serving packages from this repository's git tree.

The full build → publish sequence (from the `agent-backup` repository):

```bash
dart run tool/publish_release.dart --repo <path to this clone> \
    --package dist/everbox-1.1.2.exe \
    --notes "What the version brings"
# then review, commit, push main — and push the tag to create the release:
git add -A && git commit -m "release 1.1.2+13" && git push origin main
git tag v1.1.2+13 && git push origin v1.1.2+13
```

## Automatic updates (in-app channel)

The EverBox application checks for updates **directly in this repository**
(served from `raw.githubusercontent.com`, `main` branch). The layout is
generated by the publishing tool of the `agent-backup` repository at every
build:

```text
CHANGELOG.json                        ← what's new in every version (version + description)
windows/x64/stable/
  latest.json                         ← Windows channel manifest (version, sha256, size)
  1.1.2/everbox.exe                   ← one folder per version
macos/arm64/stable/  (and macos/x64)  ← same, signed disk image (.dmg)
linux/amd64/stable/   (and arm64)     ← same, .deb or AppImage
```

- `CHANGELOG.json` (root) carries the release notes: the application shows
  them ("Release notes" in Settings) and includes them in the
  update-available notification;
- `latest.json` points to the channel installer: the application then offers
  an **automatic** or **manual** installation, at the user's choice;
- the SHA-256 and size published in `latest.json` are computed on the
  actually compiled package — any failed verification blocks the
  installation.

Installers are stored as **regular git files** (NOT Git LFS): the
application downloads them from `raw.githubusercontent.com`, which only
serves the 133-byte LFS pointer for LFS-tracked files — the update's
SHA-256 verification would always fail. This keeps GitHub's 100 MB
per-file limit on the auto-update layer: a larger package must be split or
served from a dedicated base (`EVB_DOWNLOAD_BASE` on the application side).
The GitHub release layer has no such constraint (2 GB per asset).

## Support

- Website: [everabyte.com](https://everabyte.com)
- Help Center: [everabyte.com/en/help](https://everabyte.com/en/help)
- Support: [support@everabyte.com](mailto:support@everabyte.com)
- Key, permission or bucket issues: first check the key scopes and the bucket
  scope configured in Everabyte.

## Copyright

See [`COPYRIGHT.md`](COPYRIGHT.md) for the copyright notice, trademarks and
general distribution terms for the application.

