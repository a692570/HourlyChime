import Foundation

/// Tracks whether the end-of-day signal has already fired today
/// and provides the logic to determine when it should fire.
public final class EndOfDayManager {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let lastEndOfDayDate = "lastEndOfDayDate"
    }

    public init() {}

    /// Returns true if the end-of-day signal should fire right now.
    /// `now` has just crossed (or is past) `endHour` on a workday.
    public func shouldFireEndOfDay(now: Date, settings: ChimeSettings, calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.weekday, .hour], from: now)
        guard let weekday = components.weekday, let hour = components.hour else { return false }

        // Only fire when we've reached or passed the end hour
        guard hour >= settings.endHour else { return false }

        // Only fire on enabled workdays
        let dayIndex = (weekday + 5) % 7
        guard dayIndex >= 0, dayIndex < settings.enabledDays.count, settings.enabledDays[dayIndex] else {
            return false
        }

        // Fire at most once per calendar day
        let todayKey = dateKey(for: now, calendar: calendar)
        if let lastFiredKey = defaults.string(forKey: Keys.lastEndOfDayDate), lastFiredKey == todayKey {
            return false
        }

        return true
    }

    /// Mark end-of-day as fired for today so it won't repeat.
    public func markFired(now: Date, calendar: Calendar = .current) {
        defaults.set(dateKey(for: now, calendar: calendar), forKey: Keys.lastEndOfDayDate)
    }

    private func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
