import SwiftUI

// MARK: - ContentView
// Uygulamanın kök View'ı. IntervalTimerNativeApp.swift buraya yönlendirir.
// Tek işi HomeView'ı göstermek ve koyu temayı zorlamak.

struct ContentView: View {
    var body: some View {
        HomeView()
            // preferredColorScheme: Uygulamayı her zaman koyu tema modunda göster
            // Kullanıcının telefon ayarından bağımsız çalışır
            .preferredColorScheme(.dark)
    }
}
