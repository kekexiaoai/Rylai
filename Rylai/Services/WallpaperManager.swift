// WallpaperManager.swift
// Rylai ❄️

import AppKit
import Foundation

@MainActor
class WallpaperManager: ObservableObject {

    @Published var currentPhotoURL: URL?
    @Published var currentPhotoURLs: [Int: URL]?  // screen ID -> URL

    private let workspace = NSWorkspace.shared

    // MARK: - Set Wallpaper (All Screens, Same)

    /// Set wallpaper from local file URL (same for all displays)
    func setWallpaper(from localURL: URL, fillMode: WallpaperFillMode = .fill) throws {
        let screens = NSScreen.screens

        for screen in screens {
            try setWallpaper(on: screen, localURL: localURL, fillMode: fillMode)
        }
        currentPhotoURL = localURL
    }

    // MARK: - Set Wallpapers (Multi-Display, Different)

    /// Set wallpapers from multiple local file URLs (different per display)
    func setWallpapers(from localURLs: [URL], fillMode: WallpaperFillMode = .fill) throws {
        let screens = NSScreen.screens
        var urlMap: [Int: URL] = [:]

        for (index, screen) in screens.enumerated() {
            let url = localURLs[safe: index] ?? localURLs.first!  // Fall back to first image if not enough
            try setWallpaper(on: screen, localURL: url, fillMode: fillMode)
            // Use screen hashValue as identifier (NSScreen has no public deviceID)
            urlMap[screen.hashValue] = url
        }
        currentPhotoURLs = urlMap
    }

    /// Set wallpaper for a specific screen
    func setWallpaper(on screen: NSScreen, localURL: URL, fillMode: WallpaperFillMode) throws {
        var options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: fillMode.nsScaling.rawValue,
            .allowClipping: (fillMode == .fill),
        ]
        
        // macOS 26: allow dynamic wallpaper overlay
        if #available(macOS 26.0, *) {
            options[.fillColor] = NSColor.clear
        }
        
        try workspace.setDesktopImageURL(localURL, for: screen, options: options)
    }
    
    // MARK: - Current Wallpaper
    
    func getCurrentWallpaperURL(for screen: NSScreen = .main ?? .screens[0]) -> URL? {
        workspace.desktopImageURL(for: screen)
    }
    
    // MARK: - Screen Info
    
    var mainScreenSize: CGSize {
        NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
    }
    
    var allScreens: [NSScreen] {
        NSScreen.screens
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
