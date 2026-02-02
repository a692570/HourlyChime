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
    var chimeTimer: DispatchSourceTimer?
    var menuUpdateTimer: Timer?
    var muteUntil: Date?

    // Cached sound IDs (fix: audio memory leak)
    private var chimeSoundID: SystemSoundID = 0
    private var pomodoroSoundID: SystemSoundID = 0

    // Pomodoro
    var pomodoroState: PomodoroState = .idle
    var pomodoroTimer: Timer?
    var pomodoroSecondsLeft: Int = 0
    var pomodoroEndTime: Date?  // fix: track wall-clock time for sleep/wake
    var pomodoroCount: Int = 0

    var lastPlayedMinute: Int = -1

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🔔"
            button.toolTip = "Hourly Chime"
            button.setAccessibilityLabel("Hourly Chime")
            button.setAccessibilityRole(.menuButton)
        }

        setupSounds()
        setupMenu()
        loadSettings()
        startChimeTimer()
        startMenuUpdateTimer()

        // Listen for sleep/wake (fix: Pomodoro timer accuracy)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )

        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // fix: proper cleanup on quit
        chimeTimer?.cancel()
        chimeTimer = nil
        menuUpdateTimer?.invalidate()
        menuUpdateTimer = nil
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        if chimeSoundID != 0 {
            AudioServicesDisposeSystemSoundID(chimeSoundID)
        }
        if pomodoroSoundID != 0 {
            AudioServicesDisposeSystemSoundID(pomodoroSoundID)
        }
    }

    // MARK: - Sound (fix: cache sound IDs, create once)

    func setupSounds() {
        let chimeURL = URL(fileURLWithPath: "/System/Library/Sounds/Hero.aiff")
        AudioServicesCreateSystemSoundID(chimeURL as CFURL, &chimeSoundID)

        let pomodoroURL = URL(fileURLWithPath: "/System/Library/Sounds/Ping.aiff")
        AudioServicesCreateSystemSoundID(pomodoroURL as CFURL, &pomodoroSoundID)
    }

    func playChime() {
        AudioServicesPlaySystemSound(chimeSoundID)
    }

    func playPomodoroSound() {
        AudioServicesPlaySystemSound(pomodoroSoundID)
    }

    // MARK: - Sleep/Wake

    @objc func handleWake() {
        // Recalculate Pomodoro time remaining after sleep
        if pomodoroState != .idle, let endTime = pomodoroEndTime {
            let remaining = endTime.timeIntervalSinceNow
            if remaining <= 0 {
                // Session ended while asleep
                pomodoroSessionEnded()
            } else {
                pomodoroSecondsLeft = Int(remaining)
                updateMenuBarTitle()
                setupMenu()
            }
        }

        // Re-sync chime timer after wake
        checkAndPlayChime()
    }

    // MARK: - Menu

    func setupMenu() {
        let menu = NSMenu()

        let nextChimeText = getNextChimeText()
        let nextItem = NSMenuItem(title: nextChimeText, action: nil, keyEquivalent: "")
        nextItem.isEnabled = false
        menu.addItem(nextItem)

        let hoursUntilEnd = getHoursUntilEndOfDay()
        let endDayItem = NSMenuItem(title: hoursUntilEnd, action: nil, keyEquivalent: "")
        endDayItem.isEnabled = false
        menu.addItem(endDayItem)

        menu.addItem(NSMenuItem.separator())

        let enabledItem = NSMenuItem(
            title: ChimeSettings.shared.enabled ? "✓ Enabled" : "Disabled",
            action: #selector(toggleChime),
            keyEquivalent: ""
        )
        menu.addItem(enabledItem)

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

        var nextHour = hour
        if minute > 0 || hour * 60 % settings.frequencyMinutes != 0 {
            let currentMinutes = hour * 60 + minute
            let nextMinutes = ((currentMinutes / settings.frequencyMinutes) + 1) * settings.frequencyMinutes
            nextHour = nextMinutes / 60
        }

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
        let endHour = settings.endHour

        if hour >= endHour {
            return "Work day ended"
        }

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
        pomodoroSecondsLeft = 25 * 60
        pomodoroEndTime = Date().addingTimeInterval(25 * 60)  // fix: wall-clock tracking
        updateMenuBarTitle()
        startPomodoroTimer()
        setupMenu()
    }

    @objc func stopPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroState = .idle
        pomodoroSecondsLeft = 0
        pomodoroEndTime = nil
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
        // fix: use wall-clock time instead of decrement (handles sleep/wake)
        if let endTime = pomodoroEndTime {
            let remaining = endTime.timeIntervalSinceNow
            pomodoroSecondsLeft = max(0, Int(remaining))
        } else {
            pomodoroSecondsLeft -= 1
        }

        updateMenuBarTitle()

        if pomodoroSecondsLeft <= 0 {
            pomodoroTimer?.invalidate()
            pomodoroSessionEnded()
        }
    }

    func pomodoroSessionEnded() {
        playPomodoroSound()

        switch pomodoroState {
        case .work:
            pomodoroCount += 1
            if pomodoroCount >= 4 {
                pomodoroState = .longBreak
                pomodoroSecondsLeft = 15 * 60
                pomodoroEndTime = Date().addingTimeInterval(15 * 60)
                showPomodoroNotification("Work done! Take a long break (15 min)")
                pomodoroCount = 0
            } else {
                pomodoroState = .shortBreak
                pomodoroSecondsLeft = 5 * 60
                pomodoroEndTime = Date().addingTimeInterval(5 * 60)
                showPomodoroNotification("Work done! Take a short break (5 min)")
            }
            startPomodoroTimer()

        case .shortBreak, .longBreak:
            pomodoroState = .work
            pomodoroSecondsLeft = 25 * 60
            pomodoroEndTime = Date().addingTimeInterval(25 * 60)
            showPomodoroNotification("Break over! Time to focus (25 min)")
            startPomodoroTimer()

        default:
            break
        }

        updateMenuBarTitle()
        setupMenu()
    }

    // fix: escape AppleScript strings
    func escapeAppleScript(_ string: String) -> String {
        string.replacingOccurrences(of: "\\", with: "\\\\")
              .replacingOccurrences(of: "\"", with: "\\\"")
    }

    func showPomodoroNotification(_ message: String) {
        let script = """
            display notification "\(escapeAppleScript(message))" with title "🍅 Pomodoro"
            """
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        try? process.run()
    }

    func showNotification(hour: Int) {
        let hourText = formatHour(hour)
        let script = """
            display notification "\(escapeAppleScript("It's \(hourText)"))" with title "🔔 Hourly Chime"
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
            settingsWindow.isReleasedWhenClosed = false
        }

        // fix: position near menu bar instead of center screen
        if let button = statusItem.button, let buttonWindow = button.window {
            let buttonFrame = buttonWindow.frame
            let windowWidth: CGFloat = 340
            let windowHeight: CGFloat = 180
            let x = buttonFrame.midX - windowWidth / 2
            let y = buttonFrame.minY - windowHeight - 4
            settingsWindow.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            settingsWindow.center()
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

    // fix: use DispatchSourceTimer synced to minute boundaries for accuracy
    func startChimeTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)

        // Sync to next minute boundary
        let calendar = Calendar.current
        let now = Date()
        var nextMinute = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        nextMinute.minute! += 1
        nextMinute.second = 0
        let nextTick = calendar.date(from: nextMinute) ?? now.addingTimeInterval(60)
        let delay = max(0, nextTick.timeIntervalSince(now))

        timer.schedule(deadline: .now() + delay, repeating: .seconds(30))
        timer.setEventHandler { [weak self] in self?.checkAndPlayChime() }
        timer.resume()
        chimeTimer = timer

        // Also check immediately
        checkAndPlayChime()
    }

    func startMenuUpdateTimer() {
        menuUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.setupMenu()
        }
    }

    func checkAndPlayChime() {
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

        // weekday: 1=Sunday, 2=Monday ... 7=Saturday -> 0=Monday, 6=Sunday
        let dayIndex = (weekday + 5) % 7

        guard dayIndex >= 0 && dayIndex < settings.enabledDays.count else { return }
        guard settings.enabledDays[dayIndex] else { return }

        guard hour >= settings.startHour && hour < settings.endHour else { return }

        let minutesSinceMidnight = hour * 60 + minute
        if minutesSinceMidnight % settings.frequencyMinutes == 0 {
            if self.lastPlayedMinute != minutesSinceMidnight {
                self.lastPlayedMinute = minutesSinceMidnight
                self.playChime()
                self.showNotification(hour: hour)
                self.setupMenu()
            }
        }
    }
}

// Settings Model
class ChimeSettings: ObservableObject {
    static let shared = ChimeSettings()

    private let lock = NSLock()  // fix: thread safety

    @Published var enabled: Bool = true
    @Published var enabledDays: [Bool] = Array(repeating: true, count: 7)
    @Published var startHour: Int = 9
    @Published var endHour: Int = 18
    @Published var frequencyMinutes: Int = 60

    private let defaults = UserDefaults.standard

    func save() {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(enabled, forKey: "enabled")
        defaults.set(enabledDays, forKey: "enabledDays")
        defaults.set(startHour, forKey: "startHour")
        defaults.set(endHour, forKey: "endHour")
        defaults.set(frequencyMinutes, forKey: "frequencyMinutes")
        defaults.synchronize()
    }

    func load() {
        lock.lock()
        defer { lock.unlock() }
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
    // fix: clearer day abbreviations (no ambiguous T/T, S/S)
    let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Days
            HStack {
                Text("Days")
                    .frame(width: 70, alignment: .leading)
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        DayToggle(label: dayNames[index], isOn: $settings.enabledDays[index])
                    }
                }
            }

            // Hours (fix: end hour validates against start hour)
            HStack {
                Text("Hours")
                    .frame(width: 70, alignment: .leading)
                Picker("", selection: $settings.startHour) {
                    ForEach(0..<23, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .labelsHidden()
                .frame(width: 85)
                Text("to")
                Picker("", selection: $settings.endHour) {
                    ForEach((settings.startHour + 1)..<24, id: \.self) { hour in
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

            HStack {
                Button("🔊 Test") {
                    // Uses cached sound ID via AppDelegate
                    let url = URL(fileURLWithPath: "/System/Library/Sounds/Hero.aiff")
                    var soundID: SystemSoundID = 0
                    AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
                    AudioServicesPlaySystemSound(soundID)
                    AudioServicesDisposeSystemSoundID(soundID)
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

struct DayToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 32, height: 26)
                .background(isOn ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isOn ? .white : .primary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(isOn ? "enabled" : "disabled")")
    }
}

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

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
