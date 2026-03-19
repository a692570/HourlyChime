# HourlyChime

A macOS menu bar app that chimes on the hour. Also has a built-in Pomodoro timer.

You look up and it is 4pm. This app prevents that.

![macOS 13.0+](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)
![MIT](https://img.shields.io/badge/license-MIT-green.svg)

Current release: `v1.0.2`

## What it does

**Hourly chime:** Plays a short sound at regular intervals during your work hours. Configurable frequency: 15 min, 30 min, 1 hour, or 2 hours. Configurable work hours and days. Shows next chime time and hours remaining in your day.

**Pomodoro timer:** 25-min work sessions, 5-min short breaks, 15-min long break after 4 sessions. Live countdown in the menu bar. Skip breaks when you are in the zone.

**Menu bar only.** No dock icon, no window. Click the bell to see controls, start a Pomodoro, mute for an hour, or open settings.

## What is new in v1.0.2

- Split the app into smaller files for menu logic, scheduling, settings, sound, and notifications
- Fixed chime suppression across day boundaries
- Replaced AppleScript notifications with `UNUserNotificationCenter`
- Added a small checks target for schedule behavior
- Cleaned up Pomodoro state handling and settings editing

## Install

Download from [Releases](https://github.com/a692570/HourlyChime/releases/latest), unzip, drag to Applications.

On first launch, macOS may block it because it is not from the App Store. Right-click the app, select "Open", then click "Open" in the dialog. One-time thing.

### Build from source

```bash
git clone https://github.com/a692570/HourlyChime.git
cd HourlyChime
swift build -c release
swift run -c release HourlyChimeChecks
.build/release/HourlyChime
```

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `⌘,` | Settings |
| `⌘P` | Start Pomodoro |
| `⌘M` | Mute for 1 hour |
| `⌘T` | Test sound |
| `⌘Q` | Quit |

## Settings

Click the bell icon, then "Settings..." or press `⌘,`.

- **Days:** Pick which days to enable
- **Hours:** When to start and stop chiming
- **Frequency:** How often, 15m / 30m / 1h / 2h
- **Launch at Login:** Toggle from the menu

Preferences are stored at `~/Library/Preferences/com.abhishek.hourlychime.plist`.

## How it is built

- **SwiftUI** for the settings window
- **AppKit** for menu bar integration
- **AVFoundation** for sound playback
- **ServiceManagement** for launch at login
- **UserNotifications** for alerts

The app is split into focused files instead of one large source file.

Project layout:

```text
HourlyChime/
├── Package.swift
├── Sources/
│   ├── HourlyChime/main.swift
│   ├── AppDelegate.swift
│   ├── AppMenuBuilder.swift
│   ├── ChimeSchedule.swift
│   ├── ChimeSettings.swift
│   ├── NotificationManager.swift
│   ├── PomodoroSessionManager.swift
│   ├── SettingsView.swift
│   ├── SettingsViewModel.swift
│   ├── SettingsWindowController.swift
│   ├── SoundPlayer.swift
│   └── Formatters.swift
└── Tests/
    └── HourlyChimeChecks/main.swift
```

## Troubleshooting

**No menu bar icon:** Check the overflow area. Make sure you are on macOS 13.0+.

**No sound:** Check system volume. Try "Test Sound" from the menu. Verify you are within work hours.

**Notifications missing:** System Settings > Notifications > enable for HourlyChime.

**Uninstalling:**

```bash
killall HourlyChime
rm -rf /Applications/HourlyChime.app
rm ~/Library/Preferences/com.abhishek.hourlychime.plist
```

## License

MIT

## Author

Abhishek Sharma ([@a692570](https://github.com/a692570))
