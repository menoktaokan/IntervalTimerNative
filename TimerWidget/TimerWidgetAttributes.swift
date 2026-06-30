import ActivityKit
import Foundation

// MARK: - TimerWidgetAttributes
// Live Activity'nin veri modeli.
// import Foundation gerekli çünkü TimeInterval ve Date bu framework'te tanımlı.

struct TimerWidgetAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var segmentLabel: String
        var currentIndex: Int
        var totalCount: Int
        var endTimeInterval: TimeInterval   // Date yerine TimeInterval (Double)
        var isPaused: Bool
        var isCompleted: Bool

        // TimeInterval'dan Date'e dönüşüm (widget UI'da kullanmak için)
        var endTime: Date {
            Date(timeIntervalSince1970: endTimeInterval)
        }
    }

    var collectionTitle: String
}
