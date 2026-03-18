import Cocoa

enum AppMenuBuilder {
    static func makeMenu(
        target: AnyObject,
        now: Date,
        settings: ChimeSettings,
        muteUntil: Date?,
        pomodoroSession: PomodoroSessionManager,
        launchAtLoginEnabled: Bool
    ) -> NSMenu {
        let menu = NSMenu()

        menu.addItem(disabledItem(title: ChimeSchedule.nextChimeText(now: now, settings: settings)))
        menu.addItem(disabledItem(title: ChimeSchedule.workdayRemainingText(now: now, settings: settings)))
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: settings.enabled ? "✓ Enabled" : "Disabled", action: #selector(AppDelegate.toggleChime), keyEquivalent: ""))

        if let muteUntil, muteUntil > now {
            let formatter = TimeFormatter.timeOfDayFormatter
            menu.addItem(NSMenuItem(title: "Muted until \(formatter.string(from: muteUntil))", action: #selector(AppDelegate.unmute), keyEquivalent: ""))
        } else {
            menu.addItem(NSMenuItem(title: "Mute for 1 hour", action: #selector(AppDelegate.muteForHour), keyEquivalent: "m"))
        }

        menu.addItem(.separator())
        menu.addItem(disabledItem(title: "🍅 Pomodoro"))

        if !pomodoroSession.isActive {
            menu.addItem(NSMenuItem(title: "Start Work (25 min)", action: #selector(AppDelegate.startPomodoro), keyEquivalent: "p"))
        } else {
            menu.addItem(disabledItem(title: "\(pomodoroSession.stateLabel) - \(formatTime(pomodoroSession.secondsLeft))"))
            menu.addItem(NSMenuItem(title: "Stop Pomodoro", action: #selector(AppDelegate.stopPomodoro), keyEquivalent: ""))

            if pomodoroSession.state == .shortBreak || pomodoroSession.state == .longBreak {
                menu.addItem(NSMenuItem(title: "Skip Break", action: #selector(AppDelegate.skipBreak), keyEquivalent: ""))
            }
        }

        menu.addItem(disabledItem(title: "Sessions: \(pomodoroSession.completedWorkSessions)/\(PomodoroSessionManager.sessionsPerCycle)"))
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(AppDelegate.openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Test Sound", action: #selector(AppDelegate.testSound), keyEquivalent: "t"))

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: launchAtLoginEnabled ? "✓ Launch at Login" : "Launch at Login", action: #selector(AppDelegate.toggleLaunchAtLogin), keyEquivalent: ""))

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.items.forEach { $0.target = target }
        return menu
    }

    private static func disabledItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private static func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
