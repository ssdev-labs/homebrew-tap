#!/bin/sh

set -eu

version="1.0.1"

fail() {
  printf 'ssdev-cairn: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required."
}

[ "$(uname -s)" = "Linux" ] || fail "This installer only supports Linux."
[ -n "${HOME:-}" ] || fail "HOME is not available."

for command_name in awk curl git grep install mkdir mktemp sha256sum tar uname; do
  require_command "$command_name"
done

if ! printf '%s\n' "$version" |
  grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
  fail "The installer does not contain a valid release version."
fi

machine=$(uname -m)
case "$machine" in
  x86_64 | amd64)
    architecture=amd64
    ;;
  aarch64 | arm64)
    architecture=arm64
    ;;
  *)
    fail "Unsupported Linux architecture: $machine"
    ;;
esac

archive_name="ssdev-cairn_${version}_linux_${architecture}.tar.gz"
release_base_url="https://github.com/ssdev-labs/homebrew-tap/releases/download/ssdev-cairn-v${version}"
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/ssdev-cairn.XXXXXX")
archive_path="${temporary_directory}/${archive_name}"
checksums_path="${temporary_directory}/checksums.txt"
extract_directory="${temporary_directory}/archive"

cleanup() {
  rm -rf "$temporary_directory"
}
trap cleanup 0
trap 'exit 1' 1 2 3 15

curl -fsSL "${release_base_url}/${archive_name}" -o "$archive_path"
curl -fsSL "${release_base_url}/checksums.txt" -o "$checksums_path"

expected_hash=$(
  awk -v expected_name="$archive_name" '
    {
      archive = $2
      sub(/^\*/, "", archive)
      if (archive == expected_name && length($1) == 64 && $1 ~ /^[[:xdigit:]]+$/) {
        matches++
        hash = tolower($1)
      }
    }
    END {
      if (matches == 1) {
        print hash
      } else {
        exit 1
      }
    }
  ' "$checksums_path"
) || fail "checksums.txt does not contain exactly one valid entry for $archive_name."
actual_hash=$(sha256sum "$archive_path" | awk '{ print tolower($1) }')
[ "$actual_hash" = "$expected_hash" ] ||
  fail "SHA-256 mismatch for $archive_name."

mkdir -p "$extract_directory"
tar -xzf "$archive_path" -C "$extract_directory"
staged_executable="${extract_directory}/git-cairn"
[ -f "$staged_executable" ] || fail "$archive_name does not contain git-cairn."

staged_version=$("$staged_executable" version)
[ "$staged_version" = "$version" ] ||
  fail "Downloaded git-cairn reported version '$staged_version'; expected '$version'."

install_directory="${HOME}/.local/bin"
installed_executable="${install_directory}/git-cairn"
mkdir -p "$install_directory"
install -m 0755 "$staged_executable" "$installed_executable"

original_path=${PATH:-}
PATH="${install_directory}${original_path:+:${original_path}}"
export PATH
installed_version=$(git cairn version)
[ "$installed_version" = "$version" ] ||
  fail "git cairn version reported '$installed_version'; expected '$version'."

printf 'Installed ssdev-cairn %s to %s\n' "$version" "$installed_executable"
case ":${original_path}:" in
  *":${install_directory}:"*)
    ;;
  *)
    printf '%s\n' "Add \$HOME/.local/bin to PATH before opening a new terminal."
    printf '%s\n' "For the current shell, run: export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac
