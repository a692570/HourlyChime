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

    // Feature: end-of-day signal
    private let endOfDayManager = EndOfDayManager()

    // Feature: bedtime nudge at 12:20 AM
    private let bedtimeNudgeManager = BedtimeNudgeManager()

    // Feature: daily stats tracking
    private let dailyStats = DailyStatsTracker()

    // Feature: Focus mode auto-mute
    private let focusMonitor = FocusStateMonitor()
    // Cached pomodoro count for menu bar title (persisted across ticks)
    private var totalDailyPomodoros: Int = 0

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

        // Seed today's pomodoro count from persistent storage
        totalDailyPomodoros = dailyStats.pomodoroCount(for: Date())

        rebuildMenu()
        startChimeTimer()
        startMenuUpdateTimer()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Feature: Focus mode — start observing distributed notifications
        focusMonitor.onFocusStateChanged = { [weak self] in
            self?.rebuildMenu()
        }
        focusMonitor.startObserving()

        // Feature: bedtime nudge
        bedtimeNudgeManager.onNudge = { [weak self] in
            SoundPlayer.playBedtime()
            self?.notificationManager.showBedtime()
        }
        bedtimeNudgeManager.start()

        NSApp.setActivationPolicy(.accessory)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        // Feature: daily stats — show summary when user quits
        fireDailyStatsSummaryIfNeeded(now: Date())

        bedtimeNudgeManager.stop()
        chimeTimer?.cancel()
        chimeTimer = nil
        menuUpdateTimer?.invalidate()
        menuUpdateTimer = nil
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        focusMonitor.stopObserving()
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
            launchAtLoginEnabled: isLaunchAtLoginEnabled(),
            dailyStats: dailyStats
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
            // A work session just finished — record it in daily stats
            dailyStats.incrementPomodoro(for: Date())
            totalDailyPomodoros = dailyStats.pomodoroCount(for: Date())
            notificationManager.showPomodoro(message: "Work done. Take a short break.")
        case .startedLongBreak:
            // A work session just finished — record it in daily stats
            dailyStats.incrementPomodoro(for: Date())
            totalDailyPomodoros = dailyStats.pomodoroCount(for: Date())
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
            // Feature 2: show completed count alongside the timer when a session is active
            let countSuffix = totalDailyPomodoros > 0 ? " (\(totalDailyPomodoros))" : ""
            button.title = String(format: "%@ %d:%02d%@", pomodoroSession.menuEmoji, mins, secs, countSuffix)
        } else if totalDailyPomodoros > 0 {
            // Feature 2: show completed count in the bell title when idle but some pomodoros done today
            button.title = "🔔 🍅\(totalDailyPomodoros)"
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

    @objc func toggleMuteWhenFocused() {
        settings.muteWhenFocused.toggle()
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

        // Feature 3: Focus mode auto-mute — skip chime when focused and toggle is on
        if settings.muteWhenFocused && focusMonitor.isFocusActive {
            checkEndOfDay(now: now)
            return
        }

        if let muteUntil = muteUntil, muteUntil > now {
            checkEndOfDay(now: now)
            return
        }

        // Feature 1 + 4: check end-of-day regardless of whether we chime
        checkEndOfDay(now: now)

        guard ChimeSchedule.shouldChime(now: now, settings: settings) else { return }

        let key = ChimeSchedule.chimeKey(for: now)
        guard lastPlayedChimeKey != key else { return }

        lastPlayedChimeKey = key

        // Feature 4: record work start on first chime of the day
        dailyStats.recordWorkStartIfNeeded(now: now)

        SoundPlayer.playChime()
        notificationManager.showChime(hour: Calendar.current.component(.hour, from: now))
        rebuildMenu()
    }

    /// Feature 1: fire end-of-day sound + notification once per calendar day.
    /// Also fires the daily stats summary (Feature 4).
    private func checkEndOfDay(now: Date) {
        guard endOfDayManager.shouldFireEndOfDay(now: now, settings: settings) else { return }
        endOfDayManager.markFired(now: now)
        SoundPlayer.playEndOfDay()
        notificationManager.showEndOfDay()
        fireDailyStatsSummaryIfNeeded(now: now)
    }

    /// Feature 4: fire the daily stats summary notification.
    private func fireDailyStatsSummaryIfNeeded(now: Date) {
        let summary = dailyStats.summaryString(now: now)
        // Only show if there is something to report (worked at least a bit)
        guard dailyStats.workedHours(now: now) > 0 || dailyStats.pomodoroCount(for: now) > 0 else { return }
        notificationManager.showDailyStats(summary: summary)
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
