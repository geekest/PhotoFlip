# PhotoFlip

> 像刷 Tinder 一样整理你的相册 — 快速、直觉、没有负担。

PhotoFlip 是一款 iOS 相册整理应用，通过卡片滑动手势让你快速决定每张照片的命运，彻底告别"删了可惜、留着占空间"的选择困难。

---

## 功能特性

| 手势 | 操作 |
|------|------|
| 右滑 | 保留照片 |
| 左滑 | 标记删除 |
| 上滑 | 标记为最爱（同步到系统收藏） |

- **二次确认**：滑完后进入审核界面，删除前可以反悔、逐张撤销标记
- **撤销支持**：最多 10 步撤销，手滑了也不怕
- **触觉反馈**：保留/删除/收藏三种不同的振动反馈
- **会话统计**：完成后展示删除数、保留数、用时

## 截图

> *(可在此处添加应用截图)*

## 技术栈

- **语言**：Swift 6
- **UI 框架**：SwiftUI（`@Observable` 宏、`NavigationStack`、`LazyVGrid`）
- **照片权限**：Photos Framework（`PHPhotoLibrary` / `PHAsset`）
- **并发**：Swift Concurrency（`async/await`）
- **最低系统**：iOS 17+

## 项目结构

```
PhotoFlip/
├── Models/
│   ├── AppState.swift          # 全局导航状态机
│   ├── PhotoItem.swift         # 照片数据模型
│   └── SwipeDecision.swift     # 滑动决策枚举
├── ViewModels/
│   ├── SwipeSessionViewModel.swift  # 滑动会话逻辑 + 撤销栈
│   └── ReviewViewModel.swift        # 审核 & 删除执行逻辑
├── Managers/
│   ├── PhotoLibraryManager.swift    # Photos 框架封装
│   └── HapticManager.swift          # 触觉反馈
├── Utilities/
│   ├── ImageLoader.swift        # 异步图片加载
│   └── Extensions.swift
└── Views/
    ├── Swipe/                   # 滑动会话界面
    ├── Review/                  # 待删除照片审核界面
    ├── Completion/              # 完成统计界面
    └── Permission/              # 相册权限申请界面
```

## 应用流程

```
权限申请 → 加载照片 → 滑动决策 → 审核确认 → 完成统计
```

1. **权限申请**：请求相册读写权限
2. **滑动决策**：逐张浏览，左/右/上滑做决定
3. **审核确认**：查看所有标记为删除的照片，可逐张撤销
4. **执行删除**：确认后通过 `PHPhotoLibrary` 永久删除
5. **完成统计**：展示本轮整理数据

## 本地运行

1. 克隆仓库

   ```bash
   git clone https://github.com/Geekest/PhotoFlip.git
   ```

2. 用 Xcode 打开 `PhotoFlip/PhotoFlip.xcodeproj`

3. 选择真机或模拟器（需 iOS 17+），运行即可

> **注意**：照片权限和实际删除功能需要在真机上测试。

## 许可证

[MIT](LICENSE)
