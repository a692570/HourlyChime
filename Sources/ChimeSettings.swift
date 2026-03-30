import Foundation
import Combine

public final class ChimeSettings: ObservableObject {
    @Published public var enabled = true
    @Published public var enabledDays: [Bool] = Array(repeating: true, count: 7)
    @Published public var startHour = 9
    @Published public var endHour = 18
    @Published public var frequencyMinutes = 60
    @Published public var muteWhenFocused = false

    private let defaults = UserDefaults.standard

    public init() {}

    public func save() {
        defaults.set(enabled, forKey: Keys.enabled)
        defaults.set(enabledDays, forKey: Keys.enabledDays)
        defaults.set(startHour, forKey: Keys.startHour)
        defaults.set(endHour, forKey: Keys.endHour)
        defaults.set(frequencyMinutes, forKey: Keys.frequencyMinutes)
        defaults.set(muteWhenFocused, forKey: Keys.muteWhenFocused)
    }

    public func load() {
        enabled = defaults.object(forKey: Keys.enabled) as? Bool ?? true

        if let days = defaults.array(forKey: Keys.enabledDays) as? [Bool], days.count == 7 {
            enabledDays = days
        }

        startHour = defaults.object(forKey: Keys.startHour) as? Int ?? 9
        endHour = defaults.object(forKey: Keys.endHour) as? Int ?? 18
        frequencyMinutes = defaults.object(forKey: Keys.frequencyMinutes) as? Int ?? 60
        muteWhenFocused = defaults.object(forKey: Keys.muteWhenFocused) as? Bool ?? false
    }
}

private enum Keys {
    static let enabled = "enabled"
    static let enabledDays = "enabledDays"
    static let startHour = "startHour"
    static let endHour = "endHour"
    static let frequencyMinutes = "frequencyMinutes"
    static let muteWhenFocused = "muteWhenFocused"
}
