## ADDED Requirements

### Requirement: Multi-Version Launch-at-Login Support
The system SHALL provide launch-at-login functionality compatible with macOS 12.0 and later.

#### Scenario: Launch-at-login on macOS 12.x
- **WHEN** user enables launch-at-login on macOS 12.x
- **THEN** the system uses legacy SMLoginItemSetEnabled API
- **AND** the app launches automatically on login

#### Scenario: Launch-at-login on macOS 13+
- **WHEN** user enables launch-at-login on macOS 13.0 or later
- **THEN** the system uses SMAppService API
- **AND** the app launches automatically on login

#### Scenario: Disable launch-at-login
- **WHEN** user disables launch-at-login
- **THEN** the system unregisters the app from launch items
- **AND** the app no longer launches on login

#### Scenario: Verify launch status
- **WHEN** user views launch-at-login toggle
- **THEN** the toggle reflects the current registration status
- **AND** the status is accurate for the current macOS version
