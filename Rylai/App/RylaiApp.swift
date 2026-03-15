// RylaiApp.swift
// Rylai ❄️ - macOS 26 Liquid Glass Wallpaper

import SwiftUI
import AppKit

@main
struct RylaiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.wallpaperScheduler)
                .environmentObject(appDelegate.unsplashService)
                .frame(width: 600, height: 500)
        }
    }
}

// MARK: - AppDelegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    let unsplashService = UnsplashService()
    let wallpaperManager = WallpaperManager()
    let cacheManager = ImageCacheManager()
    lazy var wallpaperScheduler = WallpaperScheduler(
        unsplashService: unsplashService,
        wallpaperManager: wallpaperManager,
        cacheManager: cacheManager
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        wallpaperScheduler.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        popover?.performClose(nil)
        wallpaperScheduler.stop()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Rylai")
        button.image?.isTemplate = true
        button.action = #selector(togglePopover)
        button.target = self

        // Create popover with transient behavior (auto-dismiss on outside click)
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 360, height: 640)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.delegate = self

        // Create content view
        let contentView = MenuBarView()
            .environmentObject(wallpaperScheduler)
            .environmentObject(unsplashService)

        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor

        // Create NSVisualEffectView as popover background
        let effectView = NSVisualEffectView()
        effectView.material = .popover
        effectView.blendingMode = .withinWindow
        effectView.state = .active
        effectView.isEmphasized = true

        // Add hostingController's view to effectView
        effectView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: effectView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: effectView.bottomAnchor)
        ])

        // Set popover's contentViewController
        let viewController = NSViewController()
        viewController.view = effectView
        popover?.contentViewController = viewController
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - NSPopoverDelegate

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return true
    }
}
