# WebAppBar - 菜单栏迷你浏览器

一个轻量、快速、专注的 macOS 菜单栏迷你浏览器，专为快速访问移动友好网站而设计。

## 功能特性

- **纯菜单栏应用** — 点击菜单栏 🌐 图标弹出 popover 窗口，无 Dock 图标
- **内嵌 WebView** — 使用 WKWebView，所有网页在应用内加载，不跳转外部浏览器
- **智能 URL 补全** — 自动补全 `https://`，无协议头自动添加
- **快捷名称** — 输入 `gpt`、`b`、`x` 等短名称直接跳转对应网站
- **搜索回退** — 输入非 URL 文本自动用 Google 搜索
- **移动端模拟** — User-Agent 设置为 iPhone，网站返回移动端布局
- **自动聚焦** — 弹出窗口时自动聚焦输入框，即时输入
- **导航控制** — 后退 / 前进 / 刷新 / 停止按钮
- **快捷访问栏** — 底部常用网站一键跳转
- **JS 弹窗支持** — 处理 `alert()` / `confirm()` / `prompt()`
- **新窗口拦截** — `window.open()` 统一在当前 WebView 内打开
- **加载进度条** — 实时显示网页加载进度
- **深色模式** — 自动适配 macOS 系统主题
- **历史记录** — 自动记录最近 50 条访问历史

## 快捷名称映射

| 快捷名 | 网站 |
|--------|------|
| `gpt` / `g` | chatgpt.com |
| `b` | m.bilibili.com |
| `x` | x.com |
| `wb` | m.weibo.cn |
| `yt` | m.youtube.com |
| `gh` | github.com |
| `zhihu` | zhihu.com |
| `db` | m.douban.com |
| `xhs` | xiaohongshu.com |
| `wiki` | zh.m.wikipedia.org |
| `rd` | reddit.com |
| `tb` | m.taobao.com |
| `jd` | m.jd.com |
| `dy` | m.douyin.com |
| `tt` | m.toutiao.com |
| `bing` | bing.com |
| `ggl` | google.com |

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Xcode 15.0+

## 项目结构

```
WebAppBar/
├── WebAppBarApp.swift           # 应用入口，MenuBarExtra 配置
├── Models/
│   ├── WebViewModel.swift       # WebView 状态管理（加载状态、导航、历史）
│   └── ShortcutManager.swift    # 快捷名称映射 + URL 智能解析
├── Views/
│   ├── MainView.swift           # 主界面布局（导航栏 + 进度条 + WebView + 快捷栏）
│   ├── NavigationBar.swift      # 顶部导航栏（后退/前进/刷新 + URL 输入 + Go）
│   ├── QuickAccessBar.swift     # 底部快捷网站按钮
│   └── WebViewRepresentable.swift # WKWebView ↔ SwiftUI 桥接
├── Assets.xcassets/             # 资源目录
├── Info.plist                   # 应用配置（含 LSUIElement 隐藏 Dock 图标）
└── WebAppBar.entitlements       # 权限配置（Sandbox + 网络访问）

WebAppBar.xcodeproj/            # Xcode 项目文件（可直接打开）
project.yml                     # XcodeGen 配置（可选，用于重新生成 .xcodeproj）
```

## 快速开始

### 方式一：直接打开 Xcode 项目

```bash
open WebAppBar.xcodeproj
```

在 Xcode 中按 `Cmd + R` 运行。

### 方式二：使用 XcodeGen 重新生成项目

```bash
brew install xcodegen
xcodegen generate
open WebAppBar.xcodeproj
```

## 已知问题与 Workaround

1. **MenuBarExtra popover 尺寸** — `.menuBarExtraStyle(.window)` 的窗口尺寸由内部 `.frame()` 控制，已设置为 420×640pt
2. **ScrollView 高度 Bug** — 未使用 ScrollView 嵌套 WebView，避免了已知的高度计算问题
3. **聚焦延迟** — `onAppear` 中使用 `asyncAfter(deadline: .now() + 0.1)` 延迟聚焦，确保视图完全加载后再激活输入框
4. **全选文本** — 监听 `NSTextField.textDidBeginEditingNotification` 实现点击地址栏自动全选

## License

MIT
