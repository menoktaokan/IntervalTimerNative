import WidgetKit
import SwiftUI

struct CollectionSummary: Identifiable {
    let id = UUID()
    let title: String
    let count: String
    let total: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), collections: [
            CollectionSummary(title: "HIIT", count: "4", total: "01:20")
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(TimerEntry(date: Date(), collections: loadCollections()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        let entry = TimerEntry(date: Date(), collections: loadCollections())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }

    private func loadCollections() -> [CollectionSummary] {
        guard let defaults = UserDefaults(suiteName: "group.com.intervaltimer.shared"),
              let data = defaults.array(forKey: "widget_collections") as? [[String: String]] else {
            return [CollectionSummary(title: "HIIT", count: "4", total: "01:20")]
        }
        return data.map {
            CollectionSummary(
                title: $0["title"] ?? "",
                count: $0["count"] ?? "0",
                total: $0["total"] ?? "00:00"
            )
        }
    }
}

struct TimerEntry: TimelineEntry {
    let date: Date
    let collections: [CollectionSummary]
}

struct TimerWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.cyan)
                Text("Interval Timer")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }

            if entry.collections.isEmpty {
                Text("Koleksiyon yok")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                let limit = family == .systemSmall ? 2 : 4
                ForEach(entry.collections.prefix(limit)) { col in
                    HStack {
                        Text(col.title)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Text("\(col.count)x · \(col.total)")
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }
}

struct TimerWidget: Widget {
    let kind: String = "TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimerWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.07, green: 0.09, blue: 0.14), for: .widget)
        }
        .configurationDisplayName("Interval Timer")
        .description("Koleksiyonlarınızın özetini görün.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TimerWidget()
} timeline: {
    TimerEntry(date: .now, collections: [
        CollectionSummary(title: "HIIT", count: "4", total: "01:20"),
        CollectionSummary(title: "Pomodoro", count: "2", total: "30:00"),
    ])
}
