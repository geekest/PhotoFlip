# PhotoFlip SwiftUI 视觉系统重设计

## 1. 任务目标

在不改变 PhotoFlip 主要照片整理、滑动决策、撤销、收藏、删除和统计功能的前提下，参照 Apple Human Interface Guidelines 对现有 iOS SwiftUI 界面做一轮视觉与交互层重设计。完成后应形成清晰的视觉层级、统一的系统组件语言、可理解的状态反馈和更完整的辅助功能语义，并以独立分支、分阶段中文 commit 和中文 PR 交付。

## 2. 当前状态

- 仓库：`/Users/geekest/PhotoFlip`，当前分支为 `codex/redesign-visual`，基线来自 `main`，初始工作区干净。
- 技术栈：SwiftUI、Photos Framework、Swift Concurrency，最低 iOS 17.6，当前工程配置支持 iOS 17+。
- 顶层调用链：`PhotoFlipApp` 注入 `AppState` 与 `PhotoLibraryManager` → `ContentView` 根据权限展示 `PermissionView` 或三标签 `LibraryView`、`SwipeSessionView`、`SettingsView`。
- 整理链路：`SwipeSessionView` 管理会话和模式选择，`SwipeSessionViewModel` 处理决策、撤销、收藏与统计，卡片/详情/完成状态分别由 Swipe 目录中的视图负责。
- 图库链路：`LibraryView` 负责照片分组、搜索、统计、待删除提示和详情呈现；设置和权限由独立页面负责。
- 初步问题：页面之间缺少统一的视觉令牌；部分页面自定义颜色、字号、圆角和间距不一致；顶层导航和主要动作层级不够清晰；复杂状态、空状态、处理中状态和辅助描述需要系统化检查。
- 验证基线：仓库没有发现现成测试目录；当前 shell 默认指向 CommandLineTools，但 `/Applications/Xcode.app` 存在，可用 `DEVELOPER_DIR` 显式验证工程。

## 3. 目标状态

- 使用统一的 SwiftUI 视觉令牌（系统颜色、系统文本样式、间距、圆角、阴影/材质策略）表达品牌而不替换平台惯例。
- 保留三项顶层任务入口，使用清晰的标签、SF Symbols 和选中状态；整理页突出当前任务和决策动作，图库页突出内容浏览，设置页保持低频配置属性。
- 统一按钮、卡片、工具栏、提示、空状态、加载状态和完成状态的视觉与交互反馈；危险删除动作保持明显但不喧宾夺主。
- 保留所有既有数据流、状态机和相册操作；仅调整呈现、布局、标签、辅助描述和必要的交互反馈。
- 支持浅色/深色外观、动态字体、VoiceOver 的基本语义和非颜色状态识别。

## 4. 范围边界

### 本次包括

- `ContentView` 的顶层导航视觉与语义。
- 权限页、图库页、设置页的视觉系统和交互呈现。
- 整理页、卡片、决策提示、模式选择、详情页和完成状态的视觉层。
- 统一的本地视觉令牌与可访问性修正。
- 分阶段提交 commit、构建验证、差异审查和 PR。

### 本次不包括

- 不修改照片读取、收藏、删除、视频播放、数据持久化和会话决策算法。
- 不新增第三方依赖、不修改数据库/权限配置/生产配置、不替换 App 图标。
- 不新增产品功能；若发现现有功能缺陷，只保留与视觉交互直接相关且低风险的修正，并记录在复盘中。

## 5. 影响文件

- `PhotoFlip/PhotoFlip/ContentView.swift`：顶层标签导航与统一背景策略。
- `PhotoFlip/PhotoFlip/Views/Permission/PermissionView.swift`：权限状态的首屏层级与 CTA。
- `PhotoFlip/PhotoFlip/Views/Library/LibraryView.swift`：图库浏览、搜索、统计、待删除状态和详情入口。
- `PhotoFlip/PhotoFlip/Views/Settings/SettingsView.swift`：设置分组、选项和说明。
- `PhotoFlip/PhotoFlip/Views/Swipe/*.swift`：整理主流程的卡片、动作、模式、详情和完成状态。
- 可能新增 `PhotoFlip/PhotoFlip/Views/Shared/` 或相邻视图文件：只承载纯视觉复用组件，不移动业务逻辑。

## 6. 执行里程碑

### Milestone 1：理解现有实现与建立视觉基线

要做：完成仓库规则、调用链、所有主要 SwiftUI 视图和 Apple HIG 相关章节审查，记录当前问题与不变功能边界。

验证：能够列出每个核心状态的入口、动作和数据依赖；工程可用 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 进行构建检查。

完成标准：本计划的当前状态、范围和验收清单已具体化。

### Milestone 2：建立视觉系统与顶层壳层

要做：新增最小化视觉令牌，统一顶层标签导航、背景、系统文本样式、语义颜色和主要按钮层级；不触碰业务状态。

验证：构建工程，检查浅色/深色和动态字体相关代码；确认三标签仍能切换且保持原有入口。

完成标准：壳层与基础组件完成一个独立中文 commit。

### Milestone 3：重设计图库、权限和设置

要做：优化首屏层级、搜索、统计、分组网格、空/加载/待删除状态、详情入口、权限 CTA 和设置分组；补充必要的辅助标签与动作文案。

验证：构建工程；逐项走查权限、图库搜索/详情、待删除提示、设置修改路径；确认状态仍由原有数据源驱动。

完成标准：内容与配置页面完成一个独立中文 commit。

### Milestone 4：重设计整理主流程与状态反馈

要做：优化整理任务头部、进度、卡片层级、决策动作、撤销、模式选择、视频/照片详情和完成状态；保持 `SwipeSessionViewModel` 以及所有决策语义不变。

验证：构建工程；检查未开始、进行中、空批次、完成、撤销、待删除和错误/处理中状态；确认动作标签、图标和 VoiceOver 语义不依赖颜色。

完成标准：整理主流程完成一个独立中文 commit。

### Milestone 5：整体验证、复盘与 PR

要做：运行构建/可用测试/静态检查，审查 diff 和提交历史，补充未验证项；按仓库 PR 规范创建中文 PR，不合并。

验证：记录成功命令、失败原因、模拟器/真机覆盖边界、工作区状态和 PR 地址。

完成标准：分支干净或只保留明确未提交内容；PR 标题、描述、commit 均为中文。

## 7. 进度记录

- [x] 阅读仓库规则、README、工程配置和相关 SwiftUI 源码
- [x] 阅读 Apple HIG 视觉、布局、导航、内容、按钮、呈现和输入相关快照
- [x] 创建独立分支
- [x] 完成执行计划
- [x] 建立视觉系统与顶层壳层
- [ ] 完成图库、权限和设置重设计
- [ ] 完成整理主流程与状态反馈重设计
- [ ] 构建与人工走查
- [ ] 分阶段提交中文 commit
- [ ] 创建中文 PR
- [ ] 完成复盘

## 8. 新发现与意外情况

- 发现：仓库 README 中列出 `ReviewViewModel` 等路径，但当前工作树未发现对应文件，实际逻辑主要集中在现有 Swipe 视图和 `SwipeSessionViewModel`。
- 影响：重设计需以当前工作树为准，不能按 README 目录假设新增或移动业务层。
- 处理方式：保持现有调用链不变，仅在视图层做视觉和交互层调整，并在最终复盘说明 README 与实际目录的差异。

## 9. 决策记录

### Decision：采用系统语义优先的轻量视觉系统

选择：使用系统颜色、系统文本样式、SF Symbols、标准 `Button` / `Label` / `Toolbar` / `ContentUnavailableView` 等 SwiftUI 语义，并以少量本地令牌统一间距、圆角和卡片层级。

原因：符合 Apple HIG 对可读性、深色模式、动态字体、辅助功能和平台惯例的要求，同时降低业务行为回归风险。

备选方案：全局自定义颜色和自绘控件；视觉可控性更强，但会增加深色模式、对比度、触控目标和辅助功能维护成本，本次不采用。

影响：产品个性主要通过内容层级、克制的强调色和照片内容表达，不通过替换系统交互组件表达。

## 10. 验证计划

- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project PhotoFlip/PhotoFlip.xcodeproj -scheme PhotoFlip -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO`：确认工程可编译。
- 如工程提供可运行测试，执行对应 `xcodebuild test`；若无测试目标，明确记录未覆盖。
- `git diff --check`：确认无空白错误。
- `git diff --stat` 与 `git diff`：检查范围、重复逻辑、危险操作和业务调用是否未被改动。
- 人工走查：权限 → 进入整理 → 选择照片/视频 → 撤销 → 完成 → 查看图库/详情 → 设置；分别检查浅色/深色、动态字体和 VoiceOver 可读语义（能运行模拟器时）。

## 11. 风险与回滚

- 可能风险：重排布局影响小屏幕、动态字体或长文案；自定义材质/颜色在深色模式下对比度不足；整理页视觉改动误触业务动作。
- 控制方式：优先系统组件和语义颜色，避免硬编码尺寸；每个阶段独立 commit，逐阶段构建并审查业务调用差异。
- 回滚方式：按阶段 revert 对应中文 commit，或从 `main` 重新比较各阶段 diff；不执行破坏性 git 操作。
