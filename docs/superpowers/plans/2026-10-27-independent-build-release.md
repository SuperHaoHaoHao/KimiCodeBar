# 独立定制版构建与发布基线 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让独立定制版无需付费开发者证书即可在 Xcode 运行、本地生成 DMG，并在推送版本标签后由自己的 GitHub 仓库自动发布 DMG。

**Architecture:** 保留作者现有 SwiftUI 应用结构，只调整构建签名与更新开关。一个 Bash 打包脚本同时服务本地和 GitHub Actions，原发布 Workflow 简化为该脚本的调用方。

**Tech Stack:** Swift 5、SwiftUI、Xcode、Bash、hdiutil、codesign、GitHub Actions

**Spec:** `docs/superpowers/specs/2026-10-27-local-internal-release-design.md`

## Global Constraints

- 不使用 Apple Developer 付费证书，不做 Apple 公证。
- 不改变现有 CPU 架构、版本号和功能 UI。
- 不新增第三方依赖，不读取或提交账号凭证。
- 不自动同步上游，不允许启动、打开面板或手动刷新触发上游更新检查。
- 本次不创建版本标签；真实 GitHub 标签发布留待首次正式发版。
- 项目无自动化测试体系，不新建测试脚手架；以实际编译、签名、DMG 内容和启动结果验证。

## Review Focus

- Debug 配置中的原作者 Team ID 会让无证书 Xcode 构建失败；Task 1 用普通 Debug 构建证明已移除该依赖。
- 仅关闭 Sparkle 自动检查仍会留下手动刷新读取 appcast 的路径；Task 1 同时拦截 Sparkle 与 Model 两条路径。
- 重复打包可能混入旧产物；Task 2 连续运行脚本并检查 DMG 只含 App 与 Applications 快捷方式。
- Ad Hoc 构建不能用 Gatekeeper 评估当作成功标准；Task 2 以 `codesign` 和 `Signature=adhoc` 验证，不要求公证通过。
- 标签 Workflow 若残留原作者 Secrets 或 Pages 权限会在 Fork 失败；Task 3 检查唯一构建入口仅含 checkout、脚本和 Release 上传。

---

### Task 1: 无证书 Xcode 运行与更新隔离

**Files:**
- Modify: `macOS/Configurations/Debug.xcconfig`
- Modify: `macOS/KimiCodeBar.xcodeproj/project.pbxproj:246-273`
- Modify: `macOS/KimiCodeBar/Info.plist:27-34`
- Modify: `macOS/KimiCodeBar/SparkleUpdater.swift`
- Modify: `macOS/KimiCodeBar/KimiCodeBarApp.swift:6986-7025`

**Interfaces:**
- Consumes: 现有 `SUEnableAutomaticChecks`、`SUFeedURL`、`SparkleUpdater.shared` 和 `KimiCodeBarModel.checkForAppUpdate()`。
- Produces: `SparkleUpdater.isEnabled: Bool`，从 Info.plist 的 `SUEnableAutomaticChecks` 读取；所有更新入口在 false 时直接返回。

- [ ] **Step 1: 配置 Debug 本地签名**

在 `Debug.xcconfig` 使用 Manual + Ad Hoc 签名，并移除 `project.pbxproj` Debug 配置中的硬编码 `DEVELOPMENT_TEAM = 5A62S734AD`。不改变 Release 架构和版本号。

- [ ] **Step 2: 默认关闭所有上游更新路径**

将 `SUEnableAutomaticChecks` 设为 false。新增 `SparkleUpdater.isEnabled`，让 Sparkle 初始化不启动更新器，且 `checkForUpdateInformation()`、`showStandardUpdateUI()`、`restartToInstallUpdate()` 在关闭时直接返回；`checkForAppUpdate()` 也在关闭时直接返回，从而覆盖启动、面板打开与手动刷新。

- [ ] **Step 3: 验证普通 Debug 构建与签名**

Run:

```bash
xcodebuild -project macOS/KimiCodeBar.xcodeproj -scheme KimiCodeBar -configuration Debug -derivedDataPath build/DerivedData build
codesign -dv "build/DerivedData/Build/Products/Debug/KimiCodeBar Dev.app"
```

Expected: `** BUILD SUCCEEDED **`，签名信息含 `Signature=adhoc`；命令不再附带 `CODE_SIGNING_ALLOWED=NO`。

- [ ] **Step 4: 提交本任务**

```bash
git add macOS/Configurations/Debug.xcconfig macOS/KimiCodeBar.xcodeproj/project.pbxproj macOS/KimiCodeBar/Info.plist macOS/KimiCodeBar/SparkleUpdater.swift macOS/KimiCodeBar/KimiCodeBarApp.swift
git commit -m "build: 支持无证书开发并停用上游更新"
```

### Task 2: 本地 Ad Hoc DMG 打包脚本

**Files:**
- Create: `scripts/build-local.sh`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: Task 1 的 Xcode 工程与更新配置。
- Produces: `scripts/build-local.sh [版本字符串]`；缺省版本为 `local`，输出 `dist/KimiCodeBar-<版本>-macOS.dmg`，参数只影响 DMG 文件名，不修改 App 版本号。

- [ ] **Step 1: 实现可重复执行的打包脚本**

脚本从任意当前目录定位仓库根，使用 Release + Manual + Ad Hoc 构建，检查 App 存在，使用 `codesign --verify --deep --strict` 校验，重建干净的 DMG staging 目录，仅复制 App 并创建 `/Applications` 链接，最后用 `hdiutil` 输出 DMG。将 `dist/` 加入 `.gitignore`，脚本输出使用中文。

- [ ] **Step 2: 检查脚本语法并实际打包**

Run:

```bash
bash -n scripts/build-local.sh
chmod +x scripts/build-local.sh
./scripts/build-local.sh smoke
./scripts/build-local.sh smoke
```

Expected: 两次均成功，最终存在 `dist/KimiCodeBar-smoke-macOS.dmg`，第二次覆盖同名产物且无 stale staging 错误。

- [ ] **Step 3: 验证签名与 DMG 内容**

Run:

```bash
codesign -dv build/LocalRelease/DerivedData/Build/Products/Release/KimiCodeBar.app
mkdir -p build/DMGVerify
hdiutil attach dist/KimiCodeBar-smoke-macOS.dmg -mountpoint build/DMGVerify -nobrowse -readonly
ls -la build/DMGVerify
hdiutil detach build/DMGVerify
```

Expected: 签名含 `Signature=adhoc`；挂载目录只有 `KimiCodeBar.app` 与 `Applications`，没有 `credentials.json`、扫描状态或其他账号数据。

- [ ] **Step 4: 提交本任务**

```bash
git add .gitignore scripts/build-local.sh
git commit -m "build: 添加本地 DMG 打包脚本"
```

### Task 3: 独立 GitHub Release 与使用说明

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `README.md`
- Modify: `README_EN.md`

**Interfaces:**
- Consumes: Task 2 的 `scripts/build-local.sh [版本字符串]`。
- Produces: 推送 `v*` 标签时，Workflow 以 `${GITHUB_REF_NAME}` 调用脚本并发布 `dist/KimiCodeBar-*-macOS.dmg`。

- [ ] **Step 1: 简化发布 Workflow**

保留 `v*` 标签触发和并发保护，仅申请 `contents: write`。步骤仅包括 checkout、执行 `./scripts/build-local.sh "${GITHUB_REF_NAME}"`、使用现有 `softprops/action-gh-release@v2` 上传 DMG；删除 Pages、证书、公证、Sparkle 工具与 appcast 步骤。

- [ ] **Step 2: 补充中英文使用说明**

在现有 README 中写明 `open macOS/KimiCodeBar.xcodeproj` 后运行 scheme、`./scripts/build-local.sh` 的本地用法、推送 `v*` 标签的发布行为，以及未公证 App 在 macOS「隐私与安全性 → 仍要打开」的首次启动方式。明确不会包含本机账号数据。

- [ ] **Step 3: 静态检查发布配置**

Run:

```bash
git diff --check
bash -n scripts/build-local.sh
```

Expected: 无空白错误或 shell 语法错误；Workflow 不再出现 `secrets.`、`notarytool`、`appcast`、`pages: write` 或 `id-token: write`，Release 文件模式与脚本输出一致。

- [ ] **Step 4: 提交本任务**

```bash
git add .github/workflows/release.yml README.md README_EN.md
git commit -m "ci: 配置独立定制版 DMG 发布"
```

### Task 4: Xcode 启动与交付验证

**Files:**
- Verify only；不新增产品文件。

**Interfaces:**
- Consumes: Tasks 1-3 的全部配置。

- [ ] **Step 1: 验证最终工作区与完整构建**

Run:

```bash
git status --short
xcodebuild -project macOS/KimiCodeBar.xcodeproj -scheme KimiCodeBar -configuration Debug -derivedDataPath build/DerivedData build
```

Expected: 没有未跟踪构建产物进入 Git，最终 Debug 构建成功。

- [ ] **Step 2: 在 Xcode 打开并运行**

Run `open macOS/KimiCodeBar.xcodeproj`，在 Xcode 使用 `KimiCodeBar` scheme 和 My Mac 运行；确认开发版菜单栏 App 启动且不需要付费证书。保留作者现有 UI，不做界面调整。

- [ ] **Step 3: 推送独立定制版基线**

确认提交只包含本设计、计划和上述配置后，执行 `git push origin main`。推送后确认远程 `main` 与本地一致；不创建标签，不触发正式 Release。
