import WidgetKit
import SwiftUI

// Sadece Live Activity sunulur — ana ekran widget'ı yok.
@main
struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerWidgetLiveActivity()
    }
}
