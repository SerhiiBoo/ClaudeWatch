<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="Claude Watch icon" />
</p>

<h1 align="center">Claude Watch</h1>

---

<p align="center">
  🇺🇦 <strong>Stand with Ukraine</strong> 🇺🇦<br/>
  russia is waging a war of aggression against Ukraine. Civilians are dying. Cities are being destroyed.<br/>
  Please consider donating to support Ukraine and its people.<br/>
  <a href="https://u24.gov.ua/"><strong>United24 — Official Ukraine Fundraising Platform →</strong></a>
</p>

---

<p align="center">
  A lightweight macOS menu bar app that monitors your <a href="https://claude.ai">Claude</a> API usage in real time.<br/>
  Session limits, weekly quotas, rate limits, and pace — without ever leaving your workflow.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue?style=flat-square" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square" alt="Swift 5.9" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License" />
  <img src="https://github.com/SerhiiBoo/ClaudeWatch/actions/workflows/build.yml/badge.svg" alt="Build" />
</p>

---

## Features

<table>
<tr>
<td width="50%">

### Live Menu Bar
Color-coded status icon with configurable display — session %, weekly %, combined, or pace (%/h). Always one glance away.

### Usage Breakdown
Session (5-hour) and weekly (7-day) limits with progress bars, plus model-specific caps for Sonnet and Opus.

### Smart Notifications
Alerts at configurable thresholds (50%, 80%, 90%…), on limit hit with restoration ETA, and on limit reset.

### Usage Pace
Tracks your consumption rate (%/hour) and projects whether you're on track to hit limits.

</td>
<td width="50%">

### Sparkline Charts
Rolling usage history visualized as mini trend charts — configurable from 6 hours to 7 days.

### Rate Limit Tracking
Automatic 429 detection with countdown timer and exponential backoff. Visual banner shows time remaining.

### Quick Actions
Launch Claude Code, your terminal, or IDE directly from the popover. Supports 12+ apps with custom working directory.

### Fully Local
Zero telemetry, zero analytics. Your OAuth token never leaves your machine — read directly from the macOS Keychain.

</td>
</tr>
</table>

---

## Quick Start

> **Requirements:** macOS 14 Sonoma or later + a Claude account (OAuth token retrieved automatically from Claude Code)

### Download (recommended)

1. Grab the latest `ClaudeWatch.dmg` from the [Releases](https://github.com/SerhiiBoo/ClaudeWatch/releases) page
2. Open the DMG and drag **Claude Watch** to `/Applications`
3. On first launch, macOS will block the app because it is not notarized — see [Opening on macOS Sequoia+](#opening-on-macos-sequoia) below

### Build from source

```bash
git clone https://github.com/SerhiiBoo/ClaudeWatch.git
cd ClaudeWatch
make install    # builds, bundles, and copies to /Applications
```

### Run without installing

```bash
make run
```

### Getting started

1. Launch **Claude Watch** from `/Applications` (or `make run`)
2. Click the menu bar icon to open the usage popover
3. On first launch, follow the prompt to log in via Claude Code
4. Configure notifications and display in **Settings** (gear icon)

---

## Configuration

Open the popover → gear icon → **Settings**:

| Setting | Options |
|---|---|
| **Notification thresholds** | Custom usage % levels (e.g. 50%, 80%, 90%) |
| **Limit alerts** | On limit hit (with reset ETA) and on limit restored |
| **Sparkline range** | 6h, 12h, 24h, or 7d |
| **Pace window** | 1h, 2h, or 4h lookback |
| **Menu bar style** | Icon only / Session % / Weekly % / Session + Weekly / Pace (%/h) |
| **Quick actions** | Terminal app + working directory |
| **Compact mode** | Condensed single-column layout |
| **Launch at Login** | Start automatically with macOS |

---

## Build Commands

| Command | Description |
|---|---|
| `make build` | Compile release binary |
| `make bundle` | Create `Claude Watch.app` |
| `make install` | Bundle + copy to `/Applications` |
| `make run` | Build, bundle, and launch |
| `make clean` | Remove build artifacts |

---

## Troubleshooting

### Common Issues

| Problem | Solution |
|---|---|
| **Menu bar icon doesn't appear** | Ensure macOS 14+ is installed. Try quitting and relaunching the app. |
| **"No OAuth token found"** | Log in to [Claude Code](https://docs.anthropic.com/en/docs/claude-code) at least once — Claude Watch reads the token from the macOS Keychain. |
| **Usage shows 0% after launch** | The first API poll happens within a few seconds. If it persists, check your internet connection and OAuth token. |
| **Rate limit banner won't go away** | This is normal — the app detects HTTP 429 responses and shows a countdown. It will clear automatically once the cooldown expires. |
| **Notifications not appearing** | Open **System Settings → Notifications → Claude Watch** and ensure notifications are enabled. |
| **App won't open (blocked by macOS)** | See [Opening on macOS Sequoia+](#opening-on-macos-sequoia) below. |

### Opening on macOS Sequoia+

Claude Watch is free and open-source but is not signed with an Apple Developer certificate. macOS Sequoia (15.0+) will block the app on first launch. To allow it:

1. Open **Claude Watch** — macOS will show a blocked/warning dialog. Dismiss it.
2. Open **System Settings → Privacy & Security**
3. Scroll down to the Security section — you will see *"Claude Watch" was blocked from use because it is not from an identified developer*
4. Click **Open Anyway** and authenticate with your password or Touch ID
5. macOS will ask one more time — click **Open**

This only needs to be done once. After that, the app will open normally.

**Alternative (Terminal):** Strip the quarantine attribute and open directly:

```bash
xattr -cr "/Applications/Claude Watch.app"
open "/Applications/Claude Watch.app"
```

### Exporting Logs

Claude Watch keeps structured diagnostic logs with automatic rotation. To export them:

1. Click the menu bar icon → **gear icon** → **Settings**
2. Scroll to the bottom and click **Export Logs**
3. Choose a save location — the exported file includes a system info header (app version, macOS version, timestamp) and sanitized log entries

> **Privacy:** Logs are automatically sanitized — OAuth tokens, API keys, and other sensitive values are redacted before writing.

### Reporting Issues

If you run into a bug, please [open an issue](https://github.com/SerhiiBoo/ClaudeWatch/issues/new?template=bug_report.md) with the following:

1. **Describe the bug** — what happened vs. what you expected
2. **Steps to reproduce** — numbered steps to trigger the issue
3. **Environment** — macOS version, Claude Watch version (shown in Settings), Claude plan (Pro/Max)
4. **Attach logs** — export logs via Settings (see above) and attach the file to the issue

#### Quick Bug Report Template

```
**Bug:** [one-line summary]

**Steps:**
1. ...
2. ...

**Expected:** [what should happen]
**Actual:** [what happened instead]

**Environment:**
- macOS: [e.g. 15.3]
- Claude Watch: [e.g. 1.0.0]
- Plan: [Pro / Max]

**Logs:** [attach exported log file]
```

For feature requests, use the [feature request template](https://github.com/SerhiiBoo/ClaudeWatch/issues/new?template=feature_request.md).

---

## Contributing

Pull requests are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

For significant changes, please open an issue first to discuss what you'd like to change.

## License

MIT © [Serhii Boo](https://github.com/SerhiiBoo) — see [LICENSE](LICENSE) for details.
