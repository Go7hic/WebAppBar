# WebAppBar - Menu Bar Mini Browser

A lightweight, fast, focused macOS menu bar mini browser designed for quick access to mobile-friendly websites.

## Features

- **Menu bar only** — Click the 🌐 icon in the menu bar to open a popover window; no Dock icon
- **Embedded WebView** — Uses WKWebView; all pages load in-app without opening external browsers
- **Smart URL completion** — Auto-completes `https://`; adds protocol when missing
- **Shortcut names** — Type `gpt`, `b`, `x`, etc. to jump directly to corresponding sites
- **Search fallback** — Non-URL text is automatically searched via Google
- **Mobile viewport** — User-Agent set to iPhone for mobile layouts
- **Auto focus** — Input field auto-focuses when popover opens for immediate typing
- **Navigation controls** — Back / Forward / Refresh / Stop buttons
- **Quick access bar** — One-click shortcuts for common sites at the bottom
- **JS dialog support** — Handles `alert()` / `confirm()` / `prompt()`
- **New window handling** — `window.open()` opens in the current WebView
- **Loading progress bar** — Real-time page load progress
- **Dark mode** — Follows macOS system theme
- **History** — Keeps last 50 visited URLs

## Shortcut Name Mapping

| Shortcut | Site |
|----------|------|
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

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+

## Project Structure

```
WebAppBar/
├── WebAppBarApp.swift           # App entry, MenuBarExtra config
├── Models/
│   ├── WebViewModel.swift       # WebView state (loading, navigation, history)
│   └── ShortcutManager.swift    # Shortcut mapping + URL parsing
├── Views/
│   ├── MainView.swift           # Main layout (nav bar + progress + WebView + quick bar)
│   ├── NavigationBar.swift      # Top nav (back/forward/refresh + URL input + Go)
│   ├── QuickAccessBar.swift     # Bottom quick-access site buttons
│   └── WebViewRepresentable.swift # WKWebView ↔ SwiftUI bridge
├── Assets.xcassets/             # Assets
├── Info.plist                   # App config (LSUIElement for no Dock icon)
└── WebAppBar.entitlements       # Entitlements (Sandbox + network)

WebAppBar.xcodeproj/            # Xcode project (open directly)
project.yml                     # XcodeGen config (optional, for regenerating .xcodeproj)
```

## Quick Start

### Option 1: Open Xcode project directly

```bash
open WebAppBar.xcodeproj
```

Press `Cmd + R` in Xcode to run.

### Option 2: Regenerate project with XcodeGen

```bash
brew install xcodegen
xcodegen generate
open WebAppBar.xcodeproj
```

## License

MIT
