## Context

The Rylai app currently requires macOS 14.0+ due to a single dependency: `SMAppService` used for launch-at-login functionality. Users on macOS 12.7.4 (the user's current system) cannot build or run the app. The rest of the codebase uses SwiftUI and AppKit APIs that are compatible with macOS 12.0.

## Goals / Non-Goals

**Goals:**
- Enable Rylai to run on macOS 12.0+
- Preserve launch-at-login functionality across all supported macOS versions
- Maintain backward compatibility with modern macOS versions
- Keep code maintainability with clear version branching

**Non-Goals:**
- Support macOS versions older than 12.0 (Monterey)
- Modify any features beyond launch-at-login
- Change the app's core architecture

## Decisions

### 1. Dual API Strategy

Use `@available` version checks to conditionally implement launch-at-login:

```swift
@available(macOS 13.0, *)
private let modernService = SMAppService.mainApp

private func toggleModern() {
    // SMAppService implementation
}

private func toggleLegacy() {
    // SMLoginItemSetEnabled implementation
}
```

**Rationale:**
- Clean separation of concerns with compiler-assisted version checking
- No runtime crashes from using unavailable APIs
- Users on modern macOS get the improved `SMAppService` experience
- Minimal code complexity with a single branch point

**Alternatives Considered:**
1. **Legacy-only approach**: Drop `SMAppService` entirely and use only SMLoginItemSetEnabled
   - *Pros*: Simpler code, single code path
   - *Cons*: Loses modern API benefits (better privacy controls, sandbox support)

2. **Separate targets**: Build different binaries for different macOS versions
   - *Pros*: Optimized for each platform
   - *Cons*: Complex build configuration, maintenance burden

3. **Runtime detection only**: Use `@available` checks at every call site
   - *Pros*: Fine-grained control
   - *Cons*: Verbose, error-prone, hard to maintain

### 2. Helper App for Legacy API

The legacy `SMLoginItemSetEnabled` API requires a helper app (LoginItem) to be registered. This differs from `SMAppService.mainApp` which can register the main app directly.

**Implementation:**
- For macOS 12.x: Create a minimal helper app bundle that launches the main app
- For macOS 13+: Continue using `SMAppService.mainApp` directly

**Trade-off:**
- Slightly more complex packaging for macOS 12.x
- User experience remains the same

### 3. Swift Version Compatibility

Swift 5.9 (used in current project) includes features like:
- `if`/`switch` expressions
- Parameter pack types
- Consume operator

These are not used in the current codebase, so Swift 5.5 (Xcode 13) is sufficient.

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Legacy helper app setup | Medium | Provide clear build instructions, use XcodeGen automation |
| Testing on macOS 12 | Medium | User acceptance testing, fallback to documentation |
| `SMLoginItemSetEnabled` deprecation | Low | Continue `@available` path for modern macOS |

## Migration Plan

1. **Update configuration files** (project.yml, Info.plist)
2. **Refactor LaunchAtLoginManager** with dual implementation
3. **Add helper app target** (for macOS 12.x) if needed
4. **Run `xcodegen generate`** to update Xcode project
5. **Test on target platforms**

**Rollback:**
- Revert to macOS 14.0+ if issues arise
- Keep original `LaunchAtLoginManager` implementation as fallback

## Open Questions

1. Does the legacy API require a separate helper app bundle, or can we work around it?
2. Should we create unit tests for both implementation paths?
