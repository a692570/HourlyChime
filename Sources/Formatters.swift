import Foundation

enum TimeFormatter {
    static let timeOfDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let workdayEndFormatter = timeOfDayFormatter
}
