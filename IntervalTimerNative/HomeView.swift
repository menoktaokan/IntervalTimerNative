import SwiftUI

// MARK: - HomeView
// Uygulamanın ana ekranı.
// Güncellemeler:
// - Koleksiyon seçici: Yatay butonlar → Dropdown menü
// - Zamanlayıcı kopyalama: Sola kaydırınca "Kopyala" butonu
// - Sıralama: Sağ üstteki "Düzenle" ile sürükle-bırak

struct HomeView: View {

    @State private var engine = TimerEngine()
    @State private var collections: [TimerCollection] = []
    @State private var selectedIndex: Int = 0
    @State private var showingAddSheet = false
    @State private var showingRunning = false
    @State private var editingItem: TimerItem? = nil
    @State private var showingCollectionInput = false
    @State private var newCollectionTitle = ""

    // List'in düzenleme modunu kontrol eder (sürükle-bırak sıralama için)
    @State private var isEditing = false

    private var currentCollection: TimerCollection? {
        guard selectedIndex >= 0, selectedIndex < collections.count else { return nil }
        return collections[selectedIndex]
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Üst Çubuk — Başlık + Koleksiyon Dropdown + Düzenle
                HStack {
                    Text("Interval Timer")
                        .font(.title.weight(.bold))
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    // Düzenle / Bitti butonu — sıralama modunu açar/kapar
                    if !(currentCollection?.timers.isEmpty ?? true) {
                        Button(isEditing ? "Bitti" : "Düzenle") {
                            withAnimation { isEditing.toggle() }
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 4)

                // MARK: Koleksiyon Dropdown Seçici
                // Menu: iOS'un standart dropdown menüsü.
                // Dokunulduğunda seçenekler aşağı açılır.
                HStack {
                    Menu {
                        // Her koleksiyon bir menü öğesi
                        ForEach(Array(collections.enumerated()), id: \.element.id) { index, collection in
                            Button(action: {
                                selectedIndex = index
                                isEditing = false
                            }) {
                                // Seçili olanın yanında ✓ işareti göster
                                if index == selectedIndex {
                                    Label(collection.title, systemImage: "checkmark")
                                } else {
                                    Text(collection.title)
                                }
                            }
                        }

                        Divider()   // Ayırıcı çizgi

                        // Yeni koleksiyon ekle
                        Button(action: { showingCollectionInput = true }) {
                            Label("Yeni Koleksiyon", systemImage: "plus")
                        }

                        // Mevcut koleksiyonu sil (en az 1 koleksiyon kalmalı)
                        if collections.count > 1 {
                            Button(role: .destructive, action: deleteCurrentCollection) {
                                Label("Bu Koleksiyonu Sil", systemImage: "trash")
                            }
                        }
                    } label: {
                        // Dropdown butonunun görünümü
                        HStack(spacing: 6) {
                            Text(currentCollection?.title ?? "Koleksiyon")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)

                            // Aşağı ok ikonu — "bu bir dropdown" sinyali
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                // MARK: Zamanlayıcı Listesi
                if let collection = currentCollection {
                    if collection.timers.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.system(size: 44))
                                .foregroundColor(AppColors.textSecondary.opacity(0.4))
                            Text("Henüz zamanlayıcı yok")
                                .foregroundColor(AppColors.textSecondary)
                            Text("Aşağıdaki + butonuyla ekleyin")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(collection.timers) { item in
                                timerRow(item)
                                    .listRowBackground(AppColors.surface)
                                    .listRowSeparatorTint(AppColors.border)
                                    // MARK: Sola Kaydırma Aksiyonları (Leading Swipe)
                                    .swipeActions(edge: .leading) {
                                        // Kopyala butonu — sola kaydırınca görünür
                                        Button(action: { duplicateTimer(item) }) {
                                            Label("Kopyala", systemImage: "doc.on.doc")
                                        }
                                        .tint(AppColors.primary)
                                    }
                                    // MARK: Sağa Kaydırma Aksiyonları (Trailing Swipe)
                                    .swipeActions(edge: .trailing) {
                                        // Sil butonu — sağa kaydırınca görünür
                                        Button(role: .destructive, action: {
                                            deleteTimerById(item.id)
                                        }) {
                                            Label("Sil", systemImage: "trash")
                                        }
                                    }
                                    // Satıra tıklayınca düzenleme sheet'i aç
                                    .onTapGesture {
                                        editingItem = item
                                    }
                            }
                            // onMove: Düzenleme modunda sürükle-bırak sıralama
                            .onMove(perform: moveTimer)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        // environment: List'in düzenleme modunu kontrol eder
                        // .active iken satırların solunda tutma çubuğu görünür
                        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                    }
                }

                // MARK: Alt Bilgi + Butonlar

                if let collection = currentCollection, !collection.timers.isEmpty {
                    let total = collection.timers.reduce(0) { $0 + $1.duration }
                    Text("Toplam: \(formatMMSS(Double(total))) · \(collection.timers.count) zamanlayıcı")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 8)
                }

                HStack(spacing: 12) {
                    Button(action: { showingAddSheet = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Ekle")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.surface)
                        .foregroundColor(AppColors.textPrimary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                    }

                    Button(action: startTimer) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Başlat")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            (currentCollection?.timers.isEmpty ?? true)
                                ? AppColors.primary.opacity(0.3)
                                : AppColors.primary
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(currentCollection?.timers.isEmpty ?? true)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        // MARK: - Yaşam Döngüsü ve Sheet'ler

        .onAppear {
            collections = TimerCollection.loadAll()
        }

        .sheet(isPresented: $showingAddSheet) {
            AddTimerSheet { name, duration in
                let item = TimerItem(label: name, duration: duration)
                collections[selectedIndex].timers.append(item)
                saveAll()
            }
        }

        .sheet(item: $editingItem) { item in
            AddTimerSheet(editingItem: item) { name, duration in
                if let idx = collections[selectedIndex].timers.firstIndex(where: { $0.id == item.id }) {
                    collections[selectedIndex].timers[idx].label = name
                    collections[selectedIndex].timers[idx].duration = duration
                    saveAll()
                }
            }
        }

        .fullScreenCover(isPresented: $showingRunning) {
            RunningView(engine: engine) {
                showingRunning = false
            }
        }

        .alert("Yeni Koleksiyon", isPresented: $showingCollectionInput) {
            TextField("Koleksiyon adı", text: $newCollectionTitle)
            Button("Ekle") {
                guard !newCollectionTitle.isEmpty else { return }
                let newCollection = TimerCollection(title: newCollectionTitle)
                collections.append(newCollection)
                selectedIndex = collections.count - 1
                newCollectionTitle = ""
                saveAll()
            }
            Button("İptal", role: .cancel) {
                newCollectionTitle = ""
            }
        }
    }

    // MARK: - Zamanlayıcı Satırı

    private func timerRow(_ item: TimerItem) -> some View {
        HStack {
            // Sıra numarası (yuvarlak badge)
            if let idx = currentCollection?.timers.firstIndex(where: { $0.id == item.id }) {
                Text("\(idx + 1)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 24, height: 24)
                    .background(AppColors.primary.opacity(0.15))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.label)
                    .font(.body.weight(.medium))
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()

            Text(formatMMSS(Double(item.duration)))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Aksiyonlar

    private func startTimer() {
        guard let collection = currentCollection, !collection.timers.isEmpty else { return }
        engine.timers = collection.timers
        engine.start()
        showingRunning = true
    }

    /// Zamanlayıcıyı kopyala — aynı isim ve süreyle yeni bir tane ekler
    private func duplicateTimer(_ item: TimerItem) {
        // Orijinalin hemen altına ekle
        if let idx = collections[selectedIndex].timers.firstIndex(where: { $0.id == item.id }) {
            let copy = TimerItem(label: item.label, duration: item.duration)
            collections[selectedIndex].timers.insert(copy, at: idx + 1)
            saveAll()
        }
    }

    /// ID'ye göre zamanlayıcı sil
    private func deleteTimerById(_ id: UUID) {
        collections[selectedIndex].timers.removeAll { $0.id == id }
        saveAll()
    }

    /// Sürükle-bırak sıralama
    private func moveTimer(from source: IndexSet, to destination: Int) {
        collections[selectedIndex].timers.move(fromOffsets: source, toOffset: destination)
        saveAll()
    }

    /// Mevcut koleksiyonu sil
    private func deleteCurrentCollection() {
        guard collections.count > 1 else { return }
        collections.remove(at: selectedIndex)
        selectedIndex = max(0, selectedIndex - 1)
        saveAll()
    }

    private func saveAll() {
        TimerCollection.save(collections)
    }
}
