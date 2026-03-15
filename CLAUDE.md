<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Rylai is a macOS menu bar wallpaper application that automatically fetches and changes desktop wallpapers from Unsplash. It's built entirely with SwiftUI using a custom "Liquid Glass" design system.

- **Type**: Native macOS app (Swift/SwiftUI + AppKit)
- **Minimum macOS**: 12.0 (enhanced launch-at-login on macOS 13+)
- **Build System**: XcodeGen (project.yml)
- **Bundle ID**: com.rylai.app

## Development Setup

The project uses XcodeGen for project generation. Do not commit `.xcodeproj` files to version control.

```bash
# One-click setup (installs dependencies and generates project)
bash setup.sh

# Or manual setup
brew install xcodegen
xcodegen generate --spec project.yml
open Rylai.xcodeproj
```

### Requirements
- macOS 12.0+
- Xcode 13+
- Swift 5.5+
- XcodeGen (via Homebrew)

## Architecture

### Service-Oriented MVVM Pattern

The app follows a service-oriented MVVM architecture with clear separation of concerns:

```
RylaiApp (AppDelegate)
    ├── Services (singleton-like, passed via environmentObjects)
    │   ├── UnsplashService       # Unsplash API client with prefetch pool
    │   ├── WallpaperManager      # NSWorkspace wallpaper setter
    │   ├── WallpaperScheduler    # Timer-based rotation (ObservableObject)
    │   ├── ImageCacheManager     # Download cache + favorites storage
    │   └── LaunchAtLoginManager  # SMAppService (macOS 13+) / SMLoginItemSetEnabled (macOS 12)
    ├── Models
    │   ├── UnsplashPhoto         # API response models
    │   ├── WallpaperSettings     # UserDefaults wrapper (@ObservableObject)
    │   └── WallpaperCategory    # Topic categories
    └── Views (SwiftUI)
        ├── MenuBarView           # Main popover (360x640)
        ├── SettingsView          # Settings window
        ├── GalleryView           # History & favorites
        └── LiquidGlass/          # Design system components
```

### Entry Point

`Rylai/App/RylaiApp.swift` contains the app structure:
- `RylaiApp`: SwiftUI App struct with Settings scene
- `AppDelegate`: Handles menu bar setup, NSPopover configuration (transient behavior), service initialization, and app lifecycle

### Dependency Injection

Services are initialized in `AppDelegate` and injected into `WallpaperScheduler` during initialization. They are passed to SwiftUI views via `@EnvironmentObject`.

### Menu Bar Pattern

The app uses `LSUIElement=true` in Info.plist to hide the Dock icon and appear only in the menu bar. Key components:
- `NSStatusBar.system.statusItem` with SF Symbol icon
- `NSPopover` with `.transient` behavior (auto-dismiss on outside click)
- `NSVisualEffectView` as popover background for glass effect
- Popover content size: 360x640

### State Management

- `WallpaperSettings`: Singleton `@ObservableObject` wrapping UserDefaults
- `WallpaperScheduler`: `@ObservableObject` managing wallpaper rotation state
- All preferences persisted: interval, category, auto-change, fill mode, multi-display, API key, favorites, history

## Key Services

### WallpaperScheduler (Rylai/Services/WallpaperScheduler.swift:8)
Main orchestrator for wallpaper changes. Key patterns:
- Timer-based scheduling with `scheduleNextChange()`
- Multi-display support: fetches different wallpapers per screen in independent mode
- Calls `unsplashService.trackDownload()` after each change (Unsplash API requirement)
- Prefetches photos in background to minimize API calls

### UnsplashService (Rylai/Services/UnsplashService.swift:25)
API client with prefetch pool. Key patterns:
- Prefetch pool (`photoPool`) stores photos for reuse
- `nextPhoto()` returns from pool or fetches new if empty
- Landscape filter: only photos with `width > height` are used
- Rate limit handling: returns `UnsplashError.rateLimited` on 403/429
- Editorial mode: fetches from `/photos` endpoint with random page for featured content

### ImageCacheManager (Rylai/Services/ImageCacheManager.swift:7)
Manages local file storage. Two directories:
- `~/Library/Application Support/Rylai/Downloads` - Cache (max 50 images, LRU eviction)
- `~/Library/Application Support/Rylai/Favorites` - Favorites (unlimited)
- Moves files from cache to favorites when favorited

### WallpaperManager (Rylai/Services/WallpaperManager.swift:8)
Handles NSWorkspace wallpaper operations. Key patterns:
- Multi-display: `setWallpapers()` for independent mode, `setWallpaper()` for mirrored
- Fill modes: Fill, Fit, Center, Tile, Stretch (mapped to `NSImageScaling`)
- Uses `screen.hashValue` as identifier for per-screen URL mapping

## Design System

Liquid Glass components in `Views/LiquidGlass/`:
- All interactive elements use `.pointerCursor()` modifier
- Smooth hover animations and press scale feedback
- `GlassCard`, `LiquidButton`, `GhostIconButton`, `GhostTextButton`, `LiquidToggle`, `GlassDivider`

Navigation uses ZStack + offset pattern for smooth page transitions between main page, settings, and category editor.

## API Key Handling

Unsplash API key is configured in two places:
1. Built-in key in `Config.swift` (shared, rate-limited: 50 req/hr)
2. User custom key stored in `WallpaperSettings.unsplashAccessKey`

The app uses `WallpaperSettings.shared.effectiveAPIKey` which prioritizes user key over built-in.

Rate limit handling:
- `UnsplashError.rateLimited` returned on 403/429 responses
- Warning banner displayed on main page when limited
- Settings includes guided setup and "Verify" button for testing key validity

## Configuration Files

- `project.yml`: XcodeGen specification (target, sources, bundle ID, deployment target)
- `Rylai/Resources/Info.plist`: App config (LSUIElement, min OS 12.0, notification description)
- `Rylai/Resources/Rylai.entitlements`: Sandbox settings (JIT disabled)
- `Rylai/App/Config.swift`: Unsplash API key, defaults, cache settings

## Unsplash API

Wallpaper fetch (4K locked):
```
GET https://api.unsplash.com/photos/random
  ?client_id={ACCESS_KEY}
  &topics={TOPIC_ID}
  &orientation=landscape
  &count=10
```

Downloads use `raw` URL with `w=3840&q=85&fit=max`. Download tracking is required by Unsplash - called via `trackDownload()` after each wallpaper change.

## Multi-Display Support

Two modes in `WallpaperSettings.multiDisplayMode`:
- `.mirrored`: Same wallpaper on all screens (single API call)
- `.independent`: Different wallpaper per screen (one API call per screen)

Independent mode fetches N wallpapers for N screens and applies them via `setWallpapers()`.

## Testing Changes

When building changes, ensure:
1. Run `xcodegen generate --spec project.yml` if modifying project structure
2. System Events permission is granted (required for first launch)
3. Test both single and multi-display scenarios
4. Verify rate limit handling works correctly with custom API keys
