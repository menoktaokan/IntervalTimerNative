import SwiftUI

// MARK: - AddTimerSheet
// Yeni zamanlayıcı eklemek veya mevcut birini düzenlemek için açılan sayfa.
// .sheet() ile gösterilir — ekranın altından yukarı kayar.
//
// @Binding: Bu View dışarıdan bir değişkene bağlanır.
// Burada değişiklik yapılınca dışarıdaki (HomeView) değişken de güncellenir.
// React'taki props + callback karşılığıdır.

struct AddTimerSheet: View {

    // Düzenleme modunda mevcut zamanlayıcının ID'si (nil ise yeni ekleme)
    var editingItem: TimerItem?

    // Sheet'i kapatmak için kullanılır
    // @Environment: SwiftUI'ın sunduğu sistem değişkenlerine erişim
    @Environment(\.dismiss) private var dismiss

    // Kullanıcının girdiği isim
    @State private var label: String = ""

    // Dakika ve saniye seçimleri (Picker ile seçilecek)
    @State private var minutes: Int = 0
    @State private var seconds: Int = 30

    // Kaydet butonuna basıldığında çağrılacak fonksiyon
    // Dışarıdan (HomeView'dan) geçirilir
    var onSave: (String, Int) -> Void

    var body: some View {
        // NavigationStack: Üst çubuk (başlık + butonlar) sağlar
        NavigationStack {
            // Form: iOS'un standart ayarlar tarzı form görünümü
            Form {
                // MARK: İsim Alanı
                Section {
                    // TextField: Metin giriş alanı
                    // "Zamanlayıcı adı" placeholder olarak görünür
                    TextField("Zamanlayıcı adı", text: $label)
                } header: {
                    Text("İsim")
                }

                // MARK: Süre Seçimi
                Section {
                    // HStack: Yatay düzen (yan yana yerleştirme)
                    HStack {
                        // Picker: Dönen seçim çarkı
                        // selection: Seçilen değerin bağlandığı değişken
                        Picker("Dakika", selection: $minutes) {
                            // 0'dan 59'a kadar seçenekler oluştur
                            ForEach(0..<60) { m in
                                Text("\(m) dk").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)    // Dönen çark stili

                        Picker("Saniye", selection: $seconds) {
                            ForEach(0..<60) { s in
                                Text("\(s) sn").tag(s)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 150)         // Çark yüksekliği
                } header: {
                    Text("Süre")
                }
            }
            .navigationTitle(editingItem != nil ? "Düzenle" : "Yeni Zamanlayıcı")
            .navigationBarTitleDisplayMode(.inline)     // Küçük başlık
            .toolbar {
                // Sol üst: İptal butonu
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()   // Sheet'i kapat
                    }
                }
                // Sağ üst: Kaydet butonu
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let totalSeconds = minutes * 60 + seconds
                        // En az 1 saniye olmalı
                        let safeDuration = max(1, totalSeconds)
                        // İsim boşsa varsayılan isim kullan
                        let safeName = label.isEmpty ? "Zamanlayıcı" : label
                        onSave(safeName, safeDuration)
                        dismiss()
                    }
                    // Süre 0 ise kaydet butonu devre dışı
                    .disabled(minutes == 0 && seconds == 0)
                }
            }
            // MARK: - Düzenleme Modunda Mevcut Değerleri Yükle
            // .onAppear: View ekrana geldiğinde çalışır (React'taki useEffect([]) gibi)
            .onAppear {
                if let item = editingItem {
                    label = item.label
                    minutes = item.duration / 60
                    seconds = item.duration % 60
                }
            }
        }
    }
}
