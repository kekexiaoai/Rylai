// MenuBarView.swift
// Rylai ❄️ — Menu Bar Popover

import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var scheduler: WallpaperScheduler
    @EnvironmentObject var unsplashService: UnsplashService

    private let settings = WallpaperSettings.shared
    @State private var showSettings = false
    @State private var showCategoryEditor = false  // Sub-page navigation
    @State private var favorites: [UnsplashPhoto] = []

    private let cacheManager = ImageCacheManager()

    var body: some View {
        ZStack {
            // Main page
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                GlassDivider()

                currentWallpaperSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                // Scrollable categories and content
                ScrollView(.vertical, showsIndicators: false) {
                    categoryScrollView
                        .padding(.top, 4)
                        .padding(.bottom, 6)

                    GlassDivider()

                    // Favorites list
                    favoritesSection
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                }

                GlassDivider()

                footerView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .frame(width: 360)
            .offset(x: showSettings || showCategoryEditor ? -360 : 0)

            // Settings sub-page
            if showSettings {
                InlineSettingsView(
                    showSettings: $showSettings,
                    scheduler: scheduler
                )
                .frame(width: 360)
                .offset(x: showSettings ? 0 : 360)
            }

            // Category editor sub-page
            if showCategoryEditor {
                CategoryEditorPage(
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showCategoryEditor = false
                        }
                    }
                )
                .frame(width: 360)
                .offset(x: showCategoryEditor ? 0 : 360)
            }
        }
        .frame(width: 360, height: 620)
        .onAppear {
            loadFavorites()
        }
        .animation(.easeInOut(duration: 0.25), value: showSettings)
        .animation(.easeInOut(duration: 0.25), value: showCategoryEditor)
    }

    private func loadFavorites() {
        favorites = cacheManager.getFavorites()
    }

    // MARK: - Header (ghost buttons with hover feedback)

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Rylai")
                        .font(.system(size: 15, weight: .semibold))

                    Circle()
                        .fill(scheduler.isRunning ? Color.green : Color.gray)
                        .frame(width: 7, height: 7)
                        .shadow(color: scheduler.isRunning ? .green.opacity(0.6) : .clear, radius: 3)
                }
                Text(scheduler.statusMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Next wallpaper button (moved to top) — filled icon
            GhostIconButton(icon: "arrow.right.circle.fill", size: 20) {
                scheduler.changeNow()
            }
            .help("Next Wallpaper")
            .disabled(scheduler.isChangingNow)
            .opacity(scheduler.isChangingNow ? 0.5 : 1)

            // Pause/Play button — filled icon
            GhostIconButton(icon: scheduler.isRunning ? "pause.circle.fill" : "play.circle.fill", size: 20) {
                scheduler.toggle()
            }
            .help(scheduler.isRunning ? "Pause Auto Change" : "Resume Auto Change")

            // Settings button — filled icon
            GhostIconButton(icon: "gearshape.fill", size: 20) {
                showSettings = true
            }
            .help("Settings")
        }
    }

    // MARK: - Current wallpaper preview

    private var currentWallpaperSection: some View {
        ZStack(alignment: .bottom) {
            // Thumbnail — breathing blur on transition
            if let photo = scheduler.currentPhoto,
               let url = URL(string: photo.urls.small) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay { ProgressView().scaleEffect(0.8) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipped()
                .blur(radius: scheduler.isChangingNow ? 16 : 0)
                .scaleEffect(scheduler.isChangingNow ? 1.06 : 1.0)
                .animation(.easeInOut(duration: 0.6), value: scheduler.isChangingNow)
            } else {
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 150)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28))
                                .foregroundStyle(.tertiary)
                            Text(scheduler.isChangingNow ? "Fetching..." : "Click Next to get wallpaper")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
            }

            // Bottom info overlay (hidden during transition)
            if let photo = scheduler.currentPhoto, !scheduler.isChangingNow {
                HStack {
                    Text("by \(photo.user.name)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()

                    // Favorite button
                    Button {
                        if cacheManager.isFavorited(photo) {
                            cacheManager.removeFromFavorites(photo)
                            // Remove from list
                            withAnimation {
                                favorites.removeAll { $0.id == photo.id }
                            }
                        } else {
                            // Check if already in list to avoid duplicates
                            if !favorites.contains(where: { $0.id == photo.id }) {
                                Task {
                                    try? await cacheManager.addToFavorites(photo)
                                    // Add to list
                                    withAnimation {
                                        favorites.insert(photo, at: 0)
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: cacheManager.isFavorited(photo) ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundStyle(cacheManager.isFavorited(photo) ? .red : .white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                    Button {
                        if let url = URL(string: photo.links.html) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }

            // Breathing overlay during transition
            if scheduler.isChangingNow {
                WallpaperBreathingOverlay()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Category selection (grid layout)

    private var categoryScrollView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title bar
            HStack {
                Text("Topics")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                // Edit ghost button to open editor
                GhostTextButton(text: "Edit", icon: "pencil", action: {
                    showCategoryEditor = true
                })
            }

            LazyVGrid(
                columns: Array(repeating: .init(.flexible(), spacing: 6), count: 3),
                spacing: 6
            ) {
                ForEach(settings.displayedCategories) { cat in
                    HomeCategoryChip(
                        category: cat,
                        isSelected: settings.category == cat
                    ) {
                        settings.category = cat
                        unsplashService.clearPool()
                        scheduler.changeNow()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Favorites list

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title bar - flush against top divider
            HStack {
                Text("Favorite")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 2)

            // Horizontal scroll list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(favorites, id: \.id) { photo in
                        FavoriteThumbnail(
                            photo: photo,
                            cacheManager: cacheManager,
                            scheduler: scheduler
                        ) {
                            loadFavorites()
                        }
                    }

                    if favorites.isEmpty {
                        HStack {
                            Spacer()
                            Text("Tap ♥ below wallpaper to favorite")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: 6) {
            // Rate limit warning banner
            if scheduler.isRateLimited {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("API rate limit reached")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Set your own Access Key for unlimited use.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    GhostTextButton(text: "Set Up", icon: "key", color: Color.orange, action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSettings = true
                        }
                    })
                }
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.orange.opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(.orange.opacity(0.2), lineWidth: 0.5)
                        }
                }
            }

            HStack {
                Text(intervalDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)

                Spacer()

                if let error = scheduler.lastError, !scheduler.isRateLimited {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 11))
                        Text(error)
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.red.opacity(0.8))
                }

                GhostIconButton(icon: "power", size: 13) {
                    NSApp.terminate(nil)
                }
                .help("Quit Rylai")
            }
        }
    }

    private var intervalDescription: String {
        if let match = WallpaperSettings.intervalOptions.first(where: { $0.seconds == settings.changeInterval }) {
            return "Every \(match.label)"
        }
        return "Auto change"
    }
}

// MARK: - Key Verify State

enum KeyVerifyState {
    case idle
    case checking
    case valid
    case invalid(String)
}

// MARK: - Breathing overlay (liquid glass pulse)

struct WallpaperBreathingOverlay: View {
    @State private var breathe = false
    @State private var hasStarted = false
    @State private var shimmer = false

    var body: some View {
        ZStack {
            // Breathing pulse — simulates liquid glass depth variation
            Color.black.opacity(breathe ? 0.12 : 0.02)

            // Shimmer sweep effect
            LinearGradient(
                colors: [.clear, .white.opacity(0.03), .clear],
                startPoint: UnitPoint(x: shimmer ? -0.5 : -1.5, y: 0),
                endPoint: UnitPoint(x: shimmer ? 1.5 : 0.5, y: 0)
            )
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true

            // Main breathing animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathe = true
            }

            // Shimmer sweep animation (phase offset)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
        }
    }
}

// MARK: - Favorite thumbnail

struct FavoriteThumbnail: View {
    let photo: UnsplashPhoto
    let cacheManager: ImageCacheManager
    let scheduler: WallpaperScheduler
    let onRefresh: () -> Void

    @State private var isFavorited = true

    var body: some View {
        Button {
            // Click to apply wallpaper
            Task {
                do {
                    try cacheManager.applyFavorite(photo, fillMode: WallpaperSettings.shared.fillMode)
                    scheduler.currentPhoto = photo
                    scheduler.statusMessage = "Applied (Favorite)"
                } catch {
                    scheduler.statusMessage = "Failed: \(error.localizedDescription)"
                }
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                // Thumbnail - prefer loading from local file
                Group {
                    if let image = localImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let url = URL(string: photo.urls.small) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(.quaternary)
                        }
                    } else {
                        Rectangle()
                            .fill(.quaternary)
                    }
                }
                .frame(width: 80, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                // Unfavorite button (heart shape, floating top-right)
                Button {
                    cacheManager.removeFromFavorites(photo)
                    withAnimation {
                        isFavorited = false
                    }
                    // Notify parent view to refresh
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onRefresh()
                    }
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 2)
                        .padding(6)
                        .background {
                            Circle()
                                .fill(.black.opacity(0.5))
                        }
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .offset(x: -4, y: 4)
            }
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .onAppear {
            isFavorited = true
        }
    }

    private var localImage: NSImage? {
        let filename = "\(photo.id).jpg"
        let path = cacheManager.favoritesDirectory.appendingPathComponent(filename)
        return NSImage(contentsOf: path)
    }
}

// MARK: - Inline settings page (displayed in popover)

struct InlineSettingsView: View {
    @Binding var showSettings: Bool
    @ObservedObject var scheduler: WallpaperScheduler
    @EnvironmentObject var unsplashService: UnsplashService
    @ObservedObject private var settings = WallpaperSettings.shared
    @State private var showClearCacheAlert = false
    @State private var cacheSizeText = "Calculating..."
    @State private var showCategoryEditor = false

    private let cacheManager = ImageCacheManager()
    @State private var keyVerifyState: KeyVerifyState = .idle

    var body: some View {
        VStack(spacing: 0) {
            if showCategoryEditor {
                // Category editor sub-page
                CategoryEditorPage(
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showCategoryEditor = false
                        }
                    }
                )
                .environmentObject(scheduler)
                .environmentObject(unsplashService)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Settings main page
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        GhostIconButton(icon: "chevron.left", size: 14) {
                            showSettings = false
                        }
                        Text("Settings")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    GlassDivider()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            // Auto Change
                            SectionHeader(title: "Auto Change", icon: "timer")

                            GlassCard {
                                VStack(spacing: 0) {
                                    LiquidToggle(label: "Enable Auto Change", icon: "arrow.triangle.2.circlepath", isOn: $settings.isAutoChangeEnabled)
                                        .onChange(of: settings.isAutoChangeEnabled) { _ in
                                            scheduler.restartWithNewSettings()
                                        }
                                        .padding(.vertical, 8)

                                    GlassDivider()

                                    HStack {
                                        Label("Interval", systemImage: "clock")
                                            .font(.system(size: 13))
                                        Spacer()
                                        Picker("", selection: $settings.changeInterval) {
                                            ForEach(WallpaperSettings.intervalOptions, id: \.seconds) { opt in
                                                Text(opt.label).tag(opt.seconds)
                                            }
                                        }
                                        .frame(width: 100)
                                        .pointerCursor()
                                        .onChange(of: settings.changeInterval) { _ in
                                            scheduler.restartWithNewSettings()
                                        }
                                    }
                                    .padding(.vertical, 6)

                                    GlassDivider()

                                    LaunchAtLoginRow()
                                }
                            }

                            // Image source
                            SectionHeader(title: "Unsplash Key", icon: "key")

                            GlassCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Access Key")
                                            .font(.system(size: 12))
                                        Spacer()
                                        // Inline verify status
                                        switch keyVerifyState {
                                        case .idle:
                                            EmptyView()
                                        case .checking:
                                            HStack(spacing: 4) {
                                                ProgressView()
                                                    .controlSize(.mini)
                                                Text("Verifying...")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.secondary)
                                            }
                                        case .valid:
                                            HStack(spacing: 3) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                                Text("Valid")
                                                    .foregroundStyle(.green)
                                            }
                                            .font(.system(size: 10, weight: .medium))
                                        case .invalid(let msg):
                                            HStack(spacing: 3) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.red)
                                                Text(msg)
                                                    .foregroundStyle(.red)
                                                    .lineLimit(1)
                                            }
                                            .font(.system(size: 10, weight: .medium))
                                        }
                                    }
                                    HStack(spacing: 6) {
                                        TextField("Leave empty for built-in Key", text: $settings.customAPIKey)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 11, design: .monospaced))
                                            .onChange(of: settings.customAPIKey) { _ in
                                                keyVerifyState = .idle
                                            }
                                        GhostTextButton(text: "Verify", icon: "checkmark.shield", action: {
                                            verifyAPIKey()
                                        })
                                    }

                                    // API Key setup guide (hidden when custom key is set)
                                    if settings.customAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        GlassDivider()

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Get your free Access Key:")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(.secondary)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Label("Sign up at unsplash.com/developers", systemImage: "1.circle.fill")
                                                Label("Create a New Application", systemImage: "2.circle.fill")
                                                Label("Copy the **Access Key** (not Secret Key)", systemImage: "3.circle.fill")
                                            }
                                            .font(.system(size: 10))
                                            .foregroundStyle(.tertiary)

                                            HStack(spacing: 8) {
                                                GhostTextButton(text: "Get Access Key", icon: "arrow.up.right", color: Color.blue, action: {
                                                    if let url = URL(string: "https://unsplash.com/oauth/applications/new") {
                                                        NSWorkspace.shared.open(url)
                                                    }
                                                })
                                                Text("Free · 50 req/hr per key")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                    }
                                }
                            }

                            // Multi-display settings
                            SectionHeader(title: "Multi-Display", icon: "display.2")

                            GlassCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Display Mode")
                                                .font(.system(size: 13))
                                            Text(settings.multiDisplayMode.description)
                                                .font(.system(size: 11))
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Picker("", selection: $settings.multiDisplayMode) {
                                            Text("Independent").tag(WallpaperMultiDisplayMode.independent)
                                            Text("Mirrored").tag(WallpaperMultiDisplayMode.mirrored)
                                        }
                                        .frame(width: 100)
                                        .pointerCursor()
                                    }
                                    .padding(.vertical, 8)
                                }
                            }

                            // Category management
                            SectionHeader(title: "Home Topics", icon: "square.grid.2x2")

                            GlassCard {
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Topics shown on home")
                                                .font(.system(size: 13))
                                            Text("\(settings.displayedCategories.count) selected, max 9")
                                                .font(.system(size: 11))
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        GhostTextButton(text: "Edit", icon: "pencil", action: {
                                            showCategoryEditor = true
                                        })
                                    }
                                    .padding(.vertical, 8)
                                }
                            }

                            storageSection
                            aboutSection
                        }
                        .padding(16)
                    }
                }
            }
        }
        .frame(width: 360, height: 620)
        .onAppear {
            cacheSizeText = cacheManager.cacheSizeString
        }
        .animation(.easeInOut(duration: 0.25), value: showCategoryEditor)
    }

    // MARK: - API Key Verification (InlineSettingsView)

    private func verifyAPIKey() {
        let key = settings.effectiveAPIKey
        keyVerifyState = .checking

        Task {
            do {
                var components = URLComponents(string: "\(Config.unsplashBaseURL)/photos/random")!
                components.queryItems = [
                    URLQueryItem(name: "client_id", value: key),
                    URLQueryItem(name: "count", value: "1"),
                ]

                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 10
                let session = URLSession(configuration: config)

                let (_, response) = try await session.data(from: components.url!)
                guard let http = response as? HTTPURLResponse else {
                    keyVerifyState = .invalid("Network error")
                    return
                }

                switch http.statusCode {
                case 200:
                    keyVerifyState = .valid
                    scheduler.isRateLimited = false
                case 401:
                    keyVerifyState = .invalid("Invalid key")
                case 403, 429:
                    keyVerifyState = .invalid("Rate limited")
                default:
                    keyVerifyState = .invalid("Error \(http.statusCode)")
                }
            } catch {
                keyVerifyState = .invalid("Network error")
            }
        }
    }

    private var storageSection: some View {
        Group {
            SectionHeader(title: "Storage", icon: "folder")

            GlassCard {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cache Dir")
                                .font(.system(size: 11))
                            Text("Max 50 images")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GhostTextButton(text: "Open", icon: "folder", action: {
                            NSWorkspace.shared.open(cacheManager.cacheDirectory)
                        })
                        .frame(width: 84)
                    }
                    .padding(.vertical, 6)

                    GlassDivider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Favorites Dir")
                                .font(.system(size: 11))
                        }
                        Spacer()
                        GhostTextButton(text: "Open", icon: "folder", action: {
                            NSWorkspace.shared.open(cacheManager.favoritesDirectory)
                        })
                        .frame(width: 84)
                    }
                    .padding(.vertical, 6)

                    GlassDivider()

                    HStack {
                        Text("Cache \(cacheSizeText)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        GhostTextButton(text: "Clear", icon: "trash", color: Color.red, action: {
                            showClearCacheAlert = true
                        })
                        .frame(width: 84)
                    }
                    .padding(.vertical, 6)
                }
            }
            .alert(isPresented: $showClearCacheAlert) {
                Alert(
                    title: Text("Clear cache?"),
                    message: Text("This removes cached wallpapers and favorites stored locally."),
                    primaryButton: .destructive(Text("Clear")) {
                        cacheManager.clearAll()
                        cacheSizeText = cacheManager.cacheSizeString
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 6) {
            Text("Rylai v1.0.2")
                .font(.system(size: 11, weight: .medium))
            Text("macOS Wallpaper App")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            GhostTextButton(text: "Original: JaffryGao", icon: "link", color: .secondary, fontSize: 10, action: {
                if let url = URL(string: "https://github.com/JaffryGao") {
                    NSWorkspace.shared.open(url)
                }
            })
            GhostTextButton(text: "Fork: kekexiaoai", icon: "link", color: .secondary, fontSize: 10, action: {
                if let url = URL(string: "https://github.com/kekexiaoai/Rylai") {
                    NSWorkspace.shared.open(url)
                }
            })
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - Category editor sub-page (inline in popover)

struct CategoryEditorPage: View {
    @EnvironmentObject var scheduler: WallpaperScheduler
    @EnvironmentObject var unsplashService: UnsplashService
    @ObservedObject var settings = WallpaperSettings.shared

    let onDismiss: () -> Void

    @State private var selectedCategories: [WallpaperCategory]
    @State private var showingMinError = false

    private let allCategories = WallpaperCategory.allCases
    private let maxSelectable = 9
    private let minSelectable = 1

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        // Initialize with current settings
        let current = WallpaperSettings.shared.displayedCategories
        _selectedCategories = State(initialValue: current.isEmpty ? Array(WallpaperCategory.allCases.prefix(9)) : current)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - same style as settings page
            HStack {
                GhostIconButton(icon: "chevron.left", size: 14) {
                    onDismiss()
                }
                Text("Edit Topics")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Info bar - with count animation
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                    Text("Selected")
                        .font(.system(size: 12))
                    Text("\(selectedCategories.count)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(countColor)
                    Text("/ \(maxSelectable)")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)

                Spacer()

                Text("Max \(maxSelectable)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.06)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Category grid - liquid glass cards (3-column layout)
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                    spacing: 8
                ) {
                    ForEach(allCategories) { category in
                        CategorySelectionRow(
                            category: category,
                            isSelected: selectedCategories.contains(category),
                            canSelect: selectedCategories.count < maxSelectable || selectedCategories.contains(category),
                            remainingSlots: maxSelectable - selectedCategories.count
                        ) {
                            toggleCategory(category)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            // contentMargins(.top, 0, for: .scrollContent)  // macOS 14+ API, removing for compatibility

            GlassDivider()
                .padding(.horizontal, 20)

            // Bottom save button
            HStack {
                Spacer()

                Button {
                    saveCategories()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Save & Apply")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(canSave ? Color.blue : Color.gray.opacity(0.3))
                            .shadow(color: canSave ? .blue.opacity(0.4) : .clear, radius: 4, x: 0, y: 2)
                    }
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .disabled(!canSave)
                .opacity(canSave ? 1.0 : 0.5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 360, height: 620)
        .alert("Select at least \(minSelectable) category", isPresented: $showingMinError) {
            Button("OK") {}
        } message: {
            Text("Home page requires at least \(minSelectable) category to function")
        }
    }

    private var canSave: Bool {
        selectedCategories.count >= minSelectable
    }

    private var countColor: Color {
        if selectedCategories.count > maxSelectable {
            return .red
        } else if selectedCategories.count < minSelectable {
            return .orange
        } else {
            return .blue
        }
    }

    private func toggleCategory(_ category: WallpaperCategory) {
        if let index = selectedCategories.firstIndex(of: category) {
            selectedCategories.remove(at: index)
        } else if selectedCategories.count < maxSelectable {
            selectedCategories.append(category)
        }
    }

    private func saveCategories() {
        guard selectedCategories.count >= minSelectable else {
            showingMinError = true
            return
        }
        // Limit to max 9
        let finalCategories = Array(selectedCategories.prefix(maxSelectable))

        // Save to UserDefaults
        WallpaperSettings.shared.visibleCategories = finalCategories

        // Clear Unsplash pool to ensure new categories are used next time
        unsplashService.clearPool()

        // Delay dismiss slightly for save feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                onDismiss()
            }
        }
    }
}

// MARK: - Category selection row - liquid glass card design

struct CategorySelectionRow: View {
    let category: WallpaperCategory
    let isSelected: Bool
    let canSelect: Bool
    let remainingSlots: Int
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Emoji icon
                Text(category.emoji)
                    .font(.system(size: 22))
                    .scaleEffect(isHovered ? 1.08 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)

                // Category name
                Text(category.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: [
                                    category.accentColor.opacity(0.15),
                                    category.accentColor.opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.primary.opacity(0.04),
                                    Color.primary.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected ?
                            LinearGradient(
                                colors: [category.accentColor.opacity(0.6), category.accentColor.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            }
            .shadow(color: isSelected ? category.accentColor.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
            .overlay {
                // Remaining slots indicator
                if remainingSlots <= 2 && !isSelected {
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Text("\(remainingSlots)")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.06))
                                }
                                .padding(4)
                        }
                        Spacer()
                    }
                }

                // Hover shimmer effect
                if isHovered && !isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
                }
            }
        }
        .buttonStyle(.plain)
        .pointerCursor()
        .disabled(!canSelect)
        .scaleEffect(isHovered && canSelect ? 0.97 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}

struct HomeCategoryChip: View {
    let category: WallpaperCategory
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(category.emoji)
                    .font(.system(size: 18))
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)

                Text(category.displayName)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : category.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                            ? category.accentColor.opacity(0.18)
                            : category.accentColor.opacity(0.08)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(category.accentColor.opacity(isSelected ? 0.55 : 0.28), lineWidth: isSelected ? 1.2 : 0.8)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .pointerCursor()
    }
}
