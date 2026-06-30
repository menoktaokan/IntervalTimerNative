import ActivityKit
import Foundation

// MARK: - LiveActivityManager
// Live Activity'yi başlatma, güncelleme ve sonlandırma işlemlerini yönetir.
//
// ActivityKit: Apple'ın Live Activity framework'ü.
// - Activity.request(): Yeni bir Live Activity başlatır
// - activity.update(): Mevcut Activity'nin durumunu günceller
// - activity.end(): Activity'yi sonlandırır
//
// Önemli: TimerWidgetAttributes widget tarafında tanımlandı.
// Ana uygulama da bu struct'ı kullanabilmesi için dosyanın
// ana uygulamanın target'ına da eklenmesi gerekir.

class LiveActivityManager {

    static let shared = LiveActivityManager()

    // Şu anda aktif olan Live Activity referansı
    // Bu referansı saklıyoruz ki update ve end çağrılarında kullanabilelim
    private var currentActivity: Activity<TimerWidgetAttributes>?

    private init() {}

    // MARK: - Live Activity Başlat
    // Timer başladığında çağrılır. Kilit ekranında ve Dynamic Island'da görünür.

    func start(collectionTitle: String, segmentLabel: String, index: Int, total: Int, duration: Int) {
        // Önce aktif bir Activity varsa sonlandır (çift başlatma olmasın)
        stop()

        // Sabit özellikler (Activity boyunca değişmez)
        let attributes = TimerWidgetAttributes(collectionTitle: collectionTitle)

        // Değişen durum — ilk segment bilgileri
        let state = TimerWidgetAttributes.ContentState(
            segmentLabel: segmentLabel,
            currentIndex: index,
            totalCount: total,
            endTimeInterval: Date().addingTimeInterval(TimeInterval(duration)).timeIntervalSince1970,
            isPaused: false,
            isCompleted: false
        )

        do {
            // Activity.request(): iOS'a "Bir Live Activity başlat" der
            // content: ActivityContent ile durum ve staleDate (ne zaman eskiyeceği)
            let activity = try Activity<TimerWidgetAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil)
            )
            currentActivity = activity
            print("✅ Live Activity başlatıldı: \(activity.id)")
        } catch {
            print("❌ Live Activity başlatılamadı: \(error)")
        }
    }

    // MARK: - Live Activity Güncelle
    // Yeni segmente geçildiğinde veya pause/resume yapıldığında çağrılır.

    func update(segmentLabel: String, index: Int, total: Int, duration: Int, isPaused: Bool) {
        guard let activity = currentActivity else { return }

        let state = TimerWidgetAttributes.ContentState(
            segmentLabel: segmentLabel,
            currentIndex: index,
            totalCount: total,
            endTimeInterval: Date().addingTimeInterval(TimeInterval(duration)).timeIntervalSince1970,
            isPaused: isPaused,
            isCompleted: false
        )

        Task {
            // activity.update(): Mevcut Activity'nin durumunu günceller
            // Kilit ekranı ve Dynamic Island anında yeni bilgiyi gösterir
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    // MARK: - Tamamlandı Olarak İşaretle
    // Tüm zamanlayıcılar bittiğinde çağrılır.
    // Activity hemen silinmez, "tamamlandı" olarak gösterilir.

    func complete(total: Int) {
        guard let activity = currentActivity else { return }

        let state = TimerWidgetAttributes.ContentState(
            segmentLabel: "Tamamlandı",
            currentIndex: total,
            totalCount: total,
            endTimeInterval: Date().timeIntervalSince1970,
            isPaused: false,
            isCompleted: true
        )

        Task {
            // .end(): Activity'yi sonlandırır
            // dismissalPolicy: .after(Date) → belirtilen zamanda kilit ekranından kaldırılır
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .after(Date().addingTimeInterval(60))   // 1 dk sonra kaldır
            )
            currentActivity = nil
        }
    }

    // MARK: - Activity'yi Anında Kaldır

    func stop() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
