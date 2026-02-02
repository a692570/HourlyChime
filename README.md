# HourlyChime

A macOS menu bar app that chimes on the hour. Also has a built-in Pomodoro timer.

You look up and it's 4pm. This app prevents that.

![macOS 13.0+](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)
![MIT](https://img.shields.io/badge/license-MIT-green.svg)

## What it does

**Hourly chime:** Plays a short sound at regular intervals during your work hours. Configurable frequency (15 min, 30 min, 1 hour, 2 hours), configurable work hours and days. Shows next chime time and hours remaining in your day.

**Pomodoro timer:** 25-min work sessions, 5-min short breaks, 15-min long break after 4 sessions. Live countdown in the menu bar. Skip breaks when you're in the zone.

**Sits in your menu bar.** No dock icon, no window. Click the bell to see controls, start a Pomodoro, mute for an hour, or open settings.

## Install

Download from [Releases](https://github.com/a692570/HourlyChime/releases/latest), unzip, drag to Applications.

On first launch, macOS will block it (not from the App Store). Right-click the app, select "Open", then click "Open" in the dialog. One-time thing.

### Build from source

```bash
git clone https://github.com/a692570/HourlyChime.git
cd HourlyChime
swift build -c release
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

- **Days:** Pick which days to enable (weekdays, all 7, custom)
- **Hours:** When to start and stop chiming (default 9 AM to 6 PM)
- **Frequency:** How often (15m / 30m / 1h / 2h)
- **Launch at Login:** Toggle from the menu

Preferences stored at `~/Library/Preferences/com.abhishek.hourlychime.plist`.

## How it's built

Single Swift file (~660 lines). SwiftUI for the settings window, AppKit for menu bar integration, AVFoundation for sound. Uses macOS built-in sounds (Hero for chimes, Ping for Pomodoro).

```
HourlyChime/
├── Package.swift
├── Sources/
│   └── main.swift
└── README.md
```

## Troubleshooting

**No menu bar icon:** Check the overflow area (>> in the menu bar). Make sure you're on macOS 13.0+.

**No sound:** Check system volume. Try "Test Sound" from the menu. Verify you're within work hours.

**Notifications missing:** System Settings > Notifications > enable for HourlyChime.

**Want to uninstall:**
```bash
killall HourlyChime-Release
rm -rf /Applications/HourlyChime.app
rm ~/Library/Preferences/com.abhishek.hourlychime.plist
```

## License

MIT

## Author

Abhishek Sharma ([@a692570](https://github.com/a692570))
