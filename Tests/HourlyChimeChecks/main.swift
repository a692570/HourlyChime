import Foundation
import HourlyChimeCore

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

@main
struct Checks {
    static func main() throws {
        try testShouldChimeDuringActiveWindowOnEnabledDay()
        try testShouldNotChimeBeforeStartHour()
        try testNextChimeTextMentionsTomorrowAfterHours()
        print("HourlyChime checks passed")
    }

    private static func testShouldChimeDuringActiveWindowOnEnabledDay() throws {
        let calendar = utcCalendar()
        let settings = makeSettings()
        let date = makeDate(calendar: calendar, year: 2026, month: 3, day: 16, hour: 9, minute: 0)

        guard ChimeSchedule.shouldChime(now: date, settings: settings, calendar: calendar) else {
            throw CheckFailure.failed("expected chime at 9:00 on enabled Monday")
        }
    }

    private static func testShouldNotChimeBeforeStartHour() throws {
        let calendar = utcCalendar()
        let settings = makeSettings()
        let date = makeDate(calendar: calendar, year: 2026, month: 3, day: 16, hour: 8, minute: 0)

        guard !ChimeSchedule.shouldChime(now: date, settings: settings, calendar: calendar) else {
            throw CheckFailure.failed("expected no chime before start hour")
        }
    }

    private static func testNextChimeTextMentionsTomorrowAfterHours() throws {
        let calendar = utcCalendar()
        let settings = makeSettings()
        let date = makeDate(calendar: calendar, year: 2026, month: 3, day: 16, hour: 18, minute: 30)

        let text = ChimeSchedule.nextChimeText(now: date, settings: settings, calendar: calendar)
        guard text.contains("Tomorrow") else {
            throw CheckFailure.failed("expected tomorrow label, got: \(text)")
        }
    }

    private static func makeSettings() -> ChimeSettings {
        let settings = ChimeSettings()
        settings.enabled = true
        settings.enabledDays = [true, false, false, false, false, false, false]
        settings.startHour = 9
        settings.endHour = 18
        settings.frequencyMinutes = 60
        return settings
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func makeDate(calendar: Calendar, year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = calendar.timeZone

        return calendar.date(from: components)!
    }
}
