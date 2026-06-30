import ActivityKit
import Foundation

// MARK: - TimerWidgetAttributes
// Live Activity'nin veri modeli.
// ÖNEMLİ: ContentState içindeki tüm tipler Codable + Hashable olmalı.
// Date tipi Swift 6'da otomatik Codable/Hashable sentezlemiyor,
// bu yüzden bitiş zamanını TimeInterval (Double) olarak saklıyoruz.

struct TimerWidgetAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var segmentLabel: String
        var currentIndex: Int
        var totalCount: Int
        var endTimeInterval: TimeInterval   // Date yerine TimeInterval (saniye, epoch'tan)
        var isPaused: Bool
        var isCompleted: Bool

        // TimeInterval'dan Date'e dönüşüm (widget UI'da kullanmak için)
        var endTime: Date {
            Date(timeIntervalSince1970: endTimeInterval)
        }
    }

    var collectionTitle: String
}
