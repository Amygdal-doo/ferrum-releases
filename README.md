# Ferrum releases

Downloads for the Ferrum developer tools by AMYGDAL d.o.o. Sarajevo. This
repository holds release builds only; there is no source code here.

All Ferrum apps are in **alpha**.

## Install

Recommended, in Terminal (Apple Silicon Macs):

```bash
curl -fsSL https://raw.githubusercontent.com/Amygdal-doo/ferrum-releases/main/install.sh | bash
```

It installs the newest Ferrum Toolbox into Applications and opens it.
Downloads made this way aren't quarantined, so macOS doesn't show the
"could not verify" warning that the not-yet-notarized builds get when
downloaded in a browser.

Or download `FerrumToolbox-<version>-aarch64.dmg` from the newest
`toolbox-v…` release and drag **Ferrum Toolbox** to **Applications**. Then
on first launch: **System Settings → Privacy & Security → Open Anyway**.

Then install the apps you want from the toolbox: Ferrum IDE, FerrumAPI,
FerrumGIT, FerrumData and FerrumTerm.

The toolbox keeps every app up to date, including itself. No GitHub account
is needed.

## What's in a release

Releases are tagged `<app>-v<version>` (for example `data-v0.3.0-alpha.1`). Every
file has a matching `.sha256` checksum. `catalog.json` describes each app's
status and is read by the toolbox.
