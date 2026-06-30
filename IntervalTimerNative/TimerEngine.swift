import Foundation
import Observation
import UIKit

// MARK: - TimerEngine
// Geri sayım motorunun kalbi. Tüm zamanlama mantığı burada.
//
// @Observable: Swift 6'nın yeni gözlemlenebilirlik makrosu.
// Bu makro ile işaretlenen sınıfın TÜM stored property'leri
// değiştiğinde SwiftUI arayüzü otomatik olarak güncellenir.
// Eski @Published + ObservableObject yerine geçer, çok daha basit.
//
// React Native'deki useState + setInterval karşılığı budur,
// ama çok daha güvenilir çünkü iOS'un kendi Timer mekanizmasını kullanıyor.

@Observable
class TimerEngine {

    // MARK: - Durum Değişkenleri
    // @Observable sayesinde bu değişkenler değiştiğinde SwiftUI arayüzü otomatik güncellenir
    // @Published yazmaya gerek yok — @Observable tüm stored property'leri otomatik izler

    var status: Status = .idle           // Mevcut durum: boşta, çalışıyor, duraklatıldı, tamamlandı
    var currentIndex: Int = -1           // Şu an çalan zamanlayıcının sırası (0'dan başlar)
    var remaining: TimeInterval = 0      // Kalan süre (saniye, ondalıklı: 29.45)
    var timers: [TimerItem] = []         // Çalıştırılacak zamanlayıcı listesi

    // MARK: - Durum Tanımı (Enum)
    // Enum: Belirli, sınırlı seçeneklerden birini temsil eder.
    // String olması sayesinde kolayca yazdırılabilir ve karşılaştırılabilir.
    enum Status: String {
        case idle           // Boşta — henüz başlatılmadı
        case running        // Çalışıyor — geri sayım aktif
        case paused         // Duraklatıldı — kullanıcı pause'a bastı
        case completed      // Tamamlandı — tüm zamanlayıcılar bitti
    }

    // MARK: - İç Değişkenler (Arayüzde Gösterilmez)

    // Timer: iOS'un zamanlama nesnesi. Her 50ms'de bir tetiklenir.
    // React Native'deki setInterval karşılığı, ama iOS optimize eder.
    private var timer: Timer?

    // Mevcut segmentin bitiş zamanı (Unix timestamp olarak)
    // Neden süreyi saymak yerine bitiş zamanını saklıyoruz?
    // Çünkü Timer tam 50ms'de bir tetiklenmeyebilir (CPU meşgulse gecikir).
    // Ama Date() her zaman doğru zamanı verir. Bu yüzden:
    //   kalanSüre = bitişZamanı - şimdi
    // formülü her zaman doğru sonuç verir.
    private var endTime: Date = .distantPast

    // Son uyarı sesi çalan tam saniye (3, 2 veya 1). Aynı saniyede tekrar ses çalmasın diye.
    private var lastWarnedSecond: Int = -1

    // Duraklatıldığında kalan süreyi sakla (devam ettirmek için)
    private var remainingAtPause: TimeInterval = 0

    // Ses ve Live Activity yöneticilerine kısa erişim
    private let sound = SoundManager.shared
    private let live = LiveActivityManager.shared

    // Koleksiyon adı — Live Activity'de gösterilir
    var collectionTitle: String = ""

    // Son kaç saniyede uyarı sesi çalsın
    private let warningSeconds = 3

    // MARK: - Hesaplanan Özellikler (Computed Properties)
    // Bu değerler saklanmaz, her erişildiğinde hesaplanır

    /// Şu anda çalan zamanlayıcı (varsa)
    var currentTimer: TimerItem? {
        guard currentIndex >= 0, currentIndex < timers.count else { return nil }
        return timers[currentIndex]
    }

    /// Toplam zamanlayıcı sayısı
    var totalCount: Int { timers.count }

    /// Kalan sürenin tamsayı karşılığı (ekranda göstermek için)
    var remainingInt: Int { Int(ceil(remaining)) }

    // MARK: - Zamanlayıcı Kontrolü

    /// Geri sayımı başlat
    func start() {
        guard !timers.isEmpty else { return }
        sound.startBackgroundLoop()
        // Live Activity başlat — kilit ekranında canlı geri sayım görünecek
        live.start(
            collectionTitle: collectionTitle,
            segmentLabel: timers[0].label,
            index: 0,
            total: timers.count,
            duration: timers[0].duration
        )
        startSegment(at: 0)
    }

    /// Durakla
    func pause() {
        remainingAtPause = endTime.timeIntervalSinceNow
        stopTicking()
        status = .paused

        if let t = currentTimer {
            sound.updateNowPlaying(
                title: t.label,
                elapsed: Double(t.duration) - remaining,
                total: Double(t.duration),
                isPlaying: false
            )
            // Live Activity'yi duraklatma durumuna güncelle
            live.update(
                segmentLabel: t.label,
                index: currentIndex,
                total: timers.count,
                duration: Int(remaining),
                isPaused: true
            )
        }
    }

    /// Devam et
    func resume() {
        endTime = Date().addingTimeInterval(remainingAtPause)
        lastWarnedSecond = remainingInt + 1
        status = .running
        beginTicking()

        if let t = currentTimer {
            sound.updateNowPlaying(
                title: t.label,
                elapsed: Double(t.duration) - remaining,
                total: Double(t.duration),
                isPlaying: true
            )
            // Live Activity'yi devam ettir
            live.update(
                segmentLabel: t.label,
                index: currentIndex,
                total: timers.count,
                duration: Int(remaining),
                isPaused: false
            )
        }
    }

    /// Tamamen sıfırla (başa dön)
    func reset() {
        stopTicking()
        sound.stopBackgroundLoop()
        live.stop()                 // Live Activity'yi kaldır
        currentIndex = -1
        remaining = 0
        status = .idle
    }

    /// Mevcut segmenti atla, sonrakine geç
    func skip() {
        let isLast = currentIndex >= timers.count - 1
        if isLast {
            finishAll()
        } else {
            sound.playTimerDone()
            startSegment(at: currentIndex + 1)
        }
    }

    // MARK: - İç Mekanizma

    /// Belirli bir indeksteki zamanlayıcıyı başlat
    private func startSegment(at index: Int) {
        currentIndex = index
        let duration = timers[index].duration
        remaining = TimeInterval(duration)

        endTime = Date().addingTimeInterval(TimeInterval(duration))
        lastWarnedSecond = duration + 1
        status = .running

        // Now Playing kilit ekranını güncelle
        sound.updateNowPlaying(
            title: timers[index].label,
            elapsed: 0,
            total: Double(duration),
            isPlaying: true
        )

        // Live Activity'yi yeni segment bilgisiyle güncelle
        // (ilk segment zaten start()'ta başlatılıyor, burada sadece güncelleme)
        if index > 0 {
            live.update(
                segmentLabel: timers[index].label,
                index: index,
                total: timers.count,
                duration: duration,
                isPaused: false
            )
        }

        beginTicking()
    }

    /// Her 50ms'de çalışan geri sayım döngüsünü başlat
    private func beginTicking() {
        stopTicking()   // Önceki Timer varsa temizle

        // Timer.scheduledTimer: iOS'un resmi zamanlama mekanizması
        // - timeInterval: Her kaç saniyede bir tetiklensin (0.05 = 50ms)
        // - repeats: Tekrarlansın mı
        // - RunLoop.main + .common: Kaydırma sırasında bile çalışmaya devam et
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common modu: Ekran kaydırılırken Timer'ın durmasını engeller
        RunLoop.main.add(timer!, forMode: .common)
    }

    /// Her 50ms'de çağrılan geri sayım fonksiyonu
    private func tick() {
        // Kalan süre = bitiş zamanı - şu an
        let secondsLeft = endTime.timeIntervalSinceNow
        remaining = max(0, secondsLeft)

        let wholeSec = Int(ceil(remaining))

        // Uyarı sesi kontrolü: 3, 2, 1 saniyelerinde ses çal
        if wholeSec != lastWarnedSecond {
            // Atlanmış saniyeler varsa hepsini çal (CPU gecikmesi durumunda)
            for s in stride(from: lastWarnedSecond - 1, through: wholeSec, by: -1) {
                if s > 0 && s <= warningSeconds {
                    sound.playTick()

                    // Titreşim geri bildirimi
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
            lastWarnedSecond = wholeSec
        }

        // Süre doldu mu?
        if secondsLeft <= 0 {
            let isLast = currentIndex >= timers.count - 1
            if isLast {
                finishAll()
            } else {
                // Segment arası geçiş sesi
                sound.playTimerDone()

                // Titreşim: uyarı tipi (daha güçlü)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)

                // Sonraki segmete geç
                startSegment(at: currentIndex + 1)
            }
        }
    }

    /// Tüm zamanlayıcılar tamamlandı
    private func finishAll() {
        stopTicking()
        sound.stopBackgroundLoop()
        // Live Activity'yi "tamamlandı" olarak işaretle (1 dk sonra otomatik kalkar)
        live.complete(total: timers.count)
        currentIndex = -1
        remaining = 0
        status = .completed

        sound.playAllDone()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Timer'ı durdur ve temizle
    private func stopTicking() {
        timer?.invalidate()     // Timer'ı iptal et
        timer = nil             // Referansı temizle (bellek sızıntısını önler)
    }
}
