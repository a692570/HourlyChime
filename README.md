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

### Easy Install (Recommended)

**Requirements:**
- macOS 13.0 (Ventura) or later

**Step-by-Step Installation:**

1. **Download the App**
   - Go to [Releases](https://github.com/a692570/HourlyChime/releases/latest)
   - Download `HourlyChime-v1.0.1-macOS-Signed.zip` (properly signed for macOS 15.4 Sequoia+)

2. **Unzip the File**
   - Double-click the downloaded zip file
   - macOS will automatically extract `HourlyChime.app`

3. **Move to Applications** (Optional but Recommended)
   ```bash
   # Drag the app to Applications folder, or use Terminal:
   mv ~/Downloads/HourlyChime.app /Applications/
   ```

4. **First Launch - Handle Security Warning**

   When you first open the app, macOS Gatekeeper will block it because it's not from the App Store:

   **Option A: Using Finder (Easiest)**
   - Right-click (or Control-click) on `HourlyChime.app`
   - Select **"Open"** from the menu
   - Click **"Open"** in the security dialog
   - The app will launch and appear in your menu bar as 🔔

   **Option B: Using System Settings**
   - Try to open the app normally (double-click)
   - macOS will show: "HourlyChime.app cannot be opened"
   - Open **System Settings** → **Privacy & Security**
   - Scroll down to find: "HourlyChime.app was blocked..."
   - Click **"Open Anyway"**
   - Click **"Open"** in the confirmation dialog

   **Option C: Using Terminal**
   ```bash
   # Remove quarantine attribute
   xattr -d com.apple.quarantine /Applications/HourlyChime.app

   # Then open normally
   open /Applications/HourlyChime.app
   ```

5. **Allow Notifications** (Optional)

   For Pomodoro timer notifications to work:
   - Go to **System Settings** → **Notifications**
   - Find **HourlyChime** or **Terminal** in the list
   - Enable notifications
   - Choose your preferred notification style (Alerts or Banners)

6. **Setup Launch at Login** (Optional)

   To have HourlyChime start automatically when you log in:
   - Click the 🔔 icon in your menu bar
   - Select **"Launch at Login"**
   - A checkmark ✓ will appear when enabled

   Or manually:
   - Go to **System Settings** → **General** → **Login Items**
   - Click the **+** button
   - Select HourlyChime.app
   - Click **"Add"**

7. **Configure Settings**
   - Click the 🔔 icon in menu bar
   - Select **"Settings..."** or press `⌘,`
   - Set your preferred:
     - Work days (M-F or all 7 days)
     - Work hours (default 9 AM - 6 PM)
     - Chime frequency (15m/30m/1h/2h)

**You're all set!** The app will now chime at your configured intervals. 🎉

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

# The executable is at:
# .build/release/HourlyChime

# Run directly
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

### macOS Security Warning

**Problem:** "HourlyChime.app cannot be opened because it is from an unidentified developer"

**Solution:**
- Right-click the app → **Open** → Click **Open** in dialog
- Or: System Settings → Privacy & Security → Click **"Open Anyway"**
- Or: Remove quarantine: `xattr -d com.apple.quarantine /Applications/HourlyChime.app`

### App doesn't appear in menu bar

**Problem:** App launched but no 🔔 icon visible

**Solution:**
- Check if it's hidden in menu bar overflow (>>)
- Restart the app: `killall HourlyChime-Release && open /Applications/HourlyChime.app`
- Check Activity Monitor to see if app is running
- Make sure you're on macOS 13.0 or later

### Notifications not showing

**Problem:** Pomodoro notifications don't appear

**Solution:**
- System Settings → Notifications → Find **HourlyChime** or **osascript**
- Enable "Allow Notifications"
- Choose notification style: Alerts or Banners
- Make sure "Do Not Disturb" is off

### Sound doesn't play

**Problem:** No chime sound when expected

**Solution:**
- Check system volume (not muted)
- Click menu icon → **"Test Sound"** to verify
- Verify sounds exist: `ls /System/Library/Sounds/Hero.aiff`
- Check if app is muted (shows "Muted until..." in menu)
- Ensure you're within configured work hours

### Chimes not playing at expected times

**Problem:** App is running but not chiming

**Solution:**
- Click menu icon → Check "Next: ..." shows expected time
- Verify in Settings (⌘,):
  - Today's day is checked (M-F or 7 days)
  - Current hour is within work hours (default 9 AM - 6 PM)
  - Frequency is set correctly (15m/30m/1h/2h)
- Check if chime is enabled (menu shows "✓ Enabled")
- Look for 🔔 icon in menu bar (if missing, app isn't running)

### Launch at login not working

**Problem:** App doesn't start when you log in

**Solution:**
- Click menu icon → Ensure "✓ Launch at Login" is checked
- Or manually: System Settings → General → Login Items → Add HourlyChime
- Try disabling and re-enabling "Launch at Login" in app menu
- Check Login Items permissions in System Settings

### App crashes on launch

**Problem:** App quits immediately after opening

**Solution:**
- Check Console.app for crash logs (search "HourlyChime")
- Ensure you're on macOS 13.0+: `sw_vers`
- Remove preferences: `rm ~/Library/Preferences/com.abhishek.hourlychime.plist`
- Rebuild from source: `cd HourlyChime && swift build -c release`
- Report issue on GitHub with crash log

### Permissions Issues

**Problem:** App needs permissions but dialog doesn't appear

**Solution:**
- System Settings → Privacy & Security → Notifications → Enable for HourlyChime
- If using AppleScript notifications, enable for **osascript** too
- Reset permissions: Delete app and reinstall

### Uninstalling

To completely remove HourlyChime:

```bash
# Quit the app
killall HourlyChime-Release

# Remove app
rm -rf /Applications/HourlyChime.app

# Remove preferences
rm ~/Library/Preferences/com.abhishek.hourlychime.plist

# Remove from Login Items
# System Settings → General → Login Items → Remove HourlyChime
```

### Still having issues?

- Check [existing issues](https://github.com/a692570/HourlyChime/issues)
- Create a [new issue](https://github.com/a692570/HourlyChime/issues/new) with:
  - macOS version: `sw_vers`
  - Steps to reproduce
  - Console.app logs if available

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
