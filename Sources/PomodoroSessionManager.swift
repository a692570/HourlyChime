import Foundation

enum PomodoroState {
    case idle
    case work
    case shortBreak
    case longBreak
}

enum PomodoroTransition {
    case startedShortBreak
    case startedLongBreak
    case startedWork
}

final class PomodoroSessionManager {
    static let workDuration = 25 * 60
    static let shortBreakDuration = 5 * 60
    static let longBreakDuration = 15 * 60
    static let sessionsPerCycle = 4

    private(set) var state: PomodoroState = .idle
    private(set) var completedWorkSessions = 0
    private var endTime: Date?

    var isActive: Bool {
        state != .idle
    }

    var secondsLeft: Int {
        remainingSeconds(now: Date())
    }

    var menuEmoji: String {
        switch state {
        case .work:
            return "🍅"
        case .shortBreak, .longBreak:
            return "☕"
        case .idle:
            return "🔔"
        }
    }

    var stateLabel: String {
        switch state {
        case .work:
            return "Working"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        case .idle:
            return ""
        }
    }

    func startWork(now: Date = Date()) {
        state = .work
        endTime = now.addingTimeInterval(TimeInterval(Self.workDuration))
    }

    func stop() {
        state = .idle
        endTime = nil
    }

    func skipBreak(now: Date = Date()) {
        startWork(now: now)
    }

    func tick(now: Date = Date()) -> PomodoroTransition? {
        guard state != .idle, let endTime else { return nil }
        guard now >= endTime else { return nil }
        return advanceAfterCompletion(now: now)
    }

    func resync(now: Date = Date()) -> PomodoroTransition? {
        tick(now: now)
    }

    private func remainingSeconds(now: Date) -> Int {
        guard state != .idle, let endTime else { return 0 }
        return max(0, Int(ceil(endTime.timeIntervalSince(now))))
    }

    private func advanceAfterCompletion(now: Date) -> PomodoroTransition? {
        switch state {
        case .work:
            completedWorkSessions += 1
            if completedWorkSessions >= Self.sessionsPerCycle {
                state = .longBreak
                endTime = now.addingTimeInterval(TimeInterval(Self.longBreakDuration))
                completedWorkSessions = 0
                return .startedLongBreak
            } else {
                state = .shortBreak
                endTime = now.addingTimeInterval(TimeInterval(Self.shortBreakDuration))
                return .startedShortBreak
            }
        case .shortBreak, .longBreak:
            state = .work
            endTime = now.addingTimeInterval(TimeInterval(Self.workDuration))
            return .startedWork
        case .idle:
            return nil
        }
    }
}
