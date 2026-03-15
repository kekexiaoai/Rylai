// WallpaperSettings.swift
// Rylai ❄️

import Foundation
import Combine
import AppKit

/// User preferences, persisted to UserDefaults
class WallpaperSettings: ObservableObject {

    static let shared = WallpaperSettings()

    // MARK: - Change Interval
    @Published var changeInterval: TimeInterval {
        didSet { UserDefaults.standard.set(changeInterval, forKey: "changeInterval") }
    }

    // MARK: - Category
    @Published var category: WallpaperCategory {
        didSet { UserDefaults.standard.set(category.rawValue, forKey: "category") }
    }

    // MARK: - Toggle
    @Published var isAutoChangeEnabled: Bool {
        didSet { UserDefaults.standard.set(isAutoChangeEnabled, forKey: "isAutoChangeEnabled") }
    }

    // MARK: - Fill Mode
    @Published var fillMode: WallpaperFillMode {
        didSet { UserDefaults.standard.set(fillMode.rawValue, forKey: "fillMode") }
    }

    // MARK: - Multi-Display Mode
    @Published var multiDisplayMode: WallpaperMultiDisplayMode {
        didSet { UserDefaults.standard.set(multiDisplayMode.rawValue, forKey: "multiDisplayMode") }
    }

    // MARK: - Custom Unsplash API Key
    @Published var customAPIKey: String {
        didSet { UserDefaults.standard.set(customAPIKey, forKey: "customAPIKey") }
    }

    /// Effective API Key: custom if set, otherwise built-in
    var effectiveAPIKey: String {
        let trimmed = customAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Config.unsplashAccessKey : trimmed
    }

    // MARK: - Save Directory
    @Published var saveDirectory: String {
        didSet { UserDefaults.standard.set(saveDirectory, forKey: "saveDirectory") }
    }

    /// Default save path: ~/Pictures/Rylai
    static var defaultSaveDirectory: String {
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
        return pictures.appendingPathComponent("Rylai").path
    }

    // MARK: - Favorites
    @Published var favorites: [String] {  // photo IDs
        didSet {
            let encoded = try? JSONEncoder().encode(favorites)
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }

    // MARK: - History (Last 20)
    @Published var history: [UnsplashPhoto] {
        didSet {
            let trimmed = Array(history.prefix(20))
            let encoded = try? JSONEncoder().encode(trimmed)
            UserDefaults.standard.set(encoded, forKey: "history")
        }
    }

    // MARK: - Visible Categories (max 9)
    @Published var visibleCategories: [WallpaperCategory] {
        didSet {
            let encoded = try? JSONEncoder().encode(visibleCategories.map { $0.rawValue })
            UserDefaults.standard.set(encoded, forKey: "visibleCategories")
            // Manually trigger objectWillChange to notify displayedCategories observers
            objectWillChange.send()
        }
    }

    /// Categories displayed on the main page (min 1, max 9)
    var displayedCategories: [WallpaperCategory] {
        if visibleCategories.isEmpty {
            return Array(WallpaperCategory.allCases.prefix(9)) // Default: first 9
        }
        return visibleCategories
    }

    // MARK: - Interval Options
    static let intervalOptions: [(label: String, seconds: TimeInterval)] = [
        ("5 min",    5 * 60),
        ("15 min",   15 * 60),
        ("30 min",   30 * 60),
        ("1 hour",   60 * 60),
        ("2 hours",  2 * 60 * 60),
        ("4 hours",  4 * 60 * 60),
        ("8 hours",  8 * 60 * 60),
        ("Daily",    24 * 60 * 60),
    ]

    private init() {
        let ud = UserDefaults.standard

        self.changeInterval = ud.double(forKey: "changeInterval") > 0
            ? ud.double(forKey: "changeInterval")
            : Config.defaultInterval

        self.category = WallpaperCategory(rawValue: ud.string(forKey: "category") ?? "")
            ?? Config.defaultCategory

        self.isAutoChangeEnabled = ud.object(forKey: "isAutoChangeEnabled") as? Bool ?? true
        self.fillMode = WallpaperFillMode(rawValue: ud.string(forKey: "fillMode") ?? "") ?? .fill
        self.customAPIKey = ud.string(forKey: "customAPIKey") ?? ""
        self.saveDirectory = ud.string(forKey: "saveDirectory") ?? Self.defaultSaveDirectory
        self.multiDisplayMode = WallpaperMultiDisplayMode(rawValue: ud.string(forKey: "multiDisplayMode") ?? "") ?? .independent

        if let data = ud.data(forKey: "favorites"),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            self.favorites = ids
        } else {
            self.favorites = []
        }

        if let data = ud.data(forKey: "history"),
           let photos = try? JSONDecoder().decode([UnsplashPhoto].self, from: data) {
            self.history = photos
        } else {
            self.history = []
        }

        if let data = ud.data(forKey: "visibleCategories"),
           let categoryRawValues = try? JSONDecoder().decode([String].self, from: data) {
            let categories = categoryRawValues.compactMap { WallpaperCategory(rawValue: $0) }
            self.visibleCategories = categories.isEmpty ? [] : categories
        } else {
            self.visibleCategories = []
        }
    }

    func toggleFavorite(_ photo: UnsplashPhoto) {
        if favorites.contains(photo.id) {
            favorites.removeAll { $0 == photo.id }
        } else {
            favorites.append(photo.id)
        }
    }

    func isFavorited(_ photo: UnsplashPhoto) -> Bool {
        favorites.contains(photo.id)
    }

    func addToHistory(_ photo: UnsplashPhoto) {
        history.removeAll { $0.id == photo.id }
        history.insert(photo, at: 0)
    }
}

// MARK: - Fill Mode Enum

enum WallpaperFillMode: String, CaseIterable {
    case fill   = "fill"
    case fit    = "fit"
    case center = "center"
    case tile   = "tile"
    case stretch = "stretch"

    var displayName: String {
        switch self {
        case .fill:    return "Fill"
        case .fit:     return "Fit"
        case .center:  return "Center"
        case .tile:    return "Tile"
        case .stretch: return "Stretch"
        }
    }

    /// Map to NSWorkspace options
    var nsScaling: NSImageScaling {
        switch self {
        case .fill:    return .scaleProportionallyUpOrDown
        case .fit:     return .scaleProportionallyUpOrDown
        case .center:  return .scaleNone
        case .tile:    return .scaleNone
        case .stretch: return .scaleAxesIndependently
        }
    }
}

// MARK: - Multi-Display Mode Enum

enum WallpaperMultiDisplayMode: String, CaseIterable {
    case independent = "independent"  // Different wallpaper per display
    case mirrored    = "mirrored"     // Same wallpaper for all displays

    var displayName: String {
        switch self {
        case .independent: return "Independent"
        case .mirrored:    return "Mirrored"
        }
    }

    var description: String {
        switch self {
        case .independent: return "Different wallpaper on each display"
        case .mirrored:    return "Same wallpaper on all displays"
        }
    }
}
