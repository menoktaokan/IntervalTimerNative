import SwiftUI

// MARK: - Uygulama Giriş Noktası
// @main: iOS'a "uygulama buradan başlar" der.
// App protokolü: SwiftUI uygulamasının temel yapısı.

@main
struct IntervalTimerNativeApp: App {

    // init: Uygulama ilk açıldığında çalışır (bir kez)
    init() {
        // Bildirim izni iste — kullanıcıya "Bildirim göndermek istiyor" diye sorar
        // İlk açılışta bir kez sorar, sonra ayarlardan değiştirilebilir
        NotificationManager.shared.requestPermission()

        // SoundManager'ı başlat — ses oturumunu yapılandırır
        // Singleton olduğu için .shared'a erişmek yeterli, otomatik init olur
        _ = SoundManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
