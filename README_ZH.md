# Rylai ❄️ (macOS 自动换壁纸)

[English](README.md)

> 基于 Unsplash 的 macOS 自动换壁纸应用，采用 Liquid Glass 设计语言。

## 功能特性

- 🖼️ 自动获取 Unsplash 4K 横屏壁纸
- ⏰ 定时轮换壁纸（5 分钟 ~ 24 小时）
- 🌊 macOS 26 Liquid Glass 界面 + 幽灵按钮体系
- 📂 基于主题的分类选择（自然、建筑、街拍、胶片等）
- ❤️ 收藏壁纸本地保存
- 🖥️ 多显示器支持（独立 / 镜像模式）
- 🌙 深色 / 浅色模式自适应
- 📌 常驻菜单栏，不占 Dock 位

## 截图

![桌面总览](Assets/1.png)

| 主页面 | 分类编辑 | 设置 |
|:---:|:---:|:---:|
| ![主页](Assets/2.png) | ![分类](Assets/3.png) | ![设置](Assets/4.png) |
| 壁纸预览、主题分类、收藏夹 | 最多选择 9 个主题分类 | 自动切换、API Key、多显示器 |

## 快速开始

### 方式一：直接下载（推荐）

1. 前往 [Releases](../../releases) 下载最新的 `Rylai.app`
2. 拖入「应用程序」文件夹
3. 双击启动 — 菜单栏会出现 🖼️ 图标
4. （推荐）在设置中配置你自己的 Unsplash API Key（详见下方）

### 方式二：从源码编译

需要 macOS 12.0+、Xcode 13+、Swift 5.5+

```bash
git clone <repo-url> && cd Rylai
brew install xcodegen    # 如果没安装的话
xcodegen generate --spec project.yml
open Rylai.xcodeproj     # Build & Run
```

或者直接运行 `bash setup.sh` 一键初始化。

## 获取你自己的 Unsplash API Key

应用内置了一个 API Key 供快速体验，但它是**所有用户共享的**，限额 **50 次请求/小时**。强烈建议申请你自己的免费 Key：

1. 访问 [Unsplash Developers](https://unsplash.com/developers) 注册 / 登录
2. 点击 **New Application** → 同意条款 → 随便起个应用名
3. 在应用详情页复制 **Access Key**（不是 Secret Key）
4. 在 Rylai 中打开 **设置 → Unsplash Key**，粘贴你的 Access Key

> **为什么？** 每个免费 Key 独享 50 次/小时的配额。用自己的 Key，就不会被其他用户挤占额度。

## 环境要求

| | 版本 | 说明 |
|:---|:---|:---|
| **macOS** | 12.0+（推荐 **macOS 13+**） | macOS 13+ 使用现代 SMAppService 实现开机自启动；macOS 12 使用旧版 API —— 所有功能正常使用 |
| **Xcode** | 13+ | 仅源码编译需要 |
| **Unsplash API** | 免费 Access Key | https://unsplash.com/developers |

## 项目结构

```
Rylai/
├── App/
│   ├── RylaiApp.swift                # 入口，菜单栏应用 + NSPopover
│   └── Config.swift                   # API Key 与默认配置
├── Models/
│   ├── UnsplashPhoto.swift            # Unsplash API 响应模型
│   ├── WallpaperSettings.swift        # 用户偏好（UserDefaults）
│   └── WallpaperCategory.swift        # 主题分类（emoji + 颜色）
├── Services/
│   ├── UnsplashService.swift          # Unsplash API 客户端 + 预取池
│   ├── WallpaperManager.swift         # NSWorkspace 壁纸设置器
│   ├── WallpaperScheduler.swift       # 定时器调度器
│   ├── ImageCacheManager.swift        # 下载缓存 + 收藏存储
│   └── LaunchAtLoginManager.swift     # SMAppService (macOS 13+) / SMLoginItemSetEnabled (macOS 12)
├── Views/
│   ├── MenuBarView.swift              # 主弹窗 UI + 内联设置
│   ├── SettingsView.swift             # 设置窗口（NavigationSplitView）
│   ├── GalleryView.swift              # 历史记录 & 收藏画廊
│   └── LiquidGlass/
│       └── LiquidGlassBackground.swift  # 可复用玻璃组件库
└── Resources/
    ├── Info.plist
    └── Assets.xcassets
```

## 设计系统

### Liquid Glass 组件

| 组件 | 说明 |
|:---|:---|
| `GlassCard` | 半透明卡片，细渐变边框 |
| `LiquidButton` | 分类按钮，带选中/悬停态 |
| `GhostIconButton` | 圆形图标按钮，悬停反馈 |
| `GhostTextButton` | 胶囊文字按钮，悬停反馈 |
| `LiquidToggle` | 自定义开关，带动画滑块 |
| `GlassDivider` | 渐变水平分隔线 |

所有交互组件均包含：
- 悬停时鼠标变为手型指针（`.pointerCursor()` 修饰符）
- 平滑悬停动画
- 按下缩放反馈

### 导航模式

弹窗使用 **ZStack + offset** 导航模式实现平滑页面切换：
- 主页 ↔ 设置子页
- 主页 ↔ 分类编辑子页
- 设置 → 分类编辑（嵌套）

## Unsplash API

### 壁纸获取（锁定 4K）

```
GET https://api.unsplash.com/photos/random
  ?client_id={ACCESS_KEY}
  &topics={TOPIC_ID}
  &orientation=landscape
  &count=10
```

下载使用 `raw` URL 拼接 `w=3840&q=85&fit=max`，保证一致的 4K 输出。

### 速率限制

- 免费额度：50 次请求/小时（每个 Key 独立计算）
- 每次设置壁纸都会触发下载追踪接口（Unsplash 要求）
- 预取池通过批量请求减少 API 调用次数
- 触发限流时，Rylai 会显示警告横幅并引导你配置自己的 Key

## 版本历史

### v1.0.2

- 主页 API 限流警告横幅 + 引导式 Key 配置
- "Verify" 按钮验证 API Key 有效性，内联状态反馈
- 设置页新增 Access Key 申请指引（填入 Key 后自动隐藏）
- 一键跳转创建 Unsplash 应用
- README 重构：下载优先的快速开始 + API Key 申请教程

### v1.0.1

- 全英文 UI 本地化
- 统一幽灵按钮体系，覆盖所有交互元素
- 所有可点击元素显示手型指针
- 分类编辑器重新设计（边框高亮选中，去除复选框）
- Unsplash API Key 标签明确为 "Access Key"
- 存储区按钮宽度对齐

### v1.0.0

- 首次发布
- Liquid Glass 界面
- Unsplash 自动换壁纸
- 多显示器支持
- 收藏 & 历史记录

## 许可证

MIT
