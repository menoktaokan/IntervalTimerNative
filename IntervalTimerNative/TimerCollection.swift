import Foundation

// MARK: - TimerCollection
// Birden fazla TimerItem'ı bir arada tutan koleksiyon modeli.
// Örnek: "HIIT" koleksiyonu → [Koşu 30s, Dinlenme 10s, Koşu 30s, Dinlenme 10s]
// Örnek: "Pomodoro" koleksiyonu → [Çalışma 25dk, Mola 5dk]

struct TimerCollection: Codable, Identifiable, Equatable {

    let id: UUID
    var title: String           // Koleksiyon adı: "HIIT", "Pomodoro", "Okul Ders"
    var timers: [TimerItem]     // Bu koleksiyona ait zamanlayıcılar

    init(title: String, timers: [TimerItem] = []) {
        self.id = UUID()
        self.title = title
        self.timers = timers
    }
}

// MARK: - Varsayılan Koleksiyonlar
// Uygulama ilk açıldığında gösterilecek hazır rutinler.
// Kullanıcı bunları düzenleyebilir veya yenilerini ekleyebilir.

extension TimerCollection {

    /// Uygulama ilk açılışta bu koleksiyonlarla başlar
    static let defaults: [TimerCollection] = [
        TimerCollection(
            title: "HIIT",
            timers: [
                TimerItem(label: "Koşu", duration: 30),
                TimerItem(label: "Dinlenme", duration: 10),
                TimerItem(label: "Koşu", duration: 30),
                TimerItem(label: "Dinlenme", duration: 10),
            ]
        ),
        TimerCollection(
            title: "Pomodoro",
            timers: [
                TimerItem(label: "Çalışma", duration: 1500),   // 25 dakika
                TimerItem(label: "Mola", duration: 300),        // 5 dakika
            ]
        ),
        TimerCollection(
            title: "Okul Ders",
            timers: [
                TimerItem(label: "Ders", duration: 2400),       // 40 dakika
                TimerItem(label: "Teneffüs", duration: 600),    // 10 dakika
            ]
        ),
    ]
}

// MARK: - Kalıcı Depolama (Persistence)
// Koleksiyonları JSON formatında telefonun disk alanına kaydetme ve okuma.
// Uygulama kapanıp açılsa bile veriler korunur.

extension TimerCollection {

    // Dosyanın kaydedileceği konum:
    // iPhone'da: /Documents/timer_collections.json
    private static var fileURL: URL {
        // FileManager: iOS'un dosya sistemi yöneticisi
        // .documentDirectory: Uygulamaya özel, kalıcı depolama alanı
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("timer_collections.json")
    }

    /// Koleksiyonları JSON dosyasına kaydet
    static func save(_ collections: [TimerCollection]) {
        do {
            // JSONEncoder: Swift nesnelerini → JSON verisine dönüştürür
            let data = try JSONEncoder().encode(collections)

            // Dosyaya yaz. atomicWrite: Ya tamamen yazar ya hiç yazmaz (veri bütünlüğü)
            try data.write(to: fileURL, options: .atomicWrite)
        } catch {
            print("Koleksiyonlar kaydedilemedi: \(error)")
        }
    }

    /// Kaydedilmiş koleksiyonları diskten oku
    /// İlk açılışta dosya yoksa varsayılan koleksiyonları döndürür
    static func loadAll() -> [TimerCollection] {
        guard let data = try? Data(contentsOf: fileURL) else {
            // Dosya yoksa (ilk açılış) → varsayılanları döndür
            return TimerCollection.defaults
        }
        do {
            // JSONDecoder: JSON verisini → Swift nesnelerine dönüştürür
            return try JSONDecoder().decode([TimerCollection].self, from: data)
        } catch {
            print("Koleksiyonlar okunamadı: \(error)")
            return TimerCollection.defaults
        }
    }
}
