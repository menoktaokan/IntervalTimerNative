import SwiftUI

// MARK: - Uygulama Giriş Noktası
// @main: iOS'a "uygulama buradan başlar" der.
// App protokolü: SwiftUI uygulamasının temel yapısı.

@main
struct IntervalTimerNativeApp: App {

    init() {
        _ = SoundManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
