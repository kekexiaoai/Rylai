import AppKit
import SwiftUI

@main
struct RylaiLoginItemApp: App {
    @NSApplicationDelegateAdaptor(LoginItemAppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class LoginItemAppDelegate: NSObject, NSApplicationDelegate {
    private let mainAppBundleIdentifier = "com.rylai.app"

    func applicationDidFinishLaunching(_ notification: Notification) {
        defer { NSApp.terminate(nil) }

        guard NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == mainAppBundleIdentifier }) == false else {
            return
        }

        let mainAppURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        guard FileManager.default.fileExists(atPath: mainAppURL.path) else {
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.createsNewApplicationInstance = false

        NSWorkspace.shared.openApplication(at: mainAppURL, configuration: configuration) { _, error in
            if let error {
                NSLog("RylaiLoginItem failed to launch main app: %@", error.localizedDescription)
            }
        }
    }
}
