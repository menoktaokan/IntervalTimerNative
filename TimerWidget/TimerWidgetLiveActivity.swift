import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Görünümü
// TimerWidgetAttributes artık Shared/TimerWidgetAttributes.swift dosyasında tanımlı.
// Bu dosya sadece görünümü (UI) içerir.

struct TimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerWidgetAttributes.self) { context in

            // MARK: Kilit Ekranı Görünümü
            if context.state.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tamamlandı!")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(context.attributes.collectionTitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .activityBackgroundTint(.black.opacity(0.85))

            } else {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.segmentLabel)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(context.state.currentIndex + 1)/\(context.state.totalCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if context.state.isPaused {
                        Text("⏸ Bekliyor")
                            .font(.title3.monospacedDigit().weight(.bold))
                            .foregroundColor(.orange)
                    } else {
                        Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                            .font(.title.monospacedDigit().weight(.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding()
                .activityBackgroundTint(.black.opacity(0.85))
            }

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.segmentLabel)
                            .font(.headline)
                        Text(context.attributes.collectionTitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text("⏸")
                            .font(.title2)
                    } else if !context.state.isCompleted {
                        Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                            .font(.title2.monospacedDigit().weight(.bold))
                            .foregroundColor(.cyan)
                            .multilineTextAlignment(.trailing)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        value: Double(context.state.currentIndex),
                        total: Double(max(context.state.totalCount, 1))
                    )
                    .tint(.cyan)
                }
            } compactLeading: {
                Text(String(context.state.segmentLabel.prefix(4)))
                    .font(.caption.weight(.semibold))
            } compactTrailing: {
                if context.state.isPaused {
                    Text("⏸")
                        .font(.caption)
                } else if !context.state.isCompleted {
                    Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                        .font(.caption.monospacedDigit().weight(.bold))
                        .multilineTextAlignment(.trailing)
                } else {
                    Text("✅")
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.cyan)
            }
        }
    }
}
