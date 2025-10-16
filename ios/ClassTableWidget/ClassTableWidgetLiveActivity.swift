//
//  ClassTableWidgetLiveActivity.swift
//  ClassTableWidget
//
//  Created by 韩沛霖 on 2025/10/16.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ClassTableWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ClassTableWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClassTableWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ClassTableWidgetAttributes {
    fileprivate static var preview: ClassTableWidgetAttributes {
        ClassTableWidgetAttributes(name: "World")
    }
}

extension ClassTableWidgetAttributes.ContentState {
    fileprivate static var smiley: ClassTableWidgetAttributes.ContentState {
        ClassTableWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ClassTableWidgetAttributes.ContentState {
         ClassTableWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ClassTableWidgetAttributes.preview) {
   ClassTableWidgetLiveActivity()
} contentStates: {
    ClassTableWidgetAttributes.ContentState.smiley
    ClassTableWidgetAttributes.ContentState.starEyes
}
