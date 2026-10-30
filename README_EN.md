<h1 align="left" style="border-bottom: none; margin: 0">
  <img src="Assets/logo.gif" width="55" alt="KimiCodeBar Logo" align="absmiddle">&nbsp;&nbsp;KimiCodeBar Custom Edition
</h1>
<p align="left">
  <a href="https://github.com/SuperHaoHaoHao/KimiCodeBar/releases"><img src="https://img.shields.io/badge/version-1.8.0-333333" alt="Version"></a>
 <img src="https://img.shields.io/badge/macOS-333333?logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/-Independent%20Custom%20Edition-orange" alt="Independent Custom Edition">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/SuperHaoHaoHao/KimiCodeBar" alt="License"></a>
</p>

[中文](README.md) | English

An **independent customized Fork** of [**xifandev/KimiCodeBar**](https://github.com/xifandev/KimiCodeBar).

The original project is a lightweight menu-bar usage monitor for Kimi Code. This repository preserves the original author's technology stack, UI, interactions, and feature-design style while adding custom features, calculation logic, and internal release capabilities for personal requirements.

## Fork Origin and Maintenance

- **Original author and source:** Thanks to [@xifandev](https://github.com/xifandev) for open-sourcing [KimiCodeBar](https://github.com/xifandev/KimiCodeBar), which provides the starting point for this repository.
- **Independent maintenance:** This Fork is maintained independently by [@SuperHaoHaoHao](https://github.com/SuperHaoHaoHao), and all custom changes remain here.
- **No impact on the original project:** Changes in this repository do not modify or affect the original author's software or future iterations, and do not imply maintenance or endorsement by the original author.
- **No automatic upstream syncing:** New upstream commits are not merged automatically. Upstream improvements may be reviewed and selectively adopted manually when needed.
- **No upstream overwrite:** The original Sparkle update feed is disabled. This customized edition is updated by building and distributing a new DMG.

🌐 **Original project website:** [https://xifandev.github.io/KimiCodeBar/](https://xifandev.github.io/KimiCodeBar/)

#

#### Custom macOS downloads: <a href="https://github.com/SuperHaoHaoHao/KimiCodeBar/releases">GitHub Releases</a>
#### Original Windows edition: <a href="https://github.com/JYH1878/KimiCodeBar-Windows/releases">GitHub Releases</a> (Maintained by @JYH1878; not part of this customized edition)

#### Feedback for this Fork: <a href="https://github.com/SuperHaoHaoHao/KimiCodeBar/issues">Issues</a>

#

## Current Customizations

- Preserve the original menu-bar quota monitoring, multi-account support, usage statistics, skill management, and visual style.
- Add QR authorization for monthly subscriptions, unified monthly/weekly/5-hour quotas, and a Kimi/Code monthly usage breakdown.
- Add an 8-day weekly rhythm, daily average limits, today's remaining quota in the menu bar, and exact reset dates.
- Support Xcode development, Ad Hoc signing, and DMG packaging without a paid Apple Developer certificate.
- Build and publish customized DMG installers through this repository's GitHub Actions for personal and internal team use.
- Disable upstream automatic updates so future features evolve independently of the original author's releases.

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

Account and statistics data stays on the local machine. Network requests are used for platform authorization, quota queries, and required official APIs. Local account data is never included in a DMG, and the source code remains open.

#

### 🛠 Platform Support

- macOS (this customized edition)
- Windows (not currently included in this Fork; the original Windows edition is maintained by @JYH1878)

#

## Local Development and Releases

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

## 📄 License

This customized edition remains under the [MIT License](LICENSE). You may use, copy, modify, and distribute it, provided that the original copyright notice and license text are retained.

## 🙏 Acknowledgements

- Thanks to [@xifandev](https://github.com/xifandev) for creating and open-sourcing [KimiCodeBar](https://github.com/xifandev/KimiCodeBar).
- Thanks to [CodexBar](https://github.com/AidenYang1/CodexBar).
- Thanks to [Kimi Code](https://github.com/MoonshotAI/kimi-code).
