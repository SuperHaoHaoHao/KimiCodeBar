<h1 align="left" style="border-bottom: none; margin: 0">
  <img src="Assets/logo.gif" width="55" alt="KimiCodeBar Logo" align="absmiddle">&nbsp;&nbsp;KimiCodeBar
</h1>
<p align="left">
  <a href="https://github.com/xifandev/KimiCodeBar/releases"><img src="https://img.shields.io/badge/version-1.2.0-333333" alt="Version"></a>
 <img src="https://img.shields.io/badge/macOS-333333?logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/-KIMI%E7%A4%BE%E5%8C%BA%E7%89%88-orange" alt="社区版">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/xifandev/KimiCodeBar" alt="License"></a>
</p>

[English](README_EN.md) | 中文

🌐 **官网：** [https://xifandev.github.io/KimiCodeBar/](https://xifandev.github.io/KimiCodeBar/)

专为 Kimi Code 打造的用量监控小工具，在菜单中轻量化运行，限额一目了然！

#

#### macOS 版下载：<a href="https://github.com/xifandev/KimiCodeBar/releases">GitHub Releases</a>
#### Windows 版下载：<a href="https://github.com/JYH1878/KimiCodeBar-Windows/releases">GitHub Releases</a>（由 @JYH1878 维护）

#### 欢迎提交：<a href="https://github.com/xifandev/KimiCodeBar/issues">Issues</a> 反馈问题或建议

#

### 👇 菜单栏实时监控

<img src="Assets/menu-bar.png" width="400" alt="菜单栏用量速览">

### ✨ 菜单栏弹出小面板

<p align="left" style="display: flex; gap: 20px; ">
  <img src="Assets/panel-01.png"   height="400" alt="暗夜模式">
  <img src="Assets/panel-02.png"  height="400" alt="浅色模式">
</p>

### ✨ 支持Kimi快速登录

采用KimiCode官方接口，支持浏览器一键授权登录，同时也保留 API Key 登录方式，可在设置中自由切换。

### ✨ 自动探测 KimiCode 更新

  <img src="Assets/newtip.png" width="400"  alt="更新提醒">
 <img src="Assets/msg.png" width="400"  alt="更新提醒">

#

### 🔒 隐私安全

数据仅本地存储，所有 API 只与 Kimi 官方通信，代码全部开源。

#

### 🛠 系统适配

- macOS（已发布）
- Windows（已发布，由 @JYH1878 维护）

#

## 独立定制版：本地开发与发布

本仓库作为独立定制版维护，不自动同步上游，也不会从上游更新源下载和覆盖当前版本。

### 使用 Xcode 运行

```bash
open macOS/KimiCodeBar.xcodeproj
```

在 Xcode 中选择 `KimiCodeBar` scheme 和 `My Mac`，按 `Command + R` 运行。Debug 使用 Ad Hoc 本地签名，不需要付费 Apple Developer 证书。

### 在本地生成 DMG

```bash
./scripts/build-local.sh
```

安装包输出到 `dist/KimiCodeBar-local-macOS.dmg`。也可以执行 `./scripts/build-local.sh vX.Y.Z` 指定安装包文件名中的版本标记；它不会修改 App 内部版本号。

### 通过 GitHub 自动发布

推送 `v*` 格式的版本标签后，GitHub Actions 会执行同一个打包脚本，并将 DMG 上传到当前仓库的 Releases：

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

发布流程不使用付费证书或 Apple 公证。同事首次打开 App 时，如果被 macOS 拦截，请确认安装包来自你，然后前往「系统设置 → 隐私与安全性」，点击「仍要打开」。DMG 只包含 App 和 Applications 安装快捷方式，不会包含本机账号数据。

#

### 欢迎提交 👉 <a href="https://github.com/xifandev/KimiCodeBar/issues">Issues</a> 反馈问题或建议

#

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 开源。你可以自由使用、复制、修改和分发本项目，但需要保留版权声明 [@xifandev](https://github.com/xifandev)

## 🙏 致谢

- 感谢 [CodexBar](https://github.com/AidenYang1/CodexBar)。
- 感谢 [Kimi Code](https://github.com/MoonshotAI/kimi-code)。
