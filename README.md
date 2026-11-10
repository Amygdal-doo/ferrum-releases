# Ferrum releases

Downloads for the Ferrum developer tools by AMYGDAL d.o.o. Sarajevo. This
repository holds release builds only; there is no source code here.

All Ferrum apps are in **alpha**.

## Install

Recommended, in Terminal (Apple Silicon Macs):

```bash
curl -fsSL https://raw.githubusercontent.com/Amygdal-doo/ferrum-releases/main/install.sh | bash
```

It installs the newest Ferrum Launcher into Applications and opens it.
Or download `FerrumLauncher-<version>-aarch64.dmg` from the newest
`launcher-v…` release and drag **Ferrum Launcher** to **Applications**.

Every app is signed with the AMYGDAL d.o.o. Sarajevo Developer ID and
notarized by Apple, so macOS opens them without a warning.

Then install the apps you want from the launcher: Ferrum IDE, FerrumAPI,
FerrumGIT, FerrumData, FerrumTerm, FerrumKit and FerrumDock. New apps show
up in the launcher on their own.

The launcher keeps every app up to date, including itself. No GitHub account
is needed.

Ferrum Launcher was called Ferrum Toolbox up to 0.5.0. Toolbox 0.5.0 updates
itself to the launcher through the `toolbox-v0.6.0` release.

## What's in a release

Releases are tagged `<app>-v<version>` (for example `kit-v0.1.0-alpha.1`). Every
file has a matching `.sha256` checksum. `catalog.json` describes each app
(name, status, logo in `logos/`) and is read by the launcher.
