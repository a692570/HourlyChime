import Foundation
import Combine

public final class SettingsViewModel: ObservableObject {
    @Published public var enabled: Bool
    @Published public var enabledDays: [Bool]
    @Published public var startHour: Int
    @Published public var endHour: Int
    @Published public var frequencyMinutes: Int

    public init(settings: ChimeSettings) {
        enabled = settings.enabled
        enabledDays = settings.enabledDays
        startHour = settings.startHour
        endHour = settings.endHour
        frequencyMinutes = settings.frequencyMinutes
    }

    public func save(to settings: ChimeSettings) {
        settings.enabled = enabled
        settings.enabledDays = enabledDays
        settings.startHour = startHour
        settings.endHour = endHour
        settings.frequencyMinutes = frequencyMinutes
        settings.save()
    }
}
