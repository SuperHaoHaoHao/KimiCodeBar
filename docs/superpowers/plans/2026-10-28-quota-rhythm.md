# 额度使用节奏 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按最终草图加入本月/本周额度节奏、重置日期、菜单栏今日周上限和按钮内刷新时间。

**Architecture:** 新建独立 Swift 文件负责周期计算和周节奏 SwiftUI，现有主文件只负责数据接入与卡片顺序。复用 `QuotaDetail`、`KimiCodeBarModel`、动态颜色和 `LText`，不新增依赖。

**Tech Stack:** Swift 5、SwiftUI、AppKit、Xcode String Catalog

**Spec:** `docs/superpowers/specs/2026-10-28-quota-rhythm-design.md`

## Global Constraints

- 保留现有面板模块、交互与作者样式，不新增设置项。
- 所有新用户文案使用中英文本地化；可点击元素保留手型与悬停反馈。
- 项目无自动化测试体系，不新建测试文件；只执行 Debug 编译和静态验证。
- 不改版本号、不打标签、不启动 App，不提交 `.superpowers` 草图。

## Review Focus

- 重置时间缺失或周期已结束时不得除零、崩溃或出现负数；计算任务钳制进度并返回可选值。
- 月度接口没有开始日；按项目30天周期推算，缺月度或重置时间时只降级月列。
- 菜单栏新增文本不得把月度重新加到状态栏，也不得漏掉设置预览；所有调用点传相同周上限。
- 刷新时间只在主账号成功时更新，不能记录点击时间或被其他平台刷新覆盖。
- 极简模式须保持一行8天，经典模式须保持4×2；今天仅用轻阴影，主题色不可硬编码成浅色系。

---

### Task 1: 周期计算与菜单栏

**Files:**
- Create: `macOS/KimiCodeBar/QuotaRhythm.swift`
- Modify: `macOS/KimiCodeBar.xcodeproj/project.pbxproj`
- Modify: `macOS/KimiCodeBar/KimiCodeBarApp.swift:214-218,287-487,4829-4835`

**Interfaces:**
- Produces: `QuotaRhythm.todayWeeklyLimit(for:now:calendar:) -> Int?`，由周重置时间向前推7天，计算当前时刻的累计百分比并钳制为0...100。
- Produces: 周节奏8节点及月度30天推算模型，供 Task 2 使用。

- [ ] **Step 1: 实现无依赖的周期计算**
在 `QuotaRhythm.swift` 建立纯值模型和计算函数，逐日生成8个节点；缺失数据返回 nil 或 `--` 所需的可选值，避免无效时间范围。
- [ ] **Step 2: 接入菜单栏与实时预览**
为 `MenuBarTextRenderer.image` 增加可选周上限参数，默认双行在周百分比后追加 `≤值%`，K前缀和单行采用同一弱色小字；只传周上限，不新增月度。
- [ ] **Step 3: 将新 Swift 文件加入工程 Sources**
按现有 PBX ID 风格增加 FileReference、BuildFile、Group child 和 Sources 条目。
- [ ] **Step 4: 编译验证**
运行 `xcodebuild -project macOS/KimiCodeBar.xcodeproj -scheme KimiCodeBar -configuration Debug -derivedDataPath build/DerivedData build`，预期 `** BUILD SUCCEEDED **`。

### Task 2: 面板周节奏、卡片顺序与刷新时间

**Files:**
- Modify: `macOS/KimiCodeBar/QuotaRhythm.swift`
- Modify: `macOS/KimiCodeBar/KimiCodeBarApp.swift:1126-1167,1440-1512,2224-2473,3239-3287,5720-6128`
- Modify: `macOS/KimiCodeBar/Localizable.xcstrings`

**Interfaces:**
- Consumes: Task 1 的周期模型和 `QuotaRhythm.todayWeeklyLimit`。
- Produces: `WeeklyQuotaRhythmView(quota:style:)`、`ActionButton.detail: String?`、`KimiCodeBarModel.lastSuccessfulRefresh: Date?`。

- [ ] **Step 1: 实现经典与极简周节奏视图**
经典用 LazyVGrid 4列、8色动态低饱和卡片；极简用一行8节点和统一图例。显示具体日期、周/月累计上限和日均值，仅今天加轻阴影。
- [ ] **Step 2: 插入主面板并调整额度卡**
仅在主 Kimi 账号具备周额度和重置时间时，在 `AccountQuotaListView` 与 `LocalUsageCard` 之间插入视图。单账号与多账号顺序调整为本月、本周、5小时，周/月重置文本改为 `MM-dd HH:mm · 原倒计时`。
- [ ] **Step 3: 在刷新按钮内显示成功时间**
扩展 `ActionButton` 可选 detail，保持其他按钮不变且同高；主账号成功获取配额时更新 `lastSuccessfulRefresh`，失败和其他平台不改写。
- [ ] **Step 4: 补齐文案与验证**
为周节奏、日均和周/月短标签加入英文翻译；校验 String Catalog JSON、`git diff --check`，再次运行同一 Debug 构建并确认成功。

### Task 3: 最终审查与推送

**Files:**
- Verify: 上述所有文件及 `git diff`。

- [ ] **Step 1: 对照草图审查最终差异**
确认仅包含约定功能，本机消耗量、按钮和版本区仍在；无临时调试代码、版本号变化或草图文件。
- [ ] **Step 2: 提交并推送**
只暂存本次相关文件，使用中文 Angular 提交信息，执行 `git push origin main`，确认本地和远程 `main` 一致。
