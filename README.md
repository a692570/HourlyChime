# HourlyChime ⏰

A minimalist macOS menu bar app that chimes on the hour to help you stay aware of time passing during your workday.

![Menu Bar](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

### 🔔 Hourly Chime
- Plays a pleasant chime sound at configurable intervals
- Customizable frequency: 15 minutes, 30 minutes, 1 hour, or 2 hours
- Set your work hours (default: 9 AM - 6 PM)
- Choose which days of the week to enable
- Mute for 1 hour when you need silence
- Shows next chime time and hours remaining in your workday

### 🍅 Built-in Pomodoro Timer
- Work sessions: 25 minutes
- Short breaks: 5 minutes
- Long breaks: 15 minutes (after 4 work sessions)
- Live countdown in menu bar
- Notifications when sessions start/end
- Skip breaks when you're in the flow

### ⚙️ Additional Features
- Launch at login support
- Lives quietly in your menu bar
- Test sound before committing
- Simple, distraction-free interface

## Why?

We spend hours at our computers and time flies by without us noticing. HourlyChime is a gentle reminder that time is passing, helping you:
- Take regular breaks
- Stay aware of how long you've been working
- Maintain better work-life boundaries
- Use the Pomodoro Technique for focused work

## Installation

### From Source

**Requirements:**
- macOS 13.0 or later
- Xcode Command Line Tools or Xcode

**Build Steps:**

```bash
# Clone the repository
git clone https://github.com/a692570/HourlyChime.git
cd HourlyChime

# Build the app
swift build -c release

# Copy to Applications (optional)
cp -r HourlyChime.app /Applications/
```

**Run the app:**
```bash
open HourlyChime.app
```

Or launch directly:
```bash
.build/release/HourlyChime
```

## Usage

### Basic Setup

1. **Launch the app** - A 🔔 icon appears in your menu bar
2. **Click the icon** to see the menu
3. **Open Settings** (⌘,) to configure:
   - Which days to enable (M-F for work days, or 7 days)
   - Work hours (when to play chimes)
   - Frequency (how often to chime)

### Hourly Chime

The app will automatically play a chime sound at your configured interval during your set work hours. The menu shows:
- Next chime time
- Hours remaining until end of day
- Enable/disable toggle
- Mute for 1 hour option

### Pomodoro Timer

1. Click the menu bar icon
2. Select **Start Work (25 min)** (⌘P)
3. The icon changes to 🍅 with countdown timer
4. After work session, take a break ☕
5. Repeat until 4 sessions complete, then take a long break

You can:
- Stop the timer anytime
- Skip breaks when focused
- See session count (X/4)

### Keyboard Shortcuts

- `⌘,` - Open Settings
- `⌘T` - Test Sound
- `⌘M` - Mute for 1 hour
- `⌘P` - Start Pomodoro
- `⌘Q` - Quit

## Configuration

Settings are stored in `~/Library/Preferences/com.abhishek.hourlychime.plist`

Default configuration:
- **Days:** Monday - Sunday (all enabled)
- **Hours:** 9 AM - 6 PM
- **Frequency:** Every 1 hour
- **Sound:** macOS "Hero" sound

## Sounds

The app uses macOS built-in sounds:
- **Hourly Chime:** Hero.aiff
- **Pomodoro:** Ping.aiff

These are pleasant, non-intrusive sounds that won't disrupt your flow.

## Development

### Project Structure

```
HourlyChime/
├── Package.swift           # Swift Package Manager config
├── Sources/
│   └── main.swift         # All app code (single file)
└── HourlyChime.app/       # Built application bundle
```

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run directly
swift run
```

### Architecture

Built with:
- **SwiftUI** for Settings window
- **AppKit** for menu bar integration
- **AVFoundation** for sound playback
- **ServiceManagement** for launch at login

Single-file architecture (~660 lines) for simplicity and maintainability.

## Troubleshooting

### App doesn't launch
- Make sure you're on macOS 13.0 or later
- Rebuild: `swift build -c release`

### Sound doesn't play
- Check system volume
- Use "Test Sound" in menu to verify
- Sounds require `/System/Library/Sounds/` to exist

### Chimes not playing at expected times
- Verify days/hours in Settings
- Check if muted
- Ensure app is running (look for 🔔 in menu bar)

### Launch at login not working
- macOS may require explicit permission
- Check System Settings → General → Login Items

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

**Abhishek Sharma** ([@a692570](https://github.com/a692570))

## Acknowledgments

- Inspired by the need for better time awareness during deep work
- Built with Apple's excellent Swift and AppKit frameworks
- Pomodoro Technique by Francesco Cirillo

---

**Built with ❤️ for focused, mindful work.**
