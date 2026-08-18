import Foundation

struct WatchTimerItem: Identifiable {
    let id = UUID()
    var label: String
    var duration: Int
}

struct WatchCollection: Identifiable {
    let id = UUID()
    var title: String
    var timers: [WatchTimerItem]
}

extension WatchCollection {
    static let defaults: [WatchCollection] = [
        WatchCollection(title: "HIIT", timers: [
            WatchTimerItem(label: "Koşu", duration: 30),
            WatchTimerItem(label: "Dinlenme", duration: 10),
            WatchTimerItem(label: "Koşu", duration: 30),
            WatchTimerItem(label: "Dinlenme", duration: 10),
        ]),
        WatchCollection(title: "Pomodoro", timers: [
            WatchTimerItem(label: "Çalışma", duration: 1500),
            WatchTimerItem(label: "Mola", duration: 300),
        ]),
        WatchCollection(title: "Okul Ders", timers: [
            WatchTimerItem(label: "Ders", duration: 2400),
            WatchTimerItem(label: "Teneffüs", duration: 600),
        ]),
    ]
}
