import Cocoa
import SwiftUI
import AVFoundation
import ServiceManagement

enum PomodoroState {
    case idle
    case work
    case shortBreak
    case longBreak
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow!
    var chimeTimer: Timer?
    var muteUntil: Date?

    // Pomodoro
    var pomodoroState: PomodoroState = .idle
    var pomodoroTimer: Timer?
    var pomodoroSecondsLeft: Int = 0
    var pomodoroCount: Int = 0  // Completed work sessions

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🔔"
            button.toolTip = "Hourly Chime"
        }

        setupMenu()
        loadSettings()
        startChimeTimer()

        // Keep app running
        NSApp.setActivationPolicy(.accessory)
    }

    func setupMenu() {
        let menu = NSMenu()

        // Next chime time
        let nextChimeText = getNextChimeText()
        let nextItem = NSMenuItem(title: nextChimeText, action: nil, keyEquivalent: "")
        nextItem.isEnabled = false
        menu.addItem(nextItem)

        // Hours until end of day
        let hoursUntilEnd = getHoursUntilEndOfDay()
        let endDayItem = NSMenuItem(title: hoursUntilEnd, action: nil, keyEquivalent: "")
        endDayItem.isEnabled = false
        menu.addItem(endDayItem)

        menu.addItem(NSMenuItem.separator())

        // Enable/Disable
        let enabledItem = NSMenuItem(
            title: ChimeSettings.shared.enabled ? "✓ Enabled" : "Disabled",
            action: #selector(toggleChime),
            keyEquivalent: ""
        )
        menu.addItem(enabledItem)

        // Mute option
        if let muteUntil = muteUntil, muteUntil > Date() {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let muteItem = NSMenuItem(
                title: "Muted until \(formatter.string(from: muteUntil))",
                action: #selector(unmute),
                keyEquivalent: ""
            )
            menu.addItem(muteItem)
        } else {
            let muteItem = NSMenuItem(
                title: "Mute for 1 hour",
                action: #selector(muteForHour),
                keyEquivalent: "m"
            )
            menu.addItem(muteItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Pomodoro section
        let pomoHeader = NSMenuItem(title: "🍅 Pomodoro", action: nil, keyEquivalent: "")
        pomoHeader.isEnabled = false
        menu.addItem(pomoHeader)

        if pomodoroState == .idle {
            menu.addItem(NSMenuItem(
                title: "Start Work (25 min)",
                action: #selector(startPomodoro),
                keyEquivalent: "p"
            ))
        } else {
            let stateText: String
            switch pomodoroState {
            case .work: stateText = "Working"
            case .shortBreak: stateText = "Short Break"
            case .longBreak: stateText = "Long Break"
            default: stateText = ""
            }
            let statusItem = NSMenuItem(
                title: "\(stateText) - \(formatTime(pomodoroSecondsLeft))",
                action: nil,
                keyEquivalent: ""
            )
            statusItem.isEnabled = false
            menu.addItem(statusItem)

            menu.addItem(NSMenuItem(
                title: "Stop Pomodoro",
                action: #selector(stopPomodoro),
                keyEquivalent: ""
            ))

            if pomodoroState == .shortBreak || pomodoroState == .longBreak {
                menu.addItem(NSMenuItem(
                    title: "Skip Break",
                    action: #selector(skipBreak),
                    keyEquivalent: ""
                ))
            }
        }

        let countItem = NSMenuItem(
            title: "Sessions: \(pomodoroCount)/4",
            action: nil,
            keyEquivalent: ""
        )
        countItem.isEnabled = false
        menu.addItem(countItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem(
            title: "Test Sound",
            action: #selector(testSound),
            keyEquivalent: "t"
        ))

        menu.addItem(NSMenuItem.separator())

        // Launch at Login
        let launchItem = NSMenuItem(
            title: isLaunchAtLoginEnabled() ? "✓ Launch at Login" : "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    func getNextChimeText() -> String {
        let settings = ChimeSettings.shared
        guard settings.enabled else { return "Next: Disabled" }

        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        // Find next chime time
        var nextHour = hour
        if minute > 0 || hour * 60 % settings.frequencyMinutes != 0 {
            // Round up to next frequency interval
            let currentMinutes = hour * 60 + minute
            let nextMinutes = ((currentMinutes / settings.frequencyMinutes) + 1) * settings.frequencyMinutes
            nextHour = nextMinutes / 60
        }

        // Check if within active hours
        if nextHour < settings.startHour {
            nextHour = settings.startHour
        } else if nextHour >= settings.endHour {
            return "Next: Tomorrow \(formatHour(settings.startHour))"
        }

        return "Next: \(formatHour(nextHour))"
    }

    func getHoursUntilEndOfDay() -> String {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        let settings = ChimeSettings.shared
        let endHour = settings.endHour  // Default 18 (6 PM)

        if hour >= endHour {
            return "Work day ended"
        }

        // Calculate hours and minutes remaining
        let currentMinutes = hour * 60 + minute
        let endMinutes = endHour * 60
        let remainingMinutes = endMinutes - currentMinutes

        let hoursLeft = remainingMinutes / 60
        let minsLeft = remainingMinutes % 60

        if hoursLeft == 0 {
            return "\(minsLeft) min until \(formatHour(endHour))"
        } else if minsLeft == 0 {
            return "\(hoursLeft) hr\(hoursLeft > 1 ? "s" : "") until \(formatHour(endHour))"
        } else {
            return "\(hoursLeft)h \(minsLeft)m until \(formatHour(endHour))"
        }
    }

    func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    @objc func muteForHour() {
        muteUntil = Date().addingTimeInterval(3600)
        setupMenu()
    }

    @objc func unmute() {
        muteUntil = nil
        setupMenu()
    }

    // MARK: - Pomodoro

    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    @objc func startPomodoro() {
        pomodoroState = .work
        pomodoroSecondsLeft = 25 * 60  // 25 minutes
        updateMenuBarTitle()
        startPomodoroTimer()
        setupMenu()
    }

    @objc func stopPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroState = .idle
        pomodoroSecondsLeft = 0
        updateMenuBarTitle()
        setupMenu()
    }

    @objc func skipBreak() {
        pomodoroTimer?.invalidate()
        startPomodoro()
    }

    func startPomodoroTimer() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickPomodoro()
        }
    }

    func tickPomodoro() {
        pomodoroSecondsLeft -= 1
        updateMenuBarTitle()

        if pomodoroSecondsLeft <= 0 {
            pomodoroTimer?.invalidate()
            pomodoroSessionEnded()
        }
    }

    func pomodoroSessionEnded() {
        // Play ping sound
        playPomodoroSound()

        switch pomodoroState {
        case .work:
            pomodoroCount += 1
            if pomodoroCount >= 4 {
                // Long break after 4 work sessions
                pomodoroState = .longBreak
                pomodoroSecondsLeft = 15 * 60  // 15 minutes
                showPomodoroNotification("Work done! Take a long break (15 min)")
                pomodoroCount = 0
            } else {
                // Short break
                pomodoroState = .shortBreak
                pomodoroSecondsLeft = 5 * 60  // 5 minutes
                showPomodoroNotification("Work done! Take a short break (5 min)")
            }
            startPomodoroTimer()

        case .shortBreak, .longBreak:
            // Break over, start new work session
            pomodoroState = .work
            pomodoroSecondsLeft = 25 * 60
            showPomodoroNotification("Break over! Time to focus (25 min)")
            startPomodoroTimer()

        default:
            break
        }

        updateMenuBarTitle()
        setupMenu()
    }

    func playPomodoroSound() {
        let soundPath = "/System/Library/Sounds/Ping.aiff"
        let url = URL(fileURLWithPath: soundPath)
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    func showPomodoroNotification(_ message: String) {
        let script = """
            display notification "\(message)" with title "🍅 Pomodoro"
            """
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        try? process.run()
    }

    func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }

        if pomodoroState != .idle {
            let mins = pomodoroSecondsLeft / 60
            let secs = pomodoroSecondsLeft % 60
            let emoji = pomodoroState == .work ? "🍅" : "☕"
            button.title = String(format: "%@ %d:%02d", emoji, mins, secs)
        } else {
            button.title = "🔔"
        }
    }

    func isLaunchAtLoginEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    @objc func toggleLaunchAtLogin() {
        do {
            if isLaunchAtLoginEnabled() {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
        setupMenu()
    }

    @objc func toggleChime() {
        ChimeSettings.shared.enabled.toggle()
        ChimeSettings.shared.save()
        setupMenu()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 180),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow.title = "Hourly Chime"
            settingsWindow.contentView = NSHostingView(rootView: contentView)
            settingsWindow.center()
            settingsWindow.isReleasedWhenClosed = false
        }
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func testSound() {
        playChime()
        let hour = Calendar.current.component(.hour, from: Date())
        showNotification(hour: hour)
    }

    func loadSettings() {
        ChimeSettings.shared.load()
    }

    func startChimeTimer() {
        // Check every 30 seconds - simple and reliable
        chimeTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkAndPlayChime()
        }

        // Also check immediately
        checkAndPlayChime()
    }

    var lastPlayedMinute: Int = -1

    func checkAndPlayChime() {
        // Run on main thread to avoid crashes with settings updates
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let settings = ChimeSettings.shared

            guard settings.enabled else { return }

            // Check if muted
            if let muteUntil = self.muteUntil, muteUntil > Date() {
                return
            }

            let now = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)

            guard let weekday = components.weekday,
                  let hour = components.hour,
                  let minute = components.minute else { return }

            // Check if today is enabled (weekday: 1=Sunday, 2=Monday, ..., 7=Saturday)
            let dayIndex = (weekday + 5) % 7 // Convert to 0=Monday, 6=Sunday

            // Safely access array with bounds check
            guard dayIndex >= 0 && dayIndex < settings.enabledDays.count else { return }
            guard settings.enabledDays[dayIndex] else { return }

            // Check if we're within the time range
            guard hour >= settings.startHour && hour < settings.endHour else { return }

            // Check if it's time to play (based on frequency)
            let minutesSinceMidnight = hour * 60 + minute
            if minutesSinceMidnight % settings.frequencyMinutes == 0 {
                // Only play once per minute (prevent double-play)
                if self.lastPlayedMinute != minutesSinceMidnight {
                    self.lastPlayedMinute = minutesSinceMidnight
                    self.playChime()
                    self.showNotification(hour: hour)
                    self.setupMenu() // Update next chime time
                }
            }
        }
    }

    func showNotification(hour: Int) {
        let script = """
            display notification "It's \(formatHour(hour))" with title "🔔 Hourly Chime"
            """
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        try? process.run()
    }

    func playChime() {
        let soundPath = "/System/Library/Sounds/Hero.aiff"
        let url = URL(fileURLWithPath: soundPath)

        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}

// Settings Model
class ChimeSettings: ObservableObject {
    static let shared = ChimeSettings()

    @Published var enabled: Bool = true
    @Published var enabledDays: [Bool] = Array(repeating: true, count: 7) // Mon-Sun
    @Published var startHour: Int = 9
    @Published var endHour: Int = 18
    @Published var frequencyMinutes: Int = 60

    private let defaults = UserDefaults.standard

    func save() {
        DispatchQueue.main.async {
            self.defaults.set(self.enabled, forKey: "enabled")
            self.defaults.set(self.enabledDays, forKey: "enabledDays")
            self.defaults.set(self.startHour, forKey: "startHour")
            self.defaults.set(self.endHour, forKey: "endHour")
            self.defaults.set(self.frequencyMinutes, forKey: "frequencyMinutes")
            self.defaults.synchronize()
        }
    }

    func load() {
        enabled = defaults.object(forKey: "enabled") as? Bool ?? true
        if let days = defaults.array(forKey: "enabledDays") as? [Bool], days.count == 7 {
            enabledDays = days
        }
        startHour = defaults.integer(forKey: "startHour")
        if startHour == 0 { startHour = 9 }
        endHour = defaults.integer(forKey: "endHour")
        if endHour == 0 { endHour = 18 }
        frequencyMinutes = defaults.integer(forKey: "frequencyMinutes")
        if frequencyMinutes == 0 { frequencyMinutes = 60 }
    }
}

// Settings View
struct SettingsView: View {
    @ObservedObject var settings = ChimeSettings.shared
    let dayNames = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Days
            HStack {
                Text("Days")
                    .frame(width: 70, alignment: .leading)
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        DayToggle(label: dayNames[index], isOn: $settings.enabledDays[index])
                    }
                }
            }

            // Hours
            HStack {
                Text("Hours")
                    .frame(width: 70, alignment: .leading)
                Picker("", selection: $settings.startHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .labelsHidden()
                .frame(width: 85)
                Text("to")
                Picker("", selection: $settings.endHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .labelsHidden()
                .frame(width: 85)
            }

            // Frequency
            HStack {
                Text("Every")
                    .frame(width: 70, alignment: .leading)
                HStack(spacing: 6) {
                    FrequencyButton(label: "15m", value: 15, selected: $settings.frequencyMinutes)
                    FrequencyButton(label: "30m", value: 30, selected: $settings.frequencyMinutes)
                    FrequencyButton(label: "1h", value: 60, selected: $settings.frequencyMinutes)
                    FrequencyButton(label: "2h", value: 120, selected: $settings.frequencyMinutes)
                }
            }

            Divider()

            // Buttons
            HStack {
                Button("🔊 Test") {
                    let url = URL(fileURLWithPath: "/System/Library/Sounds/Hero.aiff")
                    var soundID: SystemSoundID = 0
                    AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
                    AudioServicesPlaySystemSound(soundID)
                }

                Spacer()

                Button("Cancel") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    settings.save()
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 340, height: 180)
    }

    func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

// Custom day toggle button
struct DayToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(isOn ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isOn ? .white : .primary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

// Custom frequency button
struct FrequencyButton: View {
    let label: String
    let value: Int
    @Binding var selected: Int

    var body: some View {
        Button(action: { selected = value }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 36, height: 26)
                .background(selected == value ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(selected == value ? .white : .primary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
