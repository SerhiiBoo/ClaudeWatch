# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.2] - 2026-05-07

### Fixed

- Allow/Deny buttons on permission approval cards now send the correct decision — tapping a button no longer also triggers the card's tap-to-activate handler, which was consuming the continuation with `.none` before the button action could deliver the real decision

## [2.2.1] - 2026-05-07

### Fixed

- Swift concurrency error in `NotificationStackView` — added `@MainActor` to `viewModelFor(_:)` to resolve "call to main actor-isolated initializer in a synchronous nonisolated context" build error

## [2.2.0] - 2026-05-07

### Added

- [Beta] Claude Code Hooks integration: ClaudeWatch now receives hook events (Notification, Stop, PreToolUse) from Claude Code and displays floating notification cards (stacked, up to 3 visible) when Claude needs attention or finishes work
- Permission approval cards: when Claude requests a tool call and the terminal isn't visible, a card with Allow/Deny buttons appears; auto-resolves after a configurable timeout (5–120 s). Respects existing allow/deny rules in `~/.claude/settings.json` and Claude's runtime permission mode — only surfaces cards for calls that genuinely need human input
- Delivery style picker in Hooks settings — choose between floating popover cards or native macOS notifications
- Permission approval toggle and timeout slider in Hooks settings
- Settings panel now lists which hooks are installed to `~/.claude/settings.json` and notes that existing settings are preserved on both install and uninstall
- Duplicate-instance guard: launching a second ClaudeWatch process exits immediately
- Pet plays a sustained excited animation while hook notification cards or permission cards are visible; returns to mood-driven animation once all are dismissed

## [2.1.0] - 2026-05-02

### Added

- Settings panel redesigned with tabbed navigation: General, Pet, Shortcuts, Alerts, Advanced — replaces single long-scroll layout
- Toggle to show or hide the Extra Usage section (pay-as-you-go spend) in Visible Sections settings
- Section and row icons throughout settings using accent-colored SF Symbol badges

### Changed

- Settings panel width increased from 320 pt to 360 pt to accommodate tabbed layout
- Pet character and variant pickers now use `FlowLayout` so items wrap instead of overflow; sprite previews enlarged to 30×30
- Notification threshold chips redesigned with color dot, larger hit target, and clearer remove button; preset buttons switched to `.bordered` style
- Control sizes standardized — toggles use `.small`, pickers and buttons use `.regular`
- Notch pet window level raised above popover so the pet is never obscured by the settings panel
- Session estimate ring visibility now controlled by the existing "Session limit estimate" toggle

### Removed

- Compact mode setting — full-content layout is now the only display mode

## [2.0.2] - 2026-04-22

### Fixed

- Keychain re-prompt frequency reduced: credentials are now cached in memory and read from Keychain only once per session (or once per token rotation). Previously every timer tick triggered a `SecItemCopyMatching` call, causing macOS to re-prompt after each `claude` CLI token refresh.
- When the API returns 401/403 the cached token is invalidated and re-fetched automatically, so recovery from a token rotation requires exactly one keychain prompt instead of none or repeated prompts.
- Pet overlay window no longer blocks clicks on app tabs, menu-bar items, or notification banners in the 240 pt of empty space around the sprite. The window now passes mouse events through everywhere except a tight rect around the actual sprite — tap-to-poke still works.

## [2.0.1] - 2026-04-13

### Fixed

- Swift concurrency error in `NotchPetService` — added `[weak self]` capture list to `Task { @MainActor }` block to prevent "reference to captured var in concurrently-executing code" build error
- Swift Sendable warning in `NotchPetWindow` — extract `notification.userInfo` before entering `Task` closure to avoid capturing non-`Sendable` `Notification`

## [2.0.0] - 2026-04-13

### Added

- Notch pet system — animated sprite characters (Bytie, Clodey, Ghosty, Sprout) live in the macOS notch with moods, movements, and speech bubbles
- Per-pet variant skins selectable in Settings
- Chattiness preference controlling how often the pet speaks
- Mini-game accessible from the popover
- Terminal / IDE launcher with configurable app picker (iTerm2, Warp, Ghostty, VS Code, Cursor, and more)
- System activity monitor powering pet idle detection and mood transitions
- Unit test suite (`Tests/ClaudeWatchTests/`) — 153 tests across API parsing, pace classification, usage history, notifications, and view-model logic
- Protocol-based dependency injection for core services (`CredentialsLoading`, `Logging`, `UsageFetching`, `UsageHistoryStoring`)

### Changed

- `SettingsView` decomposed into focused section files: General, Notifications, Hotkeys, Terminal, Visible Sections, Diagnostics
- `PopoverView` split into reusable subviews (`SessionEstimateRow`, `UsageSectionsStack`, `PopoverFooterRow`, `PopoverRateLimitBanner`, `PlanStreakRow`)
- Shared UI helpers extracted to `Views/Shared/` and general utilities to `Utilities/`
- Pace classification moved into a dedicated `PaceClassifier` service

## [1.2.0] - 2026-04-08

### Added

- Extra (pay-as-you-go) usage tracking — displays spend, monthly limit, and utilization when the API returns extra-usage data
- New `ExtraUsageSectionView` with color-coded progress bar and spend/limit breakdown
- Debug logging for raw API responses to aid troubleshooting

### Changed

- API log sanitization rewritten with Swift Regex literals (compile-time verified) replacing `NSRegularExpression`
- ISO 8601 date formatters promoted to static properties — allocated once instead of on every API response
- HTTP error messages simplified for clarity
- Date-parse failure logs no longer include the raw value (privacy improvement)

### Fixed

- TOCTOU race condition in `LogService.writeEntry` — replaced existence check + open with atomic `O_CREAT | O_WRONLY | O_APPEND`

## [1.1.1] - 2026-03-26

### Added

- Appearance mode setting (System / Light / Dark) with live toggle
- Share screenshot now respects the active appearance mode
- Gradient progress bars with highlight effect on usage sections
- Glassmorphism-style UI using `.ultraThinMaterial` backgrounds throughout
- Subtle glow effect on session estimate circular timer
- Linear gradient borders on action buttons and settings sections

### Changed

- Popover background switched from opaque to translucent material
- Action buttons reworked with material fill, gradient borders, and soft shadows
- Settings sections redesigned with material cards, bolder headers, and refined spacing
- Rate-limit banner and pace badge refined with softer opacity values
- Footer and header rows now use material backgrounds for visual consistency
- Settings footer uses labeled buttons (Refresh Now, Quit) with icons
- Share picker window lookup is more resilient (falls back through key/main/first window)
- Version string extracted to a computed property for reuse

### Fixed

- `.dmg` files now excluded from version control via `.gitignore`
- Content area no longer clips tall layouts thanks to `fixedSize` modifier
- Sparkline label now shows "7d" instead of "168h" when 7-day window is selected

## [1.0.0] - 2026-03-24

### Added

- Menu bar live view with color-coded usage status
- Session (5-hour) and weekly (7-day) usage tracking
- Model-specific limits for Sonnet and Opus
- Rate limit detection with countdown timer and exponential backoff
- Sparkline charts for session and weekly usage trends
- Configurable notification thresholds with presets
- Limit reached and window reset notifications with ETA
- Usage pace calculation and projection
- Session time-to-empty estimate with circular timer
- Streak tracking (consecutive days of usage)
- Quick actions: open Claude Code, copy usage summary
- Terminal/IDE launcher with working directory support
- Compact mode for smaller screens
- Menu bar display styles (icon, session %, weekly %, pace)
- Launch at Login via ServiceManagement
- Settings persistence via UserDefaults
- Usage history persistence via Application Support
- OAuth authentication via macOS Keychain (reads Claude Code credentials)
