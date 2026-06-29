import SwiftUI

// MARK: - RunningView
// Geri sayım aktifken gösterilen tam ekran.
// Ortada büyük dairesel ilerleme çubuğu + kalan süre,
// altta durakla/devam et, durdur ve atla butonları.
//
// @ObservedObject: Dışarıdan gelen ObservableObject'i gözlemler.
// engine değiştiğinde (remaining, status vb.) bu View otomatik güncellenir.

struct RunningView: View {

    // @Observable olduğu için @ObservedObject yazmaya gerek yok
    // SwiftUI otomatik olarak engine'deki değişiklikleri takip eder
    var engine: TimerEngine

    // Bu View'ı kapatmak için üst View'dan geçirilen fonksiyon
    var onClose: () -> Void

    var body: some View {
        ZStack {
            // Tam ekran arka plan rengi
            AppColors.background.ignoresSafeArea()

            // Tamamlanma ekranı
            if engine.status == .completed {
                completedView
            } else {
                // Aktif geri sayım ekranı
                countdownView
            }
        }
    }

    // MARK: - Aktif Geri Sayım Ekranı

    private var countdownView: some View {
        VStack(spacing: 0) {

            // MARK: Üst Çubuk (Kapat + Adım Göstergesi)
            HStack {
                Button(action: {
                    engine.reset()      // Sıfırla
                    onClose()           // Ekranı kapat
                }) {
                    // SF Symbols: Apple'ın yerleşik ikon kütüphanesi
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()    // Ortaya boşluk koy (sağa iter)

                // "2 / 4" gibi adım göstergesi
                Text("\(engine.currentIndex + 1) / \(engine.totalCount)")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                // Sağ taraf dengeleme (simetri için görünmez eleman)
                Color.clear.frame(width: 26, height: 26)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // MARK: Dairesel İlerleme Çubuğu + Süre

            let duration = Double(engine.currentTimer?.duration ?? 1)
            let progress = 1.0 - (engine.remaining / duration)

            // ÖNEMLİ: Ekranda gösterilen sayı ceil ile yuvarlanıyor (3.5 → "4").
            // Renk kontrolünde de AYNI yuvarlanmış değeri kullanmalıyız.
            // Aksi halde ekranda "4" yazarken remaining=3.5 olduğundan
            // remaining<=3 false olur ve "4" beyaz görünür — bu hataya neden olur.
            let displaySeconds = Int(ceil(engine.remaining))
            let isFinalCountdown = engine.status == .running
                                   && displaySeconds >= 1
                                   && displaySeconds <= 3
            let ringColor = isFinalCountdown ? AppColors.danger : AppColors.primary

            ZStack {
                // Arka plan halkası (gri, tam daire)
                Circle()
                    .stroke(AppColors.surface, lineWidth: 16)
                    .frame(width: 260, height: 260)

                // İlerleme halkası (renkli, dolarak ilerler)
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        ringColor,
                        style: StrokeStyle(
                            lineWidth: 16,
                            lineCap: .round
                        )
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)

                // Ortadaki büyük süre metni
                Text(formatMMSS(engine.remaining))
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundColor(isFinalCountdown ? AppColors.danger : AppColors.textPrimary)
                    // contentTransition: Sayı değişiminde yumuşak geçiş (titreşim yerine)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: displaySeconds)
            }

            // MARK: Zamanlayıcı Adı
            Text(engine.currentTimer?.label ?? "Zamanlayıcı")
                .font(.title2.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 24)

            // MARK: Sıradaki Bilgisi
            if engine.currentIndex + 1 < engine.totalCount {
                let next = engine.timers[engine.currentIndex + 1]
                Text("Sıradaki: \(next.label) · \(formatMMSS(Double(next.duration)))")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 6)
            } else {
                Text("Son zamanlayıcı")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 6)
            }

            Spacer()

            // MARK: Kontrol Butonları
            HStack(spacing: 28) {
                // Durdur butonu
                controlButton(icon: "stop.fill", size: 56) {
                    engine.reset()
                    onClose()
                }

                // Durakla / Devam et butonu (büyük, ortada)
                Button(action: {
                    if engine.status == .running {
                        engine.pause()
                    } else {
                        engine.resume()
                    }
                }) {
                    Image(systemName: engine.status == .running ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(AppColors.background)
                        .frame(width: 84, height: 84)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                }

                // Atla butonu
                controlButton(icon: "forward.fill", size: 56) {
                    engine.skip()
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Tamamlanma Ekranı

    private var completedView: some View {
        VStack(spacing: 16) {
            Spacer()

            // Büyük onay işareti
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.secondary)

            Text("Tamamlandı!")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(AppColors.textPrimary)

            Text("\(engine.totalCount) zamanlayıcının tümünü bitirdin.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            // Alt butonlar
            HStack(spacing: 16) {
                // Listeye dön
                Button(action: onClose) {
                    Text("Listeye Dön")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.surface)
                        .foregroundColor(AppColors.textSecondary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }

                // Tekrar başlat
                Button(action: { engine.start() }) {
                    Text("Tekrar Başlat")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.secondary)
                        .foregroundColor(Color(red: 0.02, green: 0.13, blue: 0.11))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Yardımcı: Yuvarlak Kontrol Butonu

    private func controlButton(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: size, height: size)
                .background(AppColors.surface)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(AppColors.border, lineWidth: 1)
                )
        }
    }
}
