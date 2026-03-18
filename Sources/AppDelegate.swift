import Cocoa
import ServiceManagement

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var chimeTimer: DispatchSourceTimer?
    private var menuUpdateTimer: Timer?
    private var muteUntil: Date?
    private var lastPlayedChimeKey: String?
    private let settings: ChimeSettings
    private let notificationManager: NotificationManager
    private let pomodoroSession = PomodoroSessionManager()
    private var pomodoroTimer: Timer?
    private let settingsWindowController: SettingsWindowController

    public init(settings: ChimeSettings = ChimeSettings(), notificationManager: NotificationManager = NotificationManager()) {
        self.settings = settings
        self.notificationManager = notificationManager
        self.settingsWindowController = SettingsWindowController(settings: settings)
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        notificationManager.requestAuthorization()
        SoundPlayer.prepare()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🔔"
        statusItem.button?.toolTip = "Hourly Chime"

        settings.load()
        rebuildMenu()
        startChimeTimer()
        startMenuUpdateTimer()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        NSApp.setActivationPolicy(.accessory)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        chimeTimer?.cancel()
        chimeTimer = nil
        menuUpdateTimer?.invalidate()
        menuUpdateTimer = nil
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        SoundPlayer.cleanup()
    }

    private func rebuildMenu() {
        statusItem.menu = AppMenuBuilder.makeMenu(
            target: self,
            now: Date(),
            settings: settings,
            muteUntil: muteUntil,
            pomodoroSession: pomodoroSession,
            launchAtLoginEnabled: isLaunchAtLoginEnabled()
        )
    }

    @objc func muteForHour() {
        muteUntil = Date().addingTimeInterval(3600)
        rebuildMenu()
    }

    @objc func unmute() {
        muteUntil = nil
        rebuildMenu()
    }

    @objc func startPomodoro() {
        pomodoroSession.startWork()
        updateMenuBarTitle()
        startPomodoroTimer()
        rebuildMenu()
    }

    @objc func stopPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroSession.stop()
        updateMenuBarTitle()
        rebuildMenu()
    }

    @objc func skipBreak() {
        pomodoroTimer?.invalidate()
        pomodoroSession.skipBreak()
        updateMenuBarTitle()
        startPomodoroTimer()
        rebuildMenu()
    }

    private func startPomodoroTimer() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickPomodoro()
        }
    }

    private func tickPomodoro() {
        if let transition = pomodoroSession.tick(now: Date()) {
            pomodoroTimer?.invalidate()
            handlePomodoroTransition(transition)
        } else {
            updateMenuBarTitle()
        }
    }

    private func handlePomodoroTransition(_ transition: PomodoroTransition) {
        SoundPlayer.playPomodoro()

        switch transition {
        case .startedShortBreak:
            notificationManager.showPomodoro(message: "Work done. Take a short break.")
        case .startedLongBreak:
            notificationManager.showPomodoro(message: "Work done. Take a long break.")
        case .startedWork:
            notificationManager.showPomodoro(message: "Break over. Time to focus.")
        }

        startPomodoroTimer()
        updateMenuBarTitle()
        rebuildMenu()
    }

    private func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }

        if pomodoroSession.isActive {
            let mins = pomodoroSession.secondsLeft / 60
            let secs = pomodoroSession.secondsLeft % 60
            button.title = String(format: "%@ %d:%02d", pomodoroSession.menuEmoji, mins, secs)
        } else {
            button.title = "🔔"
        }
    }

    private func isLaunchAtLoginEnabled() -> Bool {
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
            NSLog("Failed to toggle launch at login: %@", String(describing: error))
        }

        rebuildMenu()
    }

    @objc func toggleChime() {
        settings.enabled.toggle()
        settings.save()
        rebuildMenu()
    }

    @objc func openSettings() {
        settingsWindowController.show()
    }

    @objc func testSound() {
        SoundPlayer.playChime()
        notificationManager.showChime(hour: Calendar.current.component(.hour, from: Date()))
    }

    private func startChimeTimer() {
        chimeTimer?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        let now = Date()
        let calendar = Calendar.current
        let nextMinute = calendar.date(byAdding: .minute, value: 1, to: now).flatMap {
            calendar.date(bySetting: .second, value: 0, of: $0)
        } ?? now.addingTimeInterval(60)
        let delay = max(0, nextMinute.timeIntervalSince(now))

        timer.schedule(deadline: .now() + delay, repeating: .seconds(30))
        timer.setEventHandler { [weak self] in
            self?.checkAndPlayChime()
        }
        timer.resume()
        chimeTimer = timer

        checkAndPlayChime()
    }

    private func startMenuUpdateTimer() {
        menuUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.rebuildMenu()
        }
    }

    private func checkAndPlayChime() {
        let now = Date()

        guard settings.enabled else { return }
        if let muteUntil = muteUntil, muteUntil > now {
            return
        }
        guard ChimeSchedule.shouldChime(now: now, settings: settings) else { return }

        let key = ChimeSchedule.chimeKey(for: now)
        guard lastPlayedChimeKey != key else { return }

        lastPlayedChimeKey = key
        SoundPlayer.playChime()
        notificationManager.showChime(hour: Calendar.current.component(.hour, from: now))
        rebuildMenu()
    }

    @objc private func handleWake() {
        if let transition = pomodoroSession.resync(now: Date()) {
            handlePomodoroTransition(transition)
        } else {
            updateMenuBarTitle()
            rebuildMenu()
        }

        startChimeTimer()
        checkAndPlayChime()
    }
}
