import AVFoundation
import MediaPlayer

// MARK: - SoundManager
// Ses çalma, arka plan ses oturumu ve kilit ekranı kontrolünden sorumlu.
//
// ÖNEMLİ KAVRAM: iOS'ta ses çalmak için bir "Audio Session" (Ses Oturumu) gerekir.
// Bu oturum iOS'a şunu söyler:
// - "Ben ne tür bir uygulamayım?" (müzik, oyun, zamanlayıcı...)
// - "Ekran kilitlenince ses çalmaya devam edeyim mi?"
// - "Sessiz mod anahtarında ne yapayım?"
//
// React Native'de bu yapılamıyordu çünkü expo-audio bu ayarları desteklemiyordu.
// Native Swift'te ise doğrudan Apple'ın AVFoundation framework'ünü kullanıyoruz.

class SoundManager {

    // Singleton: Uygulama boyunca tek bir SoundManager örneği kullanılır.
    // Neden? Birden fazla ses oturumu birbirleriyle çakışır.
    static let shared = SoundManager()

    // AVAudioPlayer: Apple'ın ses çalma sınıfı. Her ses için ayrı bir player.
    private var tickPlayer: AVAudioPlayer?
    private var timerDonePlayer: AVAudioPlayer?
    private var allDonePlayer: AVAudioPlayer?

    // Kilit ekranında CPU'yu uyanık tutacak sessiz ses döngüsü
    private var silentPlayer: AVAudioPlayer?

    // Dışarıdan new SoundManager() yapılmasını engelle (singleton kalıbı)
    private init() {
        setupAudioSession()
        loadSounds()
    }

    // MARK: - Ses Oturumu Yapılandırması
    // İşte React Native projede çözemediğimiz şey tam olarak bu fonksiyon!

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()

            // .playback kategorisi → "Ben müzik/medya çalan bir uygulamayım"
            // Bu kategori iOS'a şunları söyler:
            //   1. Ekran kilitlenince ses çalmaya DEVAM ET
            //   2. Sessiz mod anahtarı kapalıyken bile ses çal
            //   3. Diğer uygulamaların sesini kıs
            try session.setCategory(.playback, mode: .default)

            // Ses oturumunu aktifleştir
            // Bu çağrı olmadan hiçbir ses çalmaz
            try session.setActive(true)

            print("✅ Ses oturumu başarıyla yapılandırıldı (arka plan + sessiz mod)")
        } catch {
            print("❌ Ses oturumu hatası: \(error)")
        }
    }

    // MARK: - Ses Dosyalarını Yükleme

    private func loadSounds() {
        // Bundle.main: Uygulamanın kendi dosya paketi
        // .forResource: Dosya adı (uzantısız), .withExtension: Dosya uzantısı
        // Bu dosyalar Xcode projesine eklendiğinde otomatik olarak Bundle'a dahil olur

        if let url = Bundle.main.url(forResource: "tick", withExtension: "wav") {
            tickPlayer = try? AVAudioPlayer(contentsOf: url)
            tickPlayer?.prepareToPlay()  // Sesi belleğe önceden yükle (gecikmeyi önler)
        }

        if let url = Bundle.main.url(forResource: "timer_done", withExtension: "wav") {
            timerDonePlayer = try? AVAudioPlayer(contentsOf: url)
            timerDonePlayer?.prepareToPlay()
        }

        if let url = Bundle.main.url(forResource: "all_done", withExtension: "wav") {
            allDonePlayer = try? AVAudioPlayer(contentsOf: url)
            allDonePlayer?.prepareToPlay()
        }

        // Sessiz ses: CPU'yu arka planda uyanık tutmak için
        // Neden gerekli? iOS, ses çalmayan bir uygulamayı arka planda dondurur.
        // Sessiz bir ses döngüsü çalarsak, iOS "bu uygulama hâlâ ses çalıyor" der
        // ve setInterval benzeri Timer'ları dondurmaz.
        setupSilentLoop()
    }

    // MARK: - Sessiz Arka Plan Döngüsü

    private func setupSilentLoop() {
        // 1 saniyelik sessiz ses dosyası oluştur (bellekte, dosya gerektirmez)
        // PCM formatında, tamamen sıfır dalgası = sessizlik
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let numSamples = Int(sampleRate * duration)

        // AVAudioFormat: Sesin teknik özellikleri (örnek hızı, kanal sayısı)
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1  // Mono ses (tek kanal)
        ) else { return }

        // AVAudioPCMBuffer: Ham ses verisi tamponu
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(numSamples)
        ) else { return }

        buffer.frameLength = AVAudioFrameCount(numSamples)
        // floatChannelData: Ses dalgası verisi. Hepsi 0 = sessizlik
        // Zaten varsayılan olarak 0 ile doldurulur, dokunmamıza gerek yok

        // Tamponu geçici bir dosyaya yaz, sonra AVAudioPlayer ile oku
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("silent.wav")

        do {
            let file = try AVAudioFile(
                forWriting: tempURL,
                settings: format.settings
            )
            try file.write(from: buffer)

            silentPlayer = try AVAudioPlayer(contentsOf: tempURL)
            silentPlayer?.numberOfLoops = -1    // -1 = sonsuz döngü
            silentPlayer?.volume = 0.01         // Neredeyse duyulmaz ama iOS "ses çalıyor" der
            silentPlayer?.prepareToPlay()
        } catch {
            print("Sessiz döngü oluşturulamadı: \(error)")
        }
    }

    // MARK: - Arka Plan Döngüsü Kontrolü
    // Timer başlatıldığında çağrılır → Ekran kilitlense bile CPU çalışmaya devam eder

    func startBackgroundLoop() {
        silentPlayer?.play()
        updateNowPlaying(title: "Interval Timer", isPlaying: true)
    }

    func stopBackgroundLoop() {
        silentPlayer?.pause()
        clearNowPlaying()
    }

    // MARK: - Ses Çalma
    // Her fonksiyon ilgili sesi baştan çalar.
    // currentTime = 0: Sesi en başa sar (önceki çalma bitmemiş olabilir)
    // play(): Sesi çal

    func playTick() {
        tickPlayer?.currentTime = 0
        tickPlayer?.play()
    }

    func playTimerDone() {
        timerDonePlayer?.currentTime = 0
        timerDonePlayer?.play()
    }

    func playAllDone() {
        allDonePlayer?.currentTime = 0
        allDonePlayer?.play()
    }

    // MARK: - Kilit Ekranı Kontrolü (Now Playing)
    // Telefon kilitliyken müzik uygulaması gibi bir çubuk gösterir.
    // MPNowPlayingInfoCenter: Apple'ın kilit ekranı medya bilgisi merkezi.
    // Spotify, Apple Music gibi uygulamalar da bunu kullanır.

    func updateNowPlaying(title: String, elapsed: TimeInterval = 0, total: TimeInterval = 0, isPlaying: Bool = true) {
        var info = [String: Any]()

        // MPMediaItemPropertyTitle: Kilit ekranında gösterilecek başlık
        info[MPMediaItemPropertyTitle] = title

        // MPMediaItemPropertyArtist: Alt başlık
        info[MPMediaItemPropertyArtist] = "Interval Timer"

        // MPNowPlayingInfoPropertyElapsedPlaybackTime: Geçen süre (ilerleme çubuğu için)
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed

        // MPMediaItemPropertyPlaybackDuration: Toplam süre
        info[MPMediaItemPropertyPlaybackDuration] = total

        // MPNowPlayingInfoPropertyPlaybackRate: 1.0 = çalıyor, 0.0 = duraklatıldı
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        // Bilgiyi kilit ekranına gönder
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
