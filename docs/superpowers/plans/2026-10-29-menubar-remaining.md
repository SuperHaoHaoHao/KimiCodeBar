# 菜单栏今日剩余可用量实施计划

> **执行要求：** 使用 superpowers:executing-plans 在当前会话逐项实施，步骤用复选框跟踪。

**目标：** 将菜单栏今日累计上限改为带正负号的今日剩余可用量，月度更紧张时明确切换月口径，并在设置页展示当前数据算式与逻辑说明。

**架构：** 在现有 `QuotaRhythm.swift` 中集中生成周、月时间上限及最终余量模型，`KimiCodeBarApp.swift` 的三种菜单栏渲染和设置预览共用该模型。月度不做跨分母换算，只在其成为限制来源时显式标注月口径。

**技术栈：** Swift、SwiftUI、AppKit `ImageRenderer`、Xcode String Catalog。

**设计：** `docs/superpowers/specs/2026-10-29-menubar-remaining-design.md`

## 全局约束

- 保留 `7D`、`5H` 两行结构；不修改其他额度卡、其他账号平台或周节奏区。
- 周、月百分比只使用各自额度口径；不新增依赖、不改版本号。
- 项目没有自动化测试体系，不新增测试脚手架；临时验证脚本放在 `/tmp`，完成后删除。
- 所有改动仅保留本地，不执行 `git commit` 或 `git push`。

## 验证重点

- 周/月余量为负数时保留负号，不截断为 0。
- 月余量小于周余量时必须显示“月”口径，不能伪装成周百分比。
- 月度或重置时间缺失时回退周口径，周数据缺失时不显示余量。
- 三种菜单栏样式与设置实时预览必须使用同一结果，不能出现不同算式。

---

### Task 1：统一今日余量计算

**文件：**
- 修改：`macOS/KimiCodeBar/QuotaRhythm.swift:12-20`
- 临时验证：`/tmp/quota_remaining_check.swift`（验证后删除）

**接口：**
- 新增 `QuotaTodayRemaining`，包含 `value: Int`、`limit: Int`、`used: Int`、`isMonthly: Bool`，以及设置算式使用的 `signedText: String`、菜单栏原排版使用的 `menuLabel: String` 和 `menuValueText: String`。
- 新增 `QuotaRhythm.todayRemaining(for:now:calendar:) -> QuotaTodayRemaining?`，供任务 2 的菜单栏和设置页调用。

- [ ] **步骤 1：编写固定时间验证用例**

用固定重置时间和当前时间构造 `KimiQuota`：验证周余量 `57 - 28 = +29`、月余量更紧时选择月口径、负数保持负号、月数据或重置时间缺失时回退周口径、周数据缺失时返回 `nil`。先对当前实现运行，确认因接口不存在而失败。

- [ ] **步骤 2：实现统一计算**

保留现有周时间进度语义，提取可复用的周期时间上限计算；月度按 `resetTime - 30天` 计算。分别得到周、月 `limit - used`，选择较小余量并记录其口径，`signedText` 对非负值加 `+`，负值原样输出。

- [ ] **步骤 3：运行计算用例**

预期上述用例全部通过，尤其确认负值不被 clamp、月度受限时 `isMonthly == true`。

### Task 2：菜单栏与设置页显示

**文件：**
- 修改：`macOS/KimiCodeBar/KimiCodeBarApp.swift:213-219`、`287-480`、`4806-4840`
- 修改：`macOS/KimiCodeBar/Localizable.xcstrings`

**接口：**
- 使用任务 1 的 `QuotaRhythm.todayRemaining(for:now:calendar:)` 与 `QuotaTodayRemaining`。
- 将 `MenuBarTextRenderer.image` 的 `weeklyLimit: Int?` 参数改为 `remaining: QuotaTodayRemaining?`，同步所有调用点。

- [ ] **步骤 1：更新三种菜单栏样式**

默认双行保持原作者 `7D`、`5H` 排版，只把第一行当前周用量替换为余量；月度受限时以同样排版显示 `月 4%`。K 前缀与单行样式也只替换数值，保留原字号、透明度、间距、细空格、5 小时当前用量和其他平台渲染。

- [ ] **步骤 2：更新设置页实时预览与说明**

预览图与菜单栏调用同一余量模型。预览下增加当前算式：周口径为 `周今日余量：57% - 28% = +29%`，月口径为对应 `月今日余量`；再显示小字 `余量 = 今日累计上限 - 当前用量；月度更紧张时显示月口径`。补充 String Catalog 英文翻译，沿用作者字号与动态次要文字颜色。

- [ ] **步骤 3：编译与静态检查**

运行：

```bash
git diff --check && xcodebuild -project macOS/KimiCodeBar.xcodeproj -scheme KimiCodeBar -configuration Debug -derivedDataPath build/DerivedData build
```

预期 `** BUILD SUCCEEDED **`，String Catalog 可正常编译。

- [ ] **步骤 4：通过 Xcode 运行并验收实际显示**

只保留一个 Dev 实例。检查菜单栏与设置实时预览数值一致，确认月度受限标记、正负号和紧凑间距；删除 `/tmp/quota_remaining_check.swift`。不提交、不推送，交由用户验收。
