// Config.swift
// Rylai ❄️

import Foundation

enum Config {
    // MARK: - Unsplash API
    // Register free at https://unsplash.com/developers
    static let unsplashAccessKey = "ykO7HK_FeP_vKzruqXdFYbQKlEk3SaXR3x9YTSbu6rg"
    static let unsplashBaseURL = "https://api.unsplash.com"

    // MARK: - App
    static let appName = "Rylai"
    static let cacheDirectoryName = "Rylai"
    static let maxCachedImages = 50

    // MARK: - Defaults
    static let defaultInterval: TimeInterval = 30 * 60  // 30 minutes
    static let defaultCategory = WallpaperCategory.featured
    static let prefetchCount = 5
}
