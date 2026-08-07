# yahuo Homebrew Tap

Public Homebrew casks and release assets for `yahuo` packages.

## Install

### macOS

```sh
brew install --cask yahuo/tap/ssdev-cairn
```

Using the fully qualified cask name adds this tap automatically and trusts only
the requested package.

### Windows

Install Git for Windows, then run this command in PowerShell:

```powershell
irm https://raw.githubusercontent.com/yahuo/homebrew-tap/master/install.ps1 | iex
```

The public installer is pinned to the latest published ssdev-cairn release,
verifies the selected Windows archive against `checksums.txt`, and updates
the user `PATH` idempotently.

## Packages

| Package | Description |
| --- | --- |
| `ssdev-cairn` | Adds local AI coding context to Git commit messages. |

Release tags are product-prefixed so this repository can distribute multiple
independently versioned packages. Every downloadable archive has an entry in
the release's `checksums.txt`.
