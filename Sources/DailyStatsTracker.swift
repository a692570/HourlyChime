import Foundation

/// Tracks per-day pomodoro counts and work start time for the daily stats summary.
/// All data is keyed by "yyyy-MM-dd" strings in UserDefaults.
public final class DailyStatsTracker {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let pomodoroCountPrefix = "dailyPomodoros_"
        static let workStartPrefix = "dailyWorkStart_"
    }

    public init() {}

    // MARK: - Pomodoro count

    public func pomodoroCount(for date: Date, calendar: Calendar = .current) -> Int {
        defaults.integer(forKey: pomodoroKey(for: date, calendar: calendar))
    }

    public func incrementPomodoro(for date: Date, calendar: Calendar = .current) {
        let key = pomodoroKey(for: date, calendar: calendar)
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    // MARK: - Work start time (first chime of the day)

    /// Records the work-start timestamp for the day, but only the first time it's called each day.
    public func recordWorkStartIfNeeded(now: Date, calendar: Calendar = .current) {
        let key = workStartKey(for: now, calendar: calendar)
        guard defaults.object(forKey: key) == nil else { return }
        defaults.set(now, forKey: key)
    }

    /// Returns the elapsed work hours since work started today (or 0 if not started).
    public func workedHours(now: Date, calendar: Calendar = .current) -> Double {
        let key = workStartKey(for: now, calendar: calendar)
        guard let startDate = defaults.object(forKey: key) as? Date else { return 0 }
        return now.timeIntervalSince(startDate) / 3600.0
    }

    // MARK: - Summary

    /// Returns a human-readable daily stats string.
    public func summaryString(now: Date, calendar: Calendar = .current) -> String {
        let pomodoros = pomodoroCount(for: now, calendar: calendar)
        let hours = workedHours(now: now, calendar: calendar)

        let hoursFormatted: String
        if hours < 0.1 {
            hoursFormatted = "0 hrs"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            if h == 0 {
                hoursFormatted = "\(m) min"
            } else if m == 0 {
                hoursFormatted = "\(h) hr\(h == 1 ? "" : "s")"
            } else {
                hoursFormatted = "\(h)h \(m)m"
            }
        }

        return "\(pomodoros) pomodoro\(pomodoros == 1 ? "" : "s") completed, \(hoursFormatted) worked"
    }

    // MARK: - Private helpers

    private func pomodoroKey(for date: Date, calendar: Calendar) -> String {
        Keys.pomodoroCountPrefix + dateString(for: date, calendar: calendar)
    }

    private func workStartKey(for date: Date, calendar: Calendar) -> String {
        Keys.workStartPrefix + dateString(for: date, calendar: calendar)
    }

    private func dateString(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
