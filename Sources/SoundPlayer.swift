import AVFoundation
import Foundation

enum SoundPlayer {
    private static let lock = NSLock()
    private static var chimeSoundID: SystemSoundID = 0
    private static var pomodoroSoundID: SystemSoundID = 0
    private static var endOfDaySoundID: SystemSoundID = 0

    static func prepare() {
        _ = cachedSoundID(named: "Hero", storage: &chimeSoundID)
        _ = cachedSoundID(named: "Ping", storage: &pomodoroSoundID)
        _ = cachedSoundID(named: "Glass", storage: &endOfDaySoundID)
    }

    static func cleanup() {
        lock.lock()
        defer { lock.unlock() }

        if chimeSoundID != 0 {
            AudioServicesDisposeSystemSoundID(chimeSoundID)
            chimeSoundID = 0
        }

        if pomodoroSoundID != 0 {
            AudioServicesDisposeSystemSoundID(pomodoroSoundID)
            pomodoroSoundID = 0
        }

        if endOfDaySoundID != 0 {
            AudioServicesDisposeSystemSoundID(endOfDaySoundID)
            endOfDaySoundID = 0
        }
    }

    static func playChime() {
        AudioServicesPlaySystemSound(cachedSoundID(named: "Hero", storage: &chimeSoundID))
    }

    static func playPomodoro() {
        AudioServicesPlaySystemSound(cachedSoundID(named: "Ping", storage: &pomodoroSoundID))
    }

    static func playEndOfDay() {
        AudioServicesPlaySystemSound(cachedSoundID(named: "Glass", storage: &endOfDaySoundID))
    }

    private static func cachedSoundID(named name: String, storage: inout SystemSoundID) -> SystemSoundID {
        lock.lock()
        defer { lock.unlock() }

        if storage == 0 {
            let soundPath = "/System/Library/Sounds/\(name).aiff"
            let url = URL(fileURLWithPath: soundPath)
            AudioServicesCreateSystemSoundID(url as CFURL, &storage)
        }

        return storage
    }
}
