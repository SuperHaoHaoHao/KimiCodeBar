<h1 align="left" style="border-bottom: none; margin: 0">
  <img src="Assets/logo.gif" width="55" alt="KimiCodeBar Logo" align="absmiddle">&nbsp;&nbsp;KimiCodeBar
</h1>
<p align="left">
  <a href="https://github.com/xifandev/KimiCodeBar/releases"><img src="https://img.shields.io/badge/version-1.2.0-333333" alt="Version"></a>
 <img src="https://img.shields.io/badge/macOS-333333?logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/-KIMI%20Community%20Edition-orange" alt="Community Edition">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/xifandev/KimiCodeBar" alt="License"></a>
</p>

🌐 **Website:** [https://xifandev.github.io/KimiCodeBar/](https://xifandev.github.io/KimiCodeBar/)

A lightweight usage monitoring tool built for [Kimi Code](https://www.kimi.com/code). It runs quietly in your menu bar, so your quota is always at a glance!

#

#### Download (macOS): <a href="https://github.com/xifandev/KimiCodeBar/releases">GitHub Releases</a>
#### Download (Windows): <a href="https://github.com/JYH1878/KimiCodeBar-Windows/releases">GitHub Releases</a> (Maintained by @JYH1878)

#### Feedback: <a href="https://github.com/xifandev/KimiCodeBar/issues">Issues</a>

#

### 👇 Real-time menu bar monitoring

<img src="Assets/menu-bar.png" width="400" alt="Menu bar usage overview">

### ✨ Menu bar popup panel

<p align="left" style="display: flex; gap: 20px; ">
  <img src="Assets/panel-01.png"   height="400" alt="Dark mode">
  <img src="Assets/panel-02.png"  height="400" alt="Light mode">
</p>

### ✨ Quick login with Kimi

Using official Kimi Code APIs, supports one-click browser authorization login. The API Key login method is also kept available and can be switched freely in settings.

### ✨ Auto-detect KimiCode updates

  <img src="Assets/newtip.png" width="400"  alt="Update notification">
 <img src="Assets/msg.png" width="400"  alt="Update notification">

#

### 🔒 Privacy & Security

All data is stored locally. APIs only communicate with official Kimi servers. The full source code is open.

#

### 🛠 Platform Support

- macOS (Released)
- Windows (Released, maintained by @JYH1878)

#

## Independent Fork: Local Development and Releases

This repository is maintained as an independent customized version. It does not automatically sync with upstream or download updates from the upstream update feed.

### Run with Xcode

```bash
open macOS/KimiCodeBar.xcodeproj
```

Select the `KimiCodeBar` scheme and `My Mac` in Xcode, then press `Command + R`. Debug builds use Ad Hoc local signing and do not require a paid Apple Developer certificate.

### Build a DMG locally

```bash
./scripts/build-local.sh
```

The installer is saved as `dist/KimiCodeBar-local-macOS.dmg`. You can also run `./scripts/build-local.sh vX.Y.Z` to set the version label in the DMG filename; this does not change the app's internal version.

### Publish with GitHub

After you push a `v*` version tag, GitHub Actions runs the same packaging script and uploads the DMG to this repository's Releases:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

The release workflow uses neither paid certificates nor Apple notarization. If macOS blocks the app on first launch, confirm that the package came from a trusted source, then open `System Settings → Privacy & Security` and click `Open Anyway`. The DMG contains only the app and an Applications shortcut; it never includes local account data.

#

### Feedback 👉 <a href="https://github.com/xifandev/KimiCodeBar/issues">Issues</a>

#

## 📄 License

This project is licensed under the [MIT License](LICENSE). You are free to use, copy, modify, and distribute this project, provided that the original copyright notice (Copyright © 2026 xifandev) and license text are retained.
