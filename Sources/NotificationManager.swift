import Foundation
import UserNotifications

public final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    public init() {}

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func showChime(hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔔 Hourly Chime"
        content.body = "It's \(formatHour(hour))"
        content.sound = .default
        post(content, identifier: "hourly-chime-\(Date().timeIntervalSince1970)")
    }

    func showPomodoro(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "🍅 Pomodoro"
        content.body = message
        content.sound = .default
        post(content, identifier: "pomodoro-\(Date().timeIntervalSince1970)")
    }

    private func post(_ content: UNNotificationContent, identifier: String) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        center.add(request)
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}
