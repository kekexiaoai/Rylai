## 1. Configuration Updates
- [x] 1.1 Update `project.yml` deployment target from 14.0 to 12.0
- [x] 1.2 Update `project.yml` Swift version from 5.9 to 5.5
- [x] 1.3 Update `Info.plist` LSMinimumSystemVersion to 12.0
- [x] 1.4 Run `xcodegen generate --spec project.yml` to regenerate Xcode project

## 2. LaunchAtLoginManager Implementation
- [x] 2.1 Add legacy ServiceManagement API functions for macOS 10.6+
- [x] 2.2 Create `@available(macOS 13.0, *)` SMAppService implementation
- [x] 2.3 Create macOS 12 fallback using SMLoginItemSetEnabled
- [x] 2.4 Add version detection logic
- [ ] 2.5 Test on macOS 12 simulator/target (if available)
- [ ] 2.6 Test on macOS 13+ target (if available)

## 3. Validation
- [x] 3.1 Build project successfully with no errors
- [ ] 3.2 Verify launch-at-login toggle works correctly
- [ ] 3.3 Verify app still works on macOS 13+ with SMAppService
- [x] 3.4 Update README documentation with new minimum requirements
- [x] 3.5 Update CLAUDE.md project minimum requirements
