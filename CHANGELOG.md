# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
