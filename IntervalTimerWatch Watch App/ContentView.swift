import SwiftUI

struct ContentView: View {
    @State private var collections = WatchCollection.defaults
    @State private var selectedCollection: WatchCollection?
    @State private var engine = WatchTimerEngine()
    @State private var showingTimer = false

    var body: some View {
        NavigationStack {
            List(collections) { collection in
                Button {
                    selectedCollection = collection
                    engine.timers = collection.timers
                    engine.start()
                    showingTimer = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(collection.title)
                            .font(.headline)
                        let total = collection.timers.reduce(0) { $0 + $1.duration }
                        let m = total / 60
                        let s = total % 60
                        Text("\(collection.timers.count) adet · \(String(format: "%02d:%02d", m, s))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Timer")
            .fullScreenCover(isPresented: $showingTimer) {
                WatchRunningView(engine: engine) {
                    engine.reset()
                    showingTimer = false
                }
            }
        }
    }
}

struct WatchRunningView: View {
    var engine: WatchTimerEngine
    var onClose: () -> Void

    var body: some View {
        if engine.status == .completed {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                Text("Bitti!")
                    .font(.headline)
                Button("Kapat", action: onClose)
            }
        } else {
            VStack(spacing: 4) {
                Text(engine.currentTimer?.label ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(engine.currentIndex + 1)/\(engine.totalCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: min(engine.progress, 1.0))
                        .stroke(
                            Int(ceil(engine.remaining)) <= 3 ? Color.red : Color.cyan,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: engine.progress)

                    Text(engine.remainingFormatted)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .contentTransition(.numericText())
                }
                .frame(width: 120, height: 120)

                HStack(spacing: 16) {
                    Button {
                        engine.reset()
                        onClose()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        if engine.status == .running {
                            engine.pause()
                        } else {
                            engine.resume()
                        }
                    } label: {
                        Image(systemName: engine.status == .running ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.cyan)

                    Button {
                        engine.skip()
                    } label: {
                        Image(systemName: "forward.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
