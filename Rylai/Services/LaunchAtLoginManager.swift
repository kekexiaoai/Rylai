// LaunchAtLoginManager.swift
// Rylai ❄️ — Launch at Login (macOS 12.0+)

import Foundation
import ServiceManagement

class LaunchAtLoginManager: ObservableObject {
    private enum LegacyState {
        static let defaultsKey = "legacyLaunchAtLoginEnabled"
    }

    @Published var isEnabled: Bool = false
    @Published private(set) var isSupported: Bool = true
    @Published private(set) var statusMessage: String?

    // macOS 13+ SMAppService
    @available(macOS 13.0, *)
    private var modernService: SMAppService {
        return SMAppService.mainApp
    }

    // Legacy API requires an embedded login item helper app.
    private let legacyHelperAppName = "RylaiLoginItem"
    private let legacyHelperBundleID = "com.rylai.app.LoginItem"

    init() {
        refresh()
    }

    func refresh() {
        if #available(macOS 13.0, *) {
            isSupported = true
            statusMessage = nil
            isEnabled = modernService.status == .enabled
        } else {
            isSupported = hasLegacyHelperApp
            isEnabled = hasLegacyHelperApp && UserDefaults.standard.bool(forKey: LegacyState.defaultsKey)
            statusMessage = hasLegacyHelperApp
                ? nil
                : "This build does not bundle a macOS 12 login item helper."
        }
    }

    func toggle() {
        guard isSupported else { return }

        if #available(macOS 13.0, *) {
            toggleModern()
        } else {
            toggleLegacy()
        }
    }

    @available(macOS 13.0, *)
    private func toggleModern() {
        do {
            if isEnabled {
                try modernService.unregister()
            } else {
                try modernService.register()
            }
            isEnabled.toggle()
        } catch {
            print("LaunchAtLogin (SMAppService) error: \(error.localizedDescription)")
        }
    }

    private func toggleLegacy() {
        let shouldEnable = !isEnabled
        let success = SMLoginItemSetEnabled(legacyHelperBundleID as CFString, shouldEnable)

        if success {
            isEnabled.toggle()
            UserDefaults.standard.set(isEnabled, forKey: LegacyState.defaultsKey)
            statusMessage = nil
        } else {
            statusMessage = "Failed to update the macOS 12 login item."
            print("LaunchAtLogin (Legacy) error: Failed to set login item status")
        }
    }

    private var hasLegacyHelperApp: Bool {
        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/\(legacyHelperAppName).app")
        return FileManager.default.fileExists(atPath: helperURL.path)
    }
}
