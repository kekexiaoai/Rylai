// ImageCacheManager.swift
// Rylai ❄️

import Foundation
import AppKit

class ImageCacheManager {

    // MARK: - Directory Structure

    // Cache directory (Downloads, max 50)
    var cacheDirectory: URL {
        let fm = FileManager.default
        let path = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rylai")
            .appendingPathComponent("Downloads")
        // Ensure directory exists
        try? fm.createDirectory(at: path, withIntermediateDirectories: true)
        return path
    }

    // Favorites directory (unlimited)
    var favoritesDirectory: URL {
        let fm = FileManager.default
        let path = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rylai")
            .appendingPathComponent("Favorites")
        // Ensure directory exists
        try? fm.createDirectory(at: path, withIntermediateDirectories: true)
        return path
    }

    init() {
        // Ensure both directories exist
        _ = cacheDirectory
        _ = favoritesDirectory
    }

    // MARK: - Download & Cache

    func downloadAndCache(photo: UnsplashPhoto, screenSize: CGSize) async throws -> URL {
        // Ensure directory exists
        let dir = cacheDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let cachedURL = cacheURL(for: photo.id)

        // Already cached, return directly
        if FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }

        guard let imageURL = photo.urls.bestURL(for: screenSize) else {
            throw URLError(.badURL)
        }

        let (tempURL, _) = try await URLSession.shared.download(from: imageURL)

        // moveItem may fail across filesystems, use copy+delete fallback
        do {
            try FileManager.default.moveItem(at: tempURL, to: cachedURL)
        } catch {
            try FileManager.default.copyItem(at: tempURL, to: cachedURL)
            try? FileManager.default.removeItem(at: tempURL)
        }

        cleanupIfNeeded()
        return cachedURL
    }

    // MARK: - Query Cache

    func cachedURL(for photoID: String) -> URL? {
        let url = cacheURL(for: photoID)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Clear Cache

    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Favorites Management

    /// Check if favorited
    func isFavorited(_ photo: UnsplashPhoto) -> Bool {
        let filename = "\(photo.id).jpg"
        let path = favoritesDirectory.appendingPathComponent(filename).path
        return FileManager.default.fileExists(atPath: path)
    }

    /// Add to favorites
    func addToFavorites(_ photo: UnsplashPhoto) async throws {
        let filename = "\(photo.id).jpg"
        let sourcePath = cacheDirectory.appendingPathComponent(filename)
        let destPath = favoritesDirectory.appendingPathComponent(filename)

        let fm = FileManager.default

        // Already in favorites, return
        guard !fm.fileExists(atPath: destPath.path) else { return }

        // If in cache, move to favorites
        if fm.fileExists(atPath: sourcePath.path) {
            try fm.moveItem(at: sourcePath, to: destPath)
        } else {
            // Not in cache, need to download
            let imageURL = URL(string: photo.urls.raw)!
            let (tempURL, _) = try await URLSession.shared.download(from: imageURL)
            try fm.moveItem(at: tempURL, to: destPath)
        }
    }

    /// Remove from favorites
    func removeFromFavorites(_ photo: UnsplashPhoto) {
        let filename = "\(photo.id).jpg"
        let path = favoritesDirectory.appendingPathComponent(filename).path
        try? FileManager.default.removeItem(atPath: path)
    }

    /// Get all favorited wallpapers
    func getFavorites() -> [UnsplashPhoto] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: favoritesDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            return []
        }

        // Sort by creation date (newest first)
        let sorted = files.sorted {
            let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return d1 > d2
        }

        return sorted.compactMap { url in
            let photoID = url.deletingPathExtension().lastPathComponent
            // Create a minimal UnsplashPhoto
            // small/thumb use local file URL, others use Unsplash format
            let unsplashHTML = "https://unsplash.com/photos/\(photoID)"

            let photo = UnsplashPhoto(
                id: photoID,
                description: nil,
                altDescription: nil,
                color: "#666666",
                width: 1920,
                height: 1080,
                urls: PhotoURLs(
                    raw: "https://images.unsplash.com/photo-\(photoID)?w=3840&q=85&fit=max",
                    full: "https://images.unsplash.com/photo-\(photoID)?w=3840&q=85&fit=max",
                    regular: "https://images.unsplash.com/photo-\(photoID)?w=1080&q=85&fit=max",
                    small: "https://images.unsplash.com/photo-\(photoID)?w=400&q=85&fit=max",
                    thumb: "https://images.unsplash.com/photo-\(photoID)?w=200&q=85&fit=max"
                ),
                user: UnsplashUser(id: "", username: "", name: "Favorited", portfolioURL: nil),
                links: PhotoLinks(
                    self: "",
                    html: unsplashHTML,
                    download: "\(unsplashHTML)/download",
                    downloadLocation: ""
                ),
                likes: 0,
                topicSubmissions: nil
            )
            return photo
        }
    }

    /// Apply favorited wallpaper
    func applyFavorite(_ photo: UnsplashPhoto, fillMode: WallpaperFillMode) throws {
        let filename = "\(photo.id).jpg"
        let path = favoritesDirectory.appendingPathComponent(filename)
        let localURL = path

        // Check if file exists
        guard FileManager.default.fileExists(atPath: path.path) else {
            throw NSError(domain: "Favorites", code: 404, userInfo: [NSLocalizedDescriptionKey: "Wallpaper file not found"])
        }

        // Set wallpaper (all displays)
        let screens = NSScreen.screens
        for screen in screens {
            var options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                .imageScaling: fillMode.nsScaling.rawValue,
                .allowClipping: (fillMode == .fill),
            ]
            if #available(macOS 26.0, *) {
                options[.fillColor] = NSColor.clear
            }
            try NSWorkspace.shared.setDesktopImageURL(localURL, for: screen, options: options)
        }
    }

    // MARK: - Cache Size

    var cacheSize: Int64 {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )) ?? []
        return files.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return sum + Int64(size)
        }
    }

    var cacheSizeString: String {
        let bytes = cacheSize
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    // MARK: - Private

    private func cacheURL(for photoID: String) -> URL {
        cacheDirectory.appendingPathComponent("\(photoID).jpg")
    }

    private func cleanupIfNeeded() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ), files.count > Config.maxCachedImages else { return }

        let sorted = files.sorted {
            let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return d1 < d2
        }
        sorted.prefix(files.count - Config.maxCachedImages).forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
}
