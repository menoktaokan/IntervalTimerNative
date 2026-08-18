import AVFoundation
import MediaPlayer

// MARK: - SoundManager
// Ses çalma, arka plan ses oturumu ve kilit ekranı kontrolünden sorumlu.
//
// Arka planda ses çalabilmek için iki şey gerekir:
//   1. Info.plist'te UIBackgroundModes = audio (build settings'te tanımlı)
//   2. Kesintisiz çalan bir AVAudioPlayer — yoksa iOS uygulamayı askıya alır
//
// (2) için çok düşük genlikli, duyulamayan bir döngü çalıyoruz. Bu döngü
// durursa kilit ekranında geri sayım sesleri de susar.

class SoundManager {

    static let shared = SoundManager()

    private var tickPlayer: AVAudioPlayer?
    private var timerDonePlayer: AVAudioPlayer?
    private var allDonePlayer: AVAudioPlayer?
    private var silentPlayer: AVAudioPlayer?

    /// Kullanıcı sesi kapattıysa uyarı sesleri çalınmaz.
    /// Arka plan döngüsü yine de çalışır — zamanlayıcının kilit ekranında
    /// doğru ilerlemesi buna bağlı.
    var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }

    private init() {
        setupAudioSession()
        loadSounds()
        observeInterruptions()
    }

    // MARK: - Ses Oturumu

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // .playback → ekran kilitliyken ve sessiz mod anahtarı açıkken bile çal
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("❌ Ses oturumu kurulamadı: \(error)")
        }
    }

    /// Oturumu yeniden aktifleştirir. Telefon görüşmesi, alarm veya başka bir
    /// uygulama oturumu devre dışı bırakmış olabilir.
    private func activateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Ses oturumu aktifleştirilemedi: \(error)")
        }
    }

    // MARK: - Kesinti Yönetimi
    // Gelen arama gibi kesintiler ses oturumunu devre dışı bırakır.
    // Kesinti bitince oturumu ve sessiz döngüyü geri getirmezsek ses bir daha çalmaz.

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw)
            else { return }

            if type == .ended {
                self.activateSession()
                // Kesintiden önce döngü çalışıyorduysa devam ettir
                if self.silentLoopShouldRun {
                    self.silentPlayer?.play()
                }
            }
        }
    }

    // MARK: - Ses Dosyaları

    private func loadSounds() {
        tickPlayer = makePlayer(resource: "tick")
        timerDonePlayer = makePlayer(resource: "timer_done")
        allDonePlayer = makePlayer(resource: "all_done")
        setupSilentLoop()
    }

    private func makePlayer(resource: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else {
            print("❌ Ses dosyası bulunamadı: \(resource).wav")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("❌ \(resource).wav yüklenemedi: \(error)")
            return nil
        }
    }

    // MARK: - Sessiz Arka Plan Döngüsü

    private var silentLoopShouldRun = false

    private func setupSilentLoop() {
        guard let url = makeSilentWAV() else {
            print("❌ Sessiz döngü dosyası üretilemedi — arka planda ses ÇALMAYACAK")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1.0     // Örnekler zaten duyulamaz genlikte
            player.prepareToPlay()
            silentPlayer = player
        } catch {
            print("❌ Sessiz döngü yüklenemedi: \(error)")
        }
    }

    /// 16-bit PCM WAV dosyasını başlığıyla birlikte elle üretir.
    ///
    /// Neden elle? AVAudioFile'ın standart formatı Float32'dir ve o ayarlarla
    /// yazılan .wav dosyasını AVAudioPlayer açamıyor — sessizce nil dönüyordu.
    ///
    /// Örnekler tam sıfır değil, ±1 LSB arasında değişiyor (yaklaşık -90 dBFS).
    /// Duyulamaz, ama iOS için "gerçek ses" sayılır; tam sessizlikte sistem
    /// oynatmayı optimize edip uygulamayı askıya alabiliyor.
    private func makeSilentWAV() -> URL? {
        let sampleRate = 44_100
        let channels = 1
        let bitsPerSample = 16
        let seconds = 1
        let frameCount = sampleRate * seconds
        let dataSize = frameCount * channels * bitsPerSample / 8

        var data = Data()
        func append32(_ value: UInt32) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        func append16(_ value: UInt16) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }

        data.append(contentsOf: Array("RIFF".utf8))
        append32(UInt32(36 + dataSize))
        data.append(contentsOf: Array("WAVE".utf8))

        data.append(contentsOf: Array("fmt ".utf8))
        append32(16)                                                    // alt chunk boyutu
        append16(1)                                                     // PCM
        append16(UInt16(channels))
        append32(UInt32(sampleRate))
        append32(UInt32(sampleRate * channels * bitsPerSample / 8))     // byte rate
        append16(UInt16(channels * bitsPerSample / 8))                  // block align
        append16(UInt16(bitsPerSample))

        data.append(contentsOf: Array("data".utf8))
        append32(UInt32(dataSize))

        // ±1 LSB dalgalanma — işitme eşiğinin çok altında
        var samples = [Int16](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            samples[i] = (i % 2 == 0) ? 1 : -1
        }
        samples.withUnsafeBufferPointer { buffer in
            data.append(UnsafeBufferPointer(
                start: UnsafeRawPointer(buffer.baseAddress!).assumingMemoryBound(to: UInt8.self),
                count: dataSize
            ))
        }

        // Documents altında sakla — geçici dizin sistem tarafından temizlenebilir
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }
        let url = dir.appendingPathComponent("silence.wav")

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("❌ silence.wav yazılamadı: \(error)")
            return nil
        }
    }

    // MARK: - Arka Plan Döngüsü Kontrolü

    func startBackgroundLoop() {
        silentLoopShouldRun = true
        activateSession()               // Oturum arada kapanmış olabilir
        silentPlayer?.play()
        if silentPlayer == nil {
            print("⚠️ Sessiz döngü yok — ekran kilitlendiğinde sesler susacak")
        }
        updateNowPlaying(title: "Interval Timer", isPlaying: true)
    }

    func stopBackgroundLoop() {
        silentLoopShouldRun = false
        silentPlayer?.pause()
        clearNowPlaying()
    }

    // MARK: - Ses Çalma

    private func play(_ player: AVAudioPlayer?) {
        guard isSoundEnabled, let player else { return }
        player.currentTime = 0
        player.play()
    }

    func playTick()      { play(tickPlayer) }
    func playTimerDone() { play(timerDonePlayer) }
    func playAllDone()   { play(allDonePlayer) }

    // MARK: - Kilit Ekranı (Now Playing)

    func updateNowPlaying(title: String, elapsed: TimeInterval = 0, total: TimeInterval = 0, isPlaying: Bool = true) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = "Interval Timer"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        info[MPMediaItemPropertyPlaybackDuration] = total
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
