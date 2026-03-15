// WallpaperScheduler.swift
// Rylai ❄️ — Wallpaper Scheduler

import Foundation
import Combine
import SwiftUI

@MainActor
class WallpaperScheduler: ObservableObject {
    
    @Published var isRunning = false
    @Published var nextChangeDate: Date?
    @Published var currentPhoto: UnsplashPhoto?
    @Published var isChangingNow = false
    @Published var lastError: String?
    @Published var statusMessage = "Ready"
    @Published var isRateLimited = false
    
    private let settings = WallpaperSettings.shared
    private let unsplashService: UnsplashService
    private let wallpaperManager: WallpaperManager
    private let cacheManager: ImageCacheManager
    
    private var timer: Timer?
    private var changeTask: Task<Void, Never>?
    
    init(
        unsplashService: UnsplashService,
        wallpaperManager: WallpaperManager,
        cacheManager: ImageCacheManager
    ) {
        self.unsplashService = unsplashService
        self.wallpaperManager = wallpaperManager
        self.cacheManager = cacheManager
    }
    
    // MARK: - Start / Stop

    func start() {
        guard settings.isAutoChangeEnabled else { return }
        isRunning = true
        scheduleNextChange()

        // Change wallpaper immediately (first launch)
        Task { await changeWallpaper() }

        // Prefetch photo pool
        Task { await unsplashService.prefetchPhotos(category: settings.category) }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        nextChangeDate = nil
        statusMessage = "Paused"
    }

    /// Toggle scheduler (menu bar pause/resume button)
    func toggle() {
        if isRunning { stop() } else { start() }
    }
    
    // MARK: - Change Now
    
    func changeNow() {
        changeTask?.cancel()
        changeTask = Task { await changeWallpaper() }
        
        if isRunning {
            scheduleNextChange()  // Reset timer
        }
    }
    
    // MARK: - Restart With New Settings

    func restartWithNewSettings() {
        // Only update the timer, don't change wallpaper immediately
        if settings.isAutoChangeEnabled {
            scheduleNextChange()
            isRunning = true
        } else {
            stop()
        }
    }
    
    // MARK: - Private
    
    private func scheduleNextChange() {
        timer?.invalidate()
        let interval = settings.changeInterval
        nextChangeDate = Date().addingTimeInterval(interval)
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.changeWallpaper()
                self?.scheduleNextChange()  // Loop
            }
        }
    }
    
    private func changeWallpaper() async {
        guard !isChangingNow else { return }
        isChangingNow = true
        lastError = nil
        statusMessage = "Fetching new wallpaper..."

        defer { isChangingNow = false }

        do {
            let screenCount = NSScreen.screens.count
            let isMultiDisplay = settings.multiDisplayMode == .independent && screenCount > 1

            if isMultiDisplay {
                // Multi-display mode: different wallpaper per screen
                statusMessage = "Downloading \(screenCount) wallpapers..."

                var photos: [UnsplashPhoto] = []
                var localURLs: [URL] = []

                for _ in 0..<screenCount {
                    let photo = try await unsplashService.nextPhoto(category: settings.category)
                    let localURL = try await cacheManager.downloadAndCache(
                        photo: photo,
                        screenSize: wallpaperManager.mainScreenSize
                    )
                    photos.append(photo)
                    localURLs.append(localURL)

                    // Track download (Unsplash API requirement)
                    unsplashService.trackDownload(photo: photo)
                }

                // Set multi-display wallpapers
                try wallpaperManager.setWallpapers(from: localURLs, fillMode: settings.fillMode)

                // Update state (use first photo as representative)
                currentPhoto = photos[0]
                settings.addToHistory(photos[0])

                statusMessage = "Updated · \(screenCount) screens"

            } else {
                // Single display or mirrored mode: same wallpaper for all screens
                // Get next photo from pool or API
                let photo = try await unsplashService.nextPhoto(category: settings.category)
                statusMessage = "Downloading..."

                // Download and cache image
                let localURL = try await cacheManager.downloadAndCache(
                    photo: photo,
                    screenSize: wallpaperManager.mainScreenSize
                )

                // Set wallpaper
                try wallpaperManager.setWallpaper(from: localURL, fillMode: settings.fillMode)

                // Update state
                currentPhoto = photo
                settings.addToHistory(photo)

                // Track download (Unsplash API requirement)
                unsplashService.trackDownload(photo: photo)

                statusMessage = "Updated · \(photo.user.name)"
            }

            // Background prefetch
            Task { await unsplashService.prefetchPhotos(category: settings.category) }

            // Clear rate limit flag on success
            isRateLimited = false

        } catch {
            let msg = (error as? UnsplashError)?.errorDescription ?? error.localizedDescription
            lastError = msg
            statusMessage = "Failed: \(msg)"

            if let unsplashError = error as? UnsplashError,
               case .rateLimited = unsplashError {
                isRateLimited = true
            }
        }
    }
}
