#!/usr/bin/env bash
# Installs the latest Ferrum Launcher on macOS from GitHub Releases:
#   curl -fsSL https://raw.githubusercontent.com/Amygdal-doo/ferrum-releases/main/install.sh | bash
#   scripts/install-launcher.sh [--repo owner/name]
#
# The releases repo's install.sh is a copy of this file (see
# launcher/README.md). Files downloaded with curl carry no quarantine flag,
# so the launcher opens without the "could not verify" Gatekeeper dialog a
# browser download gets. The default repo is public, so only curl is needed.
# For a private repo, sign in with the GitHub CLI (`gh auth login`) and it is
# used instead.
#
# Picks the newest launcher-v* release; before the first one exists, the
# newest toolbox-v* release (Ferrum Launcher's former name). Installs the
# DMG's app, or the .app.tar.gz when the release has no DMG (the toolbox-v*
# bridge), into /Applications, or ~/Applications when /Applications isn't
# writable. An old "Ferrum Toolbox.app" next to it is moved to the Trash.
set -euo pipefail

repo="Amygdal-doo/ferrum-releases"
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) [ $# -ge 2 ] || { echo "usage: $0 [--repo owner/name]" >&2; exit 2; }; repo="$2"; shift 2 ;;
    *) echo "usage: $0 [--repo owner/name]" >&2; exit 2 ;;
  esac
done

[ "$(uname -s)" = "Darwin" ] || { echo "error: this installer is for macOS; on Linux use Ferrum Launcher's .deb or tarball" >&2; exit 1; }
use_gh=false
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then use_gh=true; fi

case "$(uname -m)" in
  arm64) arch="aarch64" ;;
  x86_64) arch="x86_64" ;;
  *) echo "error: unsupported CPU $(uname -m)" >&2; exit 1 ;;
esac
target="$arch-apple-darwin"

# Release tags, newest first (non-draft). Every Ferrum app is in alpha, so
# alpha releases count.
if $use_gh; then
  tags="$(gh release list --repo "$repo" --limit 100 --exclude-drafts --json tagName --jq '.[].tagName')"
else
  tags="$(curl -fsSL "https://api.github.com/repos/$repo/releases?per_page=100" \
    | /usr/bin/python3 -c 'import json,sys
for r in json.load(sys.stdin):
    if not r["draft"]:
        print(r["tag_name"])')" \
    || { echo "error: could not list releases of $repo (private? run: gh auth login)" >&2; exit 1; }
fi
tag="$(printf '%s\n' "$tags" | grep -m1 '^launcher-v' || true)"
[ -n "$tag" ] || tag="$(printf '%s\n' "$tags" | grep -m1 '^toolbox-v' || true)"
[ -n "$tag" ] || { echo "error: no launcher-v* release found in $repo" >&2; exit 1; }
prefix="${tag%%-v*}"
version="${tag#*-v}"
if [ "$prefix" = "launcher" ]; then
  dmg="FerrumLauncher-$version-$arch.dmg"
  app="Ferrum Launcher.app"
else
  dmg="FerrumToolbox-$version-$arch.dmg"
  app="Ferrum Toolbox.app"
fi
archive="$prefix-$version-$target.app.tar.gz"
echo "Installing Ferrum Launcher $version ($arch) from $repo…"

work="$(mktemp -d)"
mount=""
cleanup() {
  [ -n "$mount" ] && hdiutil detach -quiet "$mount" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

# Downloads <asset> (and its .sha256 when published) into $work; fails if
# the asset doesn't exist.
fetch() {
  if $use_gh; then
    gh release download "$tag" --repo "$repo" --dir "$work" --pattern "$1" --pattern "$1.sha256" 2>/dev/null \
      && [ -f "$work/$1" ]
  else
    local base="https://github.com/$repo/releases/download/$tag"
    curl -fL --progress-bar -o "$work/$1" "$base/$1" || { rm -f "$work/$1"; return 1; }
    curl -fsSL -o "$work/$1.sha256" "$base/$1.sha256" || rm -f "$work/$1.sha256"
  fi
}
verify() {
  if [ -f "$work/$1.sha256" ]; then
    expected="$(awk '{print $1}' "$work/$1.sha256")"
    actual="$(shasum -a 256 "$work/$1" | awk '{print $1}')"
    [ "$expected" = "$actual" ] || { echo "error: checksum mismatch for $1" >&2; exit 1; }
  fi
}

source_app=""
if fetch "$dmg"; then
  verify "$dmg"
  mount="$(mktemp -d)"
  hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mount" "$work/$dmg"
  source_app="$mount/$app"
elif fetch "$archive"; then
  verify "$archive"
  mkdir -p "$work/unpacked"
  tar -xzf "$work/$archive" -C "$work/unpacked"
  source_app="$(find "$work/unpacked" -maxdepth 1 -name '*.app' -type d | head -1)"
fi
[ -n "$source_app" ] && [ -d "$source_app" ] \
  || { echo "error: $tag has neither $dmg nor $archive" >&2; exit 1; }

destination="/Applications"
[ -w "$destination" ] || { destination="$HOME/Applications"; mkdir -p "$destination"; }
installed="$destination/$(basename "$source_app")"
rm -rf "$installed"
cp -R "$source_app" "$installed"
# Downloaded by gh/curl, not a browser, but clear quarantine in case it was set.
xattr -dr com.apple.quarantine "$installed" 2>/dev/null || true

# Ferrum Toolbox is the same app under its old name; its data moves to the
# launcher on first start. Move the old bundle to the Trash (recoverable).
for old in "/Applications/Ferrum Toolbox.app" "$HOME/Applications/Ferrum Toolbox.app"; do
  if [ "$old" != "$installed" ] && [ -d "$old" ] && [ -w "$(dirname "$old")" ]; then
    mkdir -p "$HOME/.Trash"
    mv "$old" "$HOME/.Trash/Ferrum Toolbox $(date +%Y%m%d%H%M%S).app" \
      && echo "Moved the old $old to the Trash."
  fi
done

echo "Installed: $installed"
open "$installed"
