# Rylai ❄️ (Auto Wallpaper for macOS)

[中文文档](README_ZH.md)

> A macOS wallpaper app powered by Unsplash, built with Liquid Glass design.

## Features

- 🖼️ Auto-fetch 4K landscape wallpapers from Unsplash
- ⏰ Scheduled wallpaper rotation (5 min ~ 24 hours)
- 🌊 macOS 26 Liquid Glass UI with ghost button system
- 📂 Topic-based categories (Nature, Architecture, Street, Film, etc.)
- ❤️ Favorite wallpapers saved locally
- 🖥️ Multi-display support (independent or mirrored mode)
- 🌙 Dark / Light mode adaptive
- 📌 Menu bar resident — no Dock icon

## Screenshots

![Desktop Overview](Assets/1.png)

| Main Page | Edit Topics | Settings |
|:---:|:---:|:---:|
| ![Main](Assets/2.png) | ![Topics](Assets/3.png) | ![Settings](Assets/4.png) |
| Wallpaper preview, topic grid, favorites | Select up to 9 topic categories | Auto change, API Key, multi-display |

## Quick Start

### Option A: Download (Recommended)

1. Go to [Releases](../../releases) and download the latest `Rylai.app`
2. Move it to your Applications folder
3. Double-click to launch — a 🖼️ icon will appear in the menu bar
4. (Recommended) Set up your own Unsplash API Key in Settings (see below)

### Option B: Build from Source

Requires macOS 12.0+, Xcode 13+, Swift 5.5+

```bash
git clone <repo-url> && cd Rylai
brew install xcodegen    # if not installed
xcodegen generate --spec project.yml
open Rylai.xcodeproj     # Build & Run
```

Or simply run `bash setup.sh` for a guided setup.

## Get Your Own Unsplash API Key

A built-in API Key is included for quick testing, but it's **shared by all users** with a limit of **50 requests/hour**. We strongly recommend getting your own free key:

1. Visit [Unsplash Developers](https://unsplash.com/developers) and sign up / log in
2. Click **New Application** → accept the terms → give it any name
3. On the app page, copy the **Access Key** (not the Secret Key)
4. In Rylai, open **Settings → Unsplash Key** and paste your Access Key

> **Why?** Each free key gets its own 50 req/hr quota. With your own key, you'll never be rate-limited by other users.

## Requirements

| | Version | Notes |
|:---|:---|:---|
| **macOS** | 12.0+ (recommended **macOS 13+**) | macOS 13+ uses modern SMAppService for launch-at-login; macOS 12 uses legacy API — all features still work |
| **Xcode** | 13+ | Only if building from source |
| **Unsplash API** | Free Access Key | https://unsplash.com/developers |

## Project Structure

```
Rylai/
├── App/
│   ├── RylaiApp.swift                # Entry point, menu bar app + NSPopover
│   └── Config.swift                   # API key & defaults
├── Models/
│   ├── UnsplashPhoto.swift            # Unsplash API response models
│   ├── WallpaperSettings.swift        # User preferences (UserDefaults)
│   └── WallpaperCategory.swift        # Topic categories with emoji & colors
├── Services/
│   ├── UnsplashService.swift          # Unsplash API client with prefetch pool
│   ├── WallpaperManager.swift         # NSWorkspace wallpaper setter
│   ├── WallpaperScheduler.swift       # Timer-based scheduler
│   ├── ImageCacheManager.swift        # Download cache + favorites storage
│   └── LaunchAtLoginManager.swift     # SMAppService (macOS 13+) / SMLoginItemSetEnabled (macOS 12)
├── Views/
│   ├── MenuBarView.swift              # Main popover UI + inline settings
│   ├── SettingsView.swift             # Settings window (NavigationSplitView)
│   ├── GalleryView.swift              # History & favorites gallery
│   └── LiquidGlass/
│       └── LiquidGlassBackground.swift  # Reusable glass components
└── Resources/
    ├── Info.plist
    └── Assets.xcassets
```

## Design System

### Liquid Glass Components

| Component | Description |
|:---|:---|
| `GlassCard` | Translucent card with thin gradient border |
| `LiquidButton` | Category button with active/hover states |
| `GhostIconButton` | Circular icon button with hover feedback |
| `GhostTextButton` | Capsule text button with hover feedback |
| `LiquidToggle` | Custom toggle with animated thumb |
| `GlassDivider` | Gradient horizontal divider |

All interactive components include:
- Pointer cursor on hover (`.pointerCursor()` modifier)
- Smooth hover animations
- Press scale feedback

### Navigation Pattern

The popover uses a **ZStack + offset** navigation pattern for smooth page transitions:
- Main page ↔ Settings sub-page
- Main page ↔ Category Editor sub-page
- Settings → Category Editor (nested)

## Unsplash API

### Wallpaper Fetch (4K locked)

```
GET https://api.unsplash.com/photos/random
  ?client_id={ACCESS_KEY}
  &topics={TOPIC_ID}
  &orientation=landscape
  &count=10
```

Downloads use `raw` URL with `w=3840&q=85&fit=max` for consistent 4K output.

### Rate Limits

- Free tier: 50 requests/hour per key
- Each wallpaper change triggers the download tracking endpoint (Unsplash requirement)
- Prefetch pool minimizes API calls by batching requests
- When the limit is hit, Rylai displays a warning banner and guides you to set up your own key

## Version History

### v1.0.2

- API rate limit warning banner on main page with guided setup
- "Verify" button to test API Key validity with inline status feedback
- Step-by-step Access Key setup guide in Settings (auto-hides when key is set)
- One-click link to create Unsplash application
- README restructured: download-first Quick Start + API Key tutorial

### v1.0.1

- Full English UI localization
- Unified ghost button system across all interactive elements
- Pointer cursor on all clickable elements
- Category editor redesigned (border highlight selection, no checkboxes)
- Unsplash API key label clarified as "Access Key"
- Aligned button widths in storage section

### v1.0.0

- Initial release
- Liquid Glass UI
- Auto wallpaper rotation with Unsplash
- Multi-display support
- Favorites & history

## License

MIT
