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

## Installation and first backup

1. Download the package for your operating system from the Everabyte download
   page or from the release supplied with this project.
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

This release corresponds to **EverBox Desktop 1.1.2 (build 9)**. Release
notes and fixes are published with each distributed package.

Expected artifacts include:

| Operating system | Typical artifact |
| --- | --- |
| Windows | `everbox.msix` or a Windows installer |
| macOS | `EverBox.app` or a signed disk image |
| Linux | `.deb`, `.rpm` or AppImage package, depending on the distribution |

Names and formats may vary by release. Always use the checksum and signature
files provided with the downloaded version.

## Support

- Website: [everabyte.com](https://everabyte.com)
- Help Center: [everabyte.com/en/help](https://everabyte.com/en/help)
- Support: [support@everabyte.com](mailto:support@everabyte.com)
- Key, permission or bucket issues: first check the key scopes and the bucket
  scope configured in Everabyte.

## Copyright

See [`COPYRIGHT.md`](COPYRIGHT.md) for the copyright notice, trademarks and
general distribution terms for the application.

