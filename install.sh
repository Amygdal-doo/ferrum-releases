#!/usr/bin/env bash
# Installs the latest Ferrum Toolbox on macOS from GitHub Releases:
#   curl -fsSL https://raw.githubusercontent.com/Amygdal-doo/ferrum-releases/main/install.sh | bash
#   scripts/install-toolbox.sh [--repo owner/name]
#
# Files downloaded with curl carry no quarantine flag, so the toolbox opens
# without the "could not verify" Gatekeeper dialog a browser download gets.
# The default repo is public, so only curl is needed. For a private repo,
# sign in with the GitHub CLI (`gh auth login`) and it is used instead.
# Installs "Ferrum Toolbox.app" into /Applications, or ~/Applications when
# /Applications isn't writable.
set -euo pipefail

repo="Amygdal-doo/ferrum-releases"
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) [ $# -ge 2 ] || { echo "usage: $0 [--repo owner/name]" >&2; exit 2; }; repo="$2"; shift 2 ;;
    *) echo "usage: $0 [--repo owner/name]" >&2; exit 2 ;;
  esac
done

[ "$(uname -s)" = "Darwin" ] || { echo "error: this installer is for macOS; on Linux use FerrumToolbox's tarball" >&2; exit 1; }
use_gh=false
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then use_gh=true; fi

case "$(uname -m)" in
  arm64) arch="aarch64" ;;
  x86_64) arch="x86_64" ;;
  *) echo "error: unsupported CPU $(uname -m)" >&2; exit 1 ;;
esac

# Newest non-draft toolbox-v* release. Every Ferrum app is in alpha, so
# alpha releases count.
if $use_gh; then
  tag="$(gh release list --repo "$repo" --limit 100 --exclude-drafts \
    --json tagName --jq '[.[].tagName | select(startswith("toolbox-v"))] | first // empty')"
else
  tag="$(curl -fsSL "https://api.github.com/repos/$repo/releases?per_page=100" \
    | /usr/bin/python3 -c 'import json,sys
for r in json.load(sys.stdin):
    if r["tag_name"].startswith("toolbox-v") and not r["draft"]:
        print(r["tag_name"]); break')" \
    || { echo "error: could not list releases of $repo (private? run: gh auth login)" >&2; exit 1; }
fi
[ -n "$tag" ] || { echo "error: no toolbox-v* release found in $repo" >&2; exit 1; }
version="${tag#toolbox-v}"
dmg="FerrumToolbox-$version-$arch.dmg"
echo "Installing Ferrum Toolbox $version ($arch) from $repo…"

work="$(mktemp -d)"
mount=""
cleanup() {
  [ -n "$mount" ] && hdiutil detach -quiet "$mount" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

if $use_gh; then
  gh release download "$tag" --repo "$repo" --dir "$work" --pattern "$dmg" --pattern "$dmg.sha256"
else
  base="https://github.com/$repo/releases/download/$tag"
  curl -fL --progress-bar -o "$work/$dmg" "$base/$dmg"
  curl -fsSL -o "$work/$dmg.sha256" "$base/$dmg.sha256" || rm -f "$work/$dmg.sha256"
fi
if [ -f "$work/$dmg.sha256" ]; then
  expected="$(awk '{print $1}' "$work/$dmg.sha256")"
  actual="$(shasum -a 256 "$work/$dmg" | awk '{print $1}')"
  [ "$expected" = "$actual" ] || { echo "error: checksum mismatch for $dmg" >&2; exit 1; }
fi

mount="$(mktemp -d)"
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mount" "$work/$dmg"

destination="/Applications"
[ -w "$destination" ] || { destination="$HOME/Applications"; mkdir -p "$destination"; }
rm -rf "$destination/Ferrum Toolbox.app"
cp -R "$mount/Ferrum Toolbox.app" "$destination/"
# Downloaded by gh/curl, not a browser, but clear quarantine in case it was set.
xattr -dr com.apple.quarantine "$destination/Ferrum Toolbox.app" 2>/dev/null || true

echo "Installed: $destination/Ferrum Toolbox.app"
open "$destination/Ferrum Toolbox.app"
