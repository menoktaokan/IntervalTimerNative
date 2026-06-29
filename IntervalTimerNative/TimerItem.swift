import Foundation

// MARK: - TimerItem
// Tek bir zamanlayıcıyı temsil eden veri modeli.
// Örnek: "Koşu" — 30 saniye, "Dinlenme" — 10 saniye
//
// Codable  → JSON'a dönüştürülüp dosyaya kaydedilebilir (kalıcı depolama için)
// Identifiable → SwiftUI listelerinde her öğenin benzersiz kimliğini sağlar
// Equatable → İki TimerItem'ın aynı olup olmadığını karşılaştırabilmek için

struct TimerItem: Codable, Identifiable, Equatable {

    // Her zamanlayıcıya otomatik benzersiz kimlik atanır (UUID = Universal Unique Identifier)
    let id: UUID

    // Kullanıcının verdiği isim: "Koşu", "Dinlenme", "Plank" vb.
    var label: String

    // Süre, saniye cinsinden. Örneğin 30 = 30 saniye, 90 = 1 dakika 30 saniye
    var duration: Int

    // Yeni bir TimerItem oluşturulduğunda varsayılan değerlerle başlatma
    // id otomatik üretilir, böylece her zamanlayıcı benzersiz olur
    init(label: String = "Zamanlayıcı", duration: Int = 30) {
        self.id = UUID()
        self.label = label
        self.duration = duration
    }
}
