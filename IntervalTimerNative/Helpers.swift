import Foundation

// MARK: - Zaman Formatlama
// Saniye cinsinden süreyi "05:30" gibi okunabilir formata çevirir.
//
// Örnek: 90 saniye → "01:30"
// Örnek: 5 saniye  → "00:05"
// Örnek: 3661 saniye → "61:01" (saati dakikaya çevirir)

func formatMMSS(_ totalSeconds: TimeInterval) -> String {
    // ceil: Yukarı yuvarla. 29.3 → 30 olur.
    // Neden? Ekranda "0" görünmeden önce "1" göstermek istiyoruz.
    // Aksi halde kullanıcı 0.9 saniye boyunca "0" görür, kafa karıştırır.
    let whole = Int(ceil(totalSeconds))

    let minutes = whole / 60        // Tam bölme: 90 / 60 = 1
    let seconds = whole % 60        // Kalan: 90 % 60 = 30

    // %02d: En az 2 haneli yaz, eksikse başına 0 koy. 5 → "05"
    return String(format: "%02d:%02d", minutes, seconds)
}

// MARK: - Tema Renkleri
// Uygulamanın renk paleti. Tek bir yerden yönetmek tutarlılık sağlar.

import SwiftUI

enum AppColors {
    static let background = Color(red: 0.07, green: 0.09, blue: 0.14)      // Koyu lacivert arka plan
    static let surface = Color(red: 0.11, green: 0.14, blue: 0.20)          // Kart/yüzey rengi
    static let primary = Color(red: 0.36, green: 0.52, blue: 1.0)           // Ana vurgu (mavi)
    static let secondary = Color(red: 0.20, green: 0.83, blue: 0.60)        // İkincil vurgu (yeşil)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.35)            // Uyarı/son saniyeler (kırmızı)
    static let textPrimary = Color.white                                      // Ana metin
    static let textSecondary = Color(white: 0.55)                            // İkincil metin
    static let border = Color(white: 0.2)                                    // Kenarlık
}
