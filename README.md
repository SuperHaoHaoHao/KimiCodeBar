<h1 align="left" style="border-bottom: none; margin: 0">
  <img src="Assets/logo.gif" width="55" alt="KimiCodeBar Logo" align="absmiddle">&nbsp;&nbsp;KimiCodeBar 定制版
</h1>
<p align="left">
  <a href="https://github.com/SuperHaoHaoHao/KimiCodeBar/releases"><img src="https://img.shields.io/badge/version-1.7.2-333333" alt="Version"></a>
 <img src="https://img.shields.io/badge/macOS-333333?logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/-%E7%8B%AC%E7%AB%8B%E5%AE%9A%E5%88%B6%E7%89%88-orange" alt="独立定制版">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/SuperHaoHaoHao/KimiCodeBar" alt="License"></a>
</p>

[English](README_EN.md) | 中文

基于 [**xifandev/KimiCodeBar**](https://github.com/xifandev/KimiCodeBar) 的**独立 Fork 定制版本**。

原项目是一款专为 Kimi Code 打造的轻量级菜单栏用量监控工具。本仓库在保留原作者技术栈、UI、交互与功能设计风格的基础上，仅根据自己的使用需求增加定制化功能、计算逻辑和内部发布能力。

## Fork 来源与维护关系

- **原作者与来源：** 感谢 [@xifandev](https://github.com/xifandev) 开源 [KimiCodeBar](https://github.com/xifandev/KimiCodeBar)，本仓库以其公开源代码为起点。
- **独立维护：** 本仓库由 [@SuperHaoHaoHao](https://github.com/SuperHaoHaoHao) 独立维护，定制修改只发生在这个 Fork 中。
- **不影响原作者项目：** 这里的修改不会反向改变或影响原作者的软件和后续迭代，也不代表原作者对本定制版提供维护或背书。
- **不自动跟随上游：** 不自动同步原作者的新提交；作者后续更新不会自动进入本仓库。如需参考上游改进，会人工评估后选择性吸收。
- **不被上游覆盖：** 已关闭原作者 Sparkle 更新源，本定制版通过重新构建和分发 DMG 更新。

🌐 **原项目官网：** [https://xifandev.github.io/KimiCodeBar/](https://xifandev.github.io/KimiCodeBar/)

#

#### 定制版 macOS 下载：<a href="https://github.com/SuperHaoHaoHao/KimiCodeBar/releases">GitHub Releases</a>
#### 原项目 Windows 版：<a href="https://github.com/JYH1878/KimiCodeBar-Windows/releases">GitHub Releases</a>（由 @JYH1878 维护，不属于本定制版）

#### 定制版反馈：<a href="https://github.com/SuperHaoHaoHao/KimiCodeBar/issues">Issues</a>

#

## 当前定制内容

- 保留原项目的菜单栏配额监控、多账号、用量统计、技能管理等功能与界面风格。
- 支持无付费 Apple Developer 证书的 Xcode 本地开发、Ad Hoc 签名与 DMG 打包。
- 支持通过本仓库 GitHub Actions 构建并发布定制版 DMG，方便个人及同事内部使用。
- 停用上游自动更新，后续功能由本仓库独立迭代，不随原作者版本自动变化。

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

账号与统计数据仅保存在本机。网络请求用于对应平台的授权、配额查询及必要的官方接口调用，不会通过 DMG 分发本机账号数据，源代码全部公开。

#

### 🛠 系统适配

- macOS（本定制版）
- Windows（本定制版暂未包含；原项目 Windows 版由 @JYH1878 维护）

#

## 本地开发与发布

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

发布流程不使用付费证书或 Apple 公证。同事首次打开 App 时，如果被 macOS 拦截，请确认安装包来自可信来源，然后前往「系统设置 → 隐私与安全性」，点击「仍要打开」。DMG 只包含 App 和 Applications 安装快捷方式，不会包含本机账号数据。

#

## 📄 开源协议

本定制版继续采用 [MIT License](LICENSE)。你可以自由使用、复制、修改和分发，但需要保留原作者版权声明及许可文本。

## 🙏 致谢

- 感谢 [@xifandev](https://github.com/xifandev) 创建并开源 [KimiCodeBar](https://github.com/xifandev/KimiCodeBar)。
- 感谢 [CodexBar](https://github.com/AidenYang1/CodexBar)。
- 感谢 [Kimi Code](https://github.com/MoonshotAI/kimi-code)。
