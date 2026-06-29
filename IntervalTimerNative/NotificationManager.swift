import UserNotifications

// MARK: - NotificationManager
// iOS'un yerel bildirim sistemini yönetir.
//
// Neden bildirim lazım?
// Uygulama arka plandayken sessiz ses döngüsü CPU'yu canlı tutar
// ve sesler çalar. Ama kullanıcı uygulamayı tamamen kapatırsa (force quit),
// sessiz döngü de durur. Bu durumda bile bildirimler zamanında gelir
// çünkü iOS bildirim sistemi uygulamadan BAĞIMSIZ çalışır.
//
// UNUserNotificationCenter: iOS'un bildirim merkezi.
// Uygulamadan bağımsız, iOS işletim sistemi tarafından yönetilir.

class NotificationManager {

    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - İzin İsteme
    // iOS'ta bildirim göndermeden önce kullanıcıdan izin almak zorunludur.
    // Bu fonksiyon uygulama ilk açıldığında çağrılır.

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Bildirim izni verildi")
            } else {
                print("❌ Bildirim izni reddedildi: \(error?.localizedDescription ?? "")")
            }
        }
    }

    // MARK: - Segment Bitişi Bildirimleri Planlama
    // Timer başlatıldığında, her segment'in bitiş zamanı için
    // önceden bildirim planlar. Böylece uygulama kapansa bile
    // bildirimler zamanında gelir.
    //
    // timers: Zamanlayıcı listesi
    // startingFrom: Kaçıncı indeksten başlayarak planlanacak

    func scheduleSegmentNotifications(timers: [TimerItem], startingFrom index: Int) {
        // Önce eski bildirimleri temizle (çakışmasın)
        cancelAll()

        // Şu anki zamandan itibaren her segment'in bitiş zamanını hesapla
        var cumulativeSeconds: TimeInterval = 0

        for i in index..<timers.count {
            cumulativeSeconds += TimeInterval(timers[i].duration)

            // Bildirim içeriği
            let content = UNMutableNotificationContent()

            let isLast = (i == timers.count - 1)
            if isLast {
                // Son segment → tamamlanma bildirimi
                content.title = "Tamamlandı! 🎉"
                content.body = "\(timers.count) zamanlayıcının tümü bitti."
                content.sound = .default
            } else {
                // Ara segment → sonraki zamanlayıcı bildirimi
                let nextTimer = timers[i + 1]
                content.title = "\(timers[i].label) bitti"
                content.body = "Sıradaki: \(nextTimer.label) — \(formatMMSS(Double(nextTimer.duration)))"
                content.sound = .default
            }

            // UNTimeIntervalNotificationTrigger: Belirli saniye sonra tetiklenir
            // repeats: false → sadece bir kez çalar
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: cumulativeSeconds,
                repeats: false
            )

            // Bildirimi sisteme kaydet
            // identifier: Her bildirimi benzersiz tanımlar (iptal için kullanılır)
            let request = UNNotificationRequest(
                identifier: "segment_\(i)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error {
                    print("Bildirim eklenemedi: \(error)")
                }
            }
        }
    }

    // MARK: - Tüm Bildirimleri İptal Et
    // Kullanıcı pause/reset yaptığında veya timer tamamlandığında çağrılır.

    func cancelAll() {
        // Henüz tetiklenmemiş tüm bildirimleri sil
        center.removeAllPendingNotificationRequests()
    }
}
