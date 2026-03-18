import Foundation

public enum ChimeSchedule {
    public static func shouldChime(now: Date, settings: ChimeSettings, calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        guard let weekday = components.weekday,
              let hour = components.hour,
              let minute = components.minute else {
            return false
        }

        let dayIndex = (weekday + 5) % 7
        guard dayIndex >= 0, dayIndex < settings.enabledDays.count, settings.enabledDays[dayIndex] else {
            return false
        }

        guard hour >= settings.startHour, hour < settings.endHour else {
            return false
        }

        guard settings.frequencyMinutes > 0 else {
            return false
        }

        let minutesSinceMidnight = hour * 60 + minute
        return minutesSinceMidnight % settings.frequencyMinutes == 0
    }

    public static func nextChimeText(now: Date, settings: ChimeSettings, calendar: Calendar = .current) -> String {
        guard settings.enabled else { return "Next: Disabled" }

        if let next = nextMatchingDate(after: now, settings: settings, calendar: calendar) {
            let label = TimeFormatter.timeOfDayFormatter.string(from: next)
            if calendar.isDate(next, inSameDayAs: now) {
                return "Next: \(label)"
            }

            return "Next: Tomorrow \(label)"
        }

        return "Next: None"
    }

    public static func workdayRemainingText(now: Date, settings: ChimeSettings, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        if hour >= settings.endHour {
            return "Work day ended"
        }

        let remainingMinutes = settings.endHour * 60 - (hour * 60 + minute)
        let hoursLeft = remainingMinutes / 60
        let minsLeft = remainingMinutes % 60
        let endLabel = TimeFormatter.workdayEndFormatter.string(from: endDate(for: now, endHour: settings.endHour, calendar: calendar))

        if hoursLeft == 0 {
            return "\(minsLeft) min until \(endLabel)"
        }

        if minsLeft == 0 {
            return "\(hoursLeft) hr\(hoursLeft == 1 ? "" : "s") until \(endLabel)"
        }

        return "\(hoursLeft)h \(minsLeft)m until \(endLabel)"
    }

    public static func chimeKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%04d-%02d-%02d-%02d-%02d", year, month, day, hour, minute)
    }

    private static func nextMatchingDate(after now: Date, settings: ChimeSettings, calendar: Calendar) -> Date? {
        guard settings.frequencyMinutes > 0 else { return nil }

        let start = calendar.date(byAdding: .minute, value: 0, to: now) ?? now
        let searchStart = calendar.date(bySetting: .second, value: 0, of: start) ?? start

        for offset in 0..<(7 * 24 * 60) {
            guard let candidate = calendar.date(byAdding: .minute, value: offset, to: searchStart) else {
                continue
            }

            guard shouldChime(now: candidate, settings: settings, calendar: calendar) else {
                continue
            }

            return candidate
        }

        return nil
    }

    private static func endDate(for date: Date, endHour: Int, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: startOfDay) ?? date
    }
}
