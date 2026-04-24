# PhotoFlip

> 像刷卡片一样整理你的相册 — 快速、直觉、没有负担。

PhotoFlip 是一款 iOS 原生相册整理应用。通过卡片滑动手势逐张决策，彻底告别"删了可惜、留着占空间"的选择困难。所有操作在本地完成，照片永远不会离开你的设备。

---

## 功能特性

### 卡片手势

| 操作 | 效果 |
|------|------|
| 右滑卡片 | 保留照片 |
| 左滑卡片 | 标记为删除 |
| 点击心形按钮 | 加入系统收藏夹 |

底部操作栏同样提供三个对应按钮，支持不擅长滑动手势的用户。

### 整理流程

- **批量决策**：一次加载最多 500 张，逐张做出保留 / 删除 / 收藏的决定
- **二次确认**：所有照片滑完后，通过确认对话框一键执行批量删除，删除前可随时取消
- **撤销支持**：最多支持 10 步撤销，手滑了也不怕
- **触觉反馈**：保留、删除、收藏三种操作对应不同振动强度
- **会话统计**：每轮完成后展示删除数、保留数、收藏数及用时

### 图库浏览

- 按月份分组展示全部照片，支持按月份关键词搜索
- 标记为待删除的照片在图库中以红色高亮显示
- 点击任意照片进入全屏查看，支持双指缩放和双击放大

### 个性化设置

- **单次整理数量**：可调整每轮会话加载的照片张数（10 — 500 张）
- **显示模式**：支持深色、浅色、跟随系统三种选项，在 app 内独立控制，无需修改系统设置

---

## 截图

> *(截图待添加)*

---

## 技术栈

| 项目 | 说明 |
|------|------|
| 语言 | Swift 6 |
| UI 框架 | SwiftUI（`@Observable`、`NavigationStack`、`LazyVGrid`） |
| 照片框架 | Photos Framework（`PHPhotoLibrary` / `PHAsset`） |
| 并发模型 | Swift Concurrency（`async/await`） |
| 数据持久化 | `@AppStorage`（UserDefaults） |
| 最低系统要求 | iOS 17+ |

---

## 项目结构

```
PhotoFlip/
├── PhotoFlipApp.swift            # 入口，注入全局状态与显示模式偏好
├── ContentView.swift             # 根视图（TabView / 权限引导）
│
├── Models/
│   ├── AppState.swift            # 全局状态（权限、当前批次照片）
│   ├── PhotoItem.swift           # 照片数据模型
│   └── SwipeDecision.swift       # 决策枚举（undecided / keep / delete / favorite）
│
├── ViewModels/
│   └── SwipeSessionViewModel.swift  # 滑动会话逻辑 + 撤销栈
│
├── Managers/
│   ├── PhotoLibraryManager.swift    # Photos 框架封装（拉取、删除、收藏）
│   └── HapticManager.swift          # 触觉反馈
│
├── Utilities/
│   ├── ImageLoader.swift         # 异步图片加载（PHImageManager）
│   └── Extensions.swift          # 颜色定义、AppearanceMode 枚举、Array 安全下标
│
└── Views/
    ├── Swipe/
    │   ├── SwipeSessionView.swift   # 整理主界面（卡片栈 + 进度条 + 操作栏 + 完成统计）
    │   ├── SwipeCardView.swift      # 单张卡片 + 拖拽手势
    │   ├── CardStackView.swift      # 三张卡片堆叠管理（图片预加载）
    │   ├── DecisionOverlay.swift    # 滑动时的"保留 / 删除"角标
    │   └── PhotoDetailView.swift    # 全屏照片查看器（支持缩放）
    ├── Library/
    │   └── LibraryView.swift        # 图库网格视图（按月分组 + 搜索）
    ├── Settings/
    │   └── SettingsView.swift       # 设置界面（整理数量 + 显示模式 + 关于）
    └── Permission/
        └── PermissionView.swift     # 相册权限申请引导页
```

---

## 应用流程

```
权限申请 → 加载照片批次 → 卡片滑动决策 → 确认删除 → 完成统计 → 下一轮
```

1. **权限申请**：首次启动请求相册读写权限，拒绝后可跳转系统设置手动开启
2. **加载批次**：按设置的数量从相册拉取最新照片
3. **卡片决策**：右滑保留，左滑标记删除，点击心形加入收藏；随时可撤销
4. **确认删除**：批次结束后，通过确认对话框批量执行删除（操作不可逆）
5. **完成统计**：展示本轮删除数、保留数、收藏数及用时，可立即开始下一轮

---

## 本地运行

**环境要求**：Xcode 16+，macOS Sonoma 及以上

```bash
git clone https://github.com/geekest/PhotoFlip.git
cd PhotoFlip
open PhotoFlip/PhotoFlip.xcodeproj
```

在 Xcode 中选择目标设备（真机或模拟器，需 iOS 17+），按 `⌘R` 运行。

> **提示**：相册读取权限和实际删除功能需在真机上测试；模拟器可访问系统内置示例图片。

---

## 许可证

[MIT](LICENSE)
