//
//  TimerWidgetBundle.swift
//  TimerWidget
//
//  Created by Mehmet Okan YILMAZ on 29.06.2026.
//

import WidgetKit
import SwiftUI

@main
struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()
        TimerWidgetLiveActivity()
    }
}
