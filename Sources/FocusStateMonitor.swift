import Foundation

/// Monitors macOS Focus mode state using DistributedNotificationCenter.
/// On macOS 12+ the system posts "com.apple.focus.status.changed" (and the
/// older "com.apple.springboard.focus-state-changed") when Focus turns on/off.
/// We also fall back to reading CFPreferences for the current state on demand.
public final class FocusStateMonitor {
    /// Callback invoked (on main queue) whenever focus state may have changed.
    public var onFocusStateChanged: (() -> Void)?

    private let notificationNames: [String] = [
        "com.apple.focus.status.changed",
        "com.apple.springboard.focus-state-changed",
        "com.apple.notificationcenterui.dndprefs_changed"
    ]

    public init() {}

    public func startObserving() {
        let center = DistributedNotificationCenter.default()
        for name in notificationNames {
            center.addObserver(
                self,
                selector: #selector(focusStateDidChange),
                name: NSNotification.Name(name),
                object: nil,
                suspensionBehavior: .deliverImmediately
            )
        }
    }

    public func stopObserving() {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    /// Best-effort synchronous check: reads the `dndSuppressNotifications` key
    /// from the `com.apple.ncprefs` preferences domain using CFPreferences.
    /// Returns true when any Focus / DND is active.
    public var isFocusActive: Bool {
        CFPreferencesSynchronize(
            "com.apple.ncprefs" as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        let value = CFPreferencesCopyAppValue(
            "dndSuppressNotifications" as CFString,
            "com.apple.ncprefs" as CFString
        )
        if let boolValue = value as? Bool {
            return boolValue
        }
        if let numberValue = value as? NSNumber {
            return numberValue.boolValue
        }
        return false
    }

    @objc private func focusStateDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.onFocusStateChanged?()
        }
    }
}
