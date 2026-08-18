import Foundation
import Observation
import WatchKit

@Observable
class WatchTimerEngine {
    var status: Status = .idle
    var currentIndex: Int = -1
    var remaining: TimeInterval = 0
    var timers: [WatchTimerItem] = []

    enum Status: String {
        case idle, running, paused, completed
    }

    private var timer: Timer?
    private var endTime: Date = .distantPast
    private var remainingAtPause: TimeInterval = 0

    var currentTimer: WatchTimerItem? {
        guard currentIndex >= 0, currentIndex < timers.count else { return nil }
        return timers[currentIndex]
    }

    var totalCount: Int { timers.count }

    var remainingFormatted: String {
        let whole = Int(ceil(remaining))
        let m = whole / 60
        let s = whole % 60
        return String(format: "%02d:%02d", m, s)
    }

    var progress: Double {
        guard let t = currentTimer else { return 0 }
        let duration = Double(t.duration)
        guard duration > 0 else { return 0 }
        return 1.0 - (remaining / duration)
    }

    func start() {
        guard !timers.isEmpty else { return }
        startSegment(at: 0)
    }

    func pause() {
        remainingAtPause = endTime.timeIntervalSinceNow
        stopTicking()
        status = .paused
    }

    func resume() {
        endTime = Date().addingTimeInterval(remainingAtPause)
        status = .running
        beginTicking()
    }

    func reset() {
        stopTicking()
        currentIndex = -1
        remaining = 0
        status = .idle
    }

    func skip() {
        if currentIndex >= timers.count - 1 {
            finishAll()
        } else {
            startSegment(at: currentIndex + 1)
        }
    }

    private func startSegment(at index: Int) {
        currentIndex = index
        let duration = timers[index].duration
        remaining = TimeInterval(duration)
        endTime = Date().addingTimeInterval(TimeInterval(duration))
        status = .running
        WKInterfaceDevice.current().play(.start)
        beginTicking()
    }

    private func beginTicking() {
        stopTicking()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        let left = endTime.timeIntervalSinceNow
        remaining = max(0, left)

        if left <= 0 {
            if currentIndex >= timers.count - 1 {
                finishAll()
            } else {
                WKInterfaceDevice.current().play(.notification)
                startSegment(at: currentIndex + 1)
            }
        } else if Int(ceil(remaining)) <= 3 && status == .running {
            WKInterfaceDevice.current().play(.click)
        }
    }

    private func finishAll() {
        stopTicking()
        currentIndex = -1
        remaining = 0
        status = .completed
        WKInterfaceDevice.current().play(.success)
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }
}
