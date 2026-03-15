// SettingsView.swift
// Rylai ❄️ — Settings Panel

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var scheduler: WallpaperScheduler
    @EnvironmentObject var unsplashService: UnsplashService
    @ObservedObject private var settings = WallpaperSettings.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSection: SettingsSection = .general
    @State private var showClearCacheAlert = false
    @State private var cacheSizeText = "Calculating..."

    private let cacheManager = ImageCacheManager()

    enum SettingsSection: String, CaseIterable {
        case general    = "General"
        case appearance = "Appearance"
        case advanced   = "Advanced"
        case about      = "About"

        var icon: String {
            switch self {
            case .general:    return "gearshape"
            case .appearance: return "paintpalette"
            case .advanced:   return "wrench.and.screwdriver"
            case .about:      return "info.circle"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                ForEach(SettingsSection.allCases, id: \.self) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Label(section.rawValue, systemImage: section.icon)
                            .font(.system(size: 13))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(selectedSection == section ? Color.accentColor.opacity(0.15) : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedSection == section ? .primary : .secondary)
                }
                Spacer()
            }
            .frame(width: 160)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Detail
            ZStack {
                LiquidGlassBackground(intensity: 0.72, cornerRadius: 0)
                    .allowsHitTesting(false)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch selectedSection {
                        case .general:    generalSection
                        case .appearance: appearanceSection
                        case .advanced:   advancedSection
                        case .about:      aboutSection
                        }
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle("Rylai Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .help("Close Settings")
            }
        }
        .frame(minWidth: 560, minHeight: 400)
        .onAppear {
            cacheSizeText = cacheManager.cacheSizeString
        }
    }

    // MARK: - General

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                        Spacer()
                        Picker("", selection: $settings.changeInterval) {
                            ForEach(WallpaperSettings.intervalOptions, id: \.seconds) { opt in
                                Text(opt.label).tag(opt.seconds)
                            }
                        }
                        .frame(width: 120)
                        .pointerCursor()
                        .onChange(of: settings.changeInterval) { _ in
                            scheduler.restartWithNewSettings()
                        }
                    }
                    .padding(.vertical, 8)

                    GlassDivider()

                    LaunchAtLoginRow()
                }
            }

            SectionHeader(title: "Image Source", icon: "photo.on.rectangle.angled")

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Unsplash Access Key", systemImage: "key")
                        Spacer()
                        Link("Apply →",
                             destination: URL(string: "https://unsplash.com/developers")!)
                            .font(.system(size: 12))
                            .pointerCursor()
                    }

                    TextField("Leave empty for built-in Key", text: $settings.customAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    if settings.customAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Currently using built-in Key")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Currently using custom Key")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
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
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Fill Mode", icon: "rectangle.fill")

            GlassCard {
                LazyVGrid(
                    columns: Array(repeating: .init(.flexible()), count: 3),
                    spacing: 10
                ) {
                    ForEach(WallpaperFillMode.allCases, id: \.self) { mode in
                        FillModeOption(
                            mode: mode,
                            isSelected: settings.fillMode == mode
                        ) {
                            settings.fillMode = mode
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            SectionHeader(title: "Category Preference", icon: "tag")

            GlassCard {
                LazyVGrid(
                    columns: Array(repeating: .init(.flexible()), count: 3),
                    spacing: 8
                ) {
                    ForEach(WallpaperCategory.allCases) { cat in
                        CategoryChip(
                            category: cat,
                            isSelected: settings.category == cat
                        ) {
                            settings.category = cat
                        }
                    }
                }
            }
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Storage", icon: "folder")

            GlassCard {
                VStack(spacing: 0) {
                    HStack {
                        Label("Save Directory", systemImage: "folder")
                        Spacer()
                        Text(settings.saveDirectory)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding(.vertical, 8)

                    GlassDivider()

                    HStack {
                        Spacer()
                        GhostTextButton(text: "Choose...", icon: "folder.badge.plus") {
                            chooseSaveDirectory()
                        }

                        GhostTextButton(text: "Reset Default", icon: "arrow.counterclockwise") {
                            settings.saveDirectory = WallpaperSettings.defaultSaveDirectory
                        }
                    }
                    .padding(.vertical, 8)

                    GlassDivider()

                    HStack {
                        Label("Open in Finder", systemImage: "arrow.right.circle")
                        Spacer()
                        GhostTextButton(text: "Open", icon: "folder") {
                            let url = URL(fileURLWithPath: settings.saveDirectory)
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            SectionHeader(title: "Cache Management", icon: "externaldrive")

            GlassCard {
                VStack(spacing: 0) {
                    HStack {
                        Label("Cache Size", systemImage: "internaldrive")
                        Spacer()
                        Text(cacheSizeText)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)

                    GlassDivider()

                    HStack {
                        Label("Max Cached Images", systemImage: "photo.stack")
                        Spacer()
                        Text("\(Config.maxCachedImages) images")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)

                    GlassDivider()

                    HStack {
                        Spacer()
                        GhostTextButton(text: "Clear Cache", icon: "trash", color: .red) {
                            showClearCacheAlert = true
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .alert("Clear cache?", isPresented: $showClearCacheAlert) {
                Button("Clear") {
                    cacheManager.clearAll()
                    cacheSizeText = cacheManager.cacheSizeString
                }
                Button("Cancel") {}
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: 20) {
            GlassCard(cornerRadius: 12, padding: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 52))
                        .foregroundStyle(.cyan)
                        // .symbolEffect(.pulse)  // macOS 14+ only, removed for compatibility

                    Text("Rylai")
                        .font(.system(size: 22, weight: .bold))

                    Text("macOS Wallpaper App")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text("Version 1.0.2  ·  macOS 26")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)

                    GlassDivider()

                    VStack(spacing: 4) {
                        Text("Liquid Glass Design · Photos from Unsplash")
                        Link("unsplash.com",
                             destination: URL(string: "https://unsplash.com")!)
                        .pointerCursor()
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                    VStack(spacing: 6) {
                        Link(destination: URL(string: "https://github.com/JaffryGao")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 10))
                                Text("Original: github.com/JaffryGao")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.secondary.opacity(0.7))
                        }
                        .pointerCursor()

                        Link(destination: URL(string: "https://github.com/kekexiaoai/Rylai")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 10))
                                Text("Fork: github.com/kekexiaoai/Rylai")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.secondary.opacity(0.7))
                        }
                        .pointerCursor()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Directory Picker

    private func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Choose wallpaper save directory"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: settings.saveDirectory)

        if panel.runModal() == .OK, let url = panel.url {
            settings.saveDirectory = url.path
        }
    }
}

// MARK: - Helper Components

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

struct LaunchAtLoginRow: View {
    @StateObject private var launchManager = LaunchAtLoginManager()

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchManager.isEnabled },
            set: { _ in
                launchManager.toggle()
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LiquidToggle(label: "Launch at Login", icon: "power", isOn: launchAtLoginBinding)
                .disabled(!launchManager.isSupported)

            if let statusMessage = launchManager.statusMessage {
                Text(statusMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            launchManager.refresh()
        }
    }
}

struct FillModeOption: View {
    let mode: WallpaperFillMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.primary.opacity(0.08))
                    .frame(height: 40)
                    .overlay {
                        Image(systemName: "rectangle")
                            .foregroundStyle(isSelected ? .blue : .secondary)
                    }
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.blue, lineWidth: 2)
                        }
                    }
                Text(mode.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
        }
        .buttonStyle(.plain)
        .pointerCursor()
    }
}

struct CategoryChip: View {
    let category: WallpaperCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(category.accentColor.opacity(0.2))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(category.accentColor.opacity(0.5), lineWidth: 1)
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.06))
                    }
                }
                .foregroundStyle(isSelected ? category.accentColor : .secondary)
        }
        .buttonStyle(.plain)
        .pointerCursor()
    }
}
