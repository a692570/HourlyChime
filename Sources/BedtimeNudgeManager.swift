import Foundation

/// Fires a bedtime nudge at 12:20 AM every night.
/// Uses a UserDefaults key (date string) to fire at most once per night.
/// Scheduling is done via a single DispatchQueue.main.asyncAfter that re-arms itself after firing.
public final class BedtimeNudgeManager {
    private let defaults = UserDefaults.standard
    private var pendingWorkItem: DispatchWorkItem?

    private enum Keys {
        static let lastBedtimeNudgeDate = "lastBedtimeNudgeDate"
    }

    // Target: 12:20 AM
    private let targetHour = 0
    private let targetMinute = 20

    public var onNudge: (() -> Void)?

    public init() {}

    /// Start the scheduling loop. Call once from AppDelegate.
    public func start() {
        scheduleNext()
    }

    public func stop() {
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
    }

    private func scheduleNext() {
        let delay = secondsUntilNextTarget()
        let item = DispatchWorkItem { [weak self] in
            self?.fire()
        }
        pendingWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func fire() {
        let now = Date()
        let calendar = Calendar.current

        // Guard: only fire once per calendar night (keyed by the day we just crossed into)
        let todayKey = dateKey(for: now, calendar: calendar)
        if let lastKey = defaults.string(forKey: Keys.lastBedtimeNudgeDate), lastKey == todayKey {
            // Already fired tonight — reschedule for tomorrow
            scheduleNext()
            return
        }

        defaults.set(todayKey, forKey: Keys.lastBedtimeNudgeDate)
        onNudge?()

        // Re-arm for the next night
        scheduleNext()
    }

    /// Seconds until the next 12:20 AM.
    func secondsUntilNextTarget() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()

        // Build a Date for today at targetHour:targetMinute:00
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = targetHour
        components.minute = targetMinute
        components.second = 0

        guard var candidate = calendar.date(from: components) else {
            // Fallback: 24 hours
            return 86400
        }

        // If that time is in the past (or within 5 seconds), advance to tomorrow
        if candidate.timeIntervalSince(now) <= 5 {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        return max(1, candidate.timeIntervalSince(now))
    }

    private func dateKey(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let year = c.year ?? 0
        let month = c.month ?? 0
        let day = c.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
