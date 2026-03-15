# Change: Support macOS 12.0 with backward-compatible launch-at-login

## Why
Users on macOS 12.x cannot build or run Rylai due to the macOS 14.0 minimum requirement. The only API requiring macOS 13+ is `SMAppService` for the launch-at-login feature, which can be replaced with the legacy ServiceManagement API on older macOS versions.

## What Changes
- Lower minimum deployment target from macOS 14.0 to macOS 12.0
- Update `LaunchAtLoginManager` to use `SMLoginItemSetEnabled` (macOS 10.6+) on macOS 12.x, and `SMAppService` (macOS 13+) on newer systems
- Update `project.yml` and `Info.plist` deployment targets
- Add `@available` version checks for conditional API usage
- Lower Swift version requirement to 5.5 (compatible with Xcode 13)

## Impact
- Affected specs: `launch-at-login`
- Affected code:
  - `project.yml` - deployment target
  - `Rylai/Resources/Info.plist` - LSMinimumSystemVersion
  - `Rylai/Services/LaunchAtLoginManager.swift` - dual API implementation
