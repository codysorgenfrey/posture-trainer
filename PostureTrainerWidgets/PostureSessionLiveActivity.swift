import ActivityKit
import SwiftUI
import WidgetKit

struct PostureSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PostureSessionAttributes.self) { context in
            // Lock Screen / Notification Banner
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "figure.stand")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Posture Session")
                            .font(.headline)
                        Text("\(context.attributes.targetMinutes) min goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: true)
                        .font(.system(.title, design: .rounded).bold())
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                ProgressView(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: false)
                    .tint(.primary)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "figure.stand")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Posture Session")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: true)
                        .font(.system(.title2, design: .rounded).bold())
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: false)
                        .tint(.primary)
                }
            } compactLeading: {
                Image(systemName: "figure.stand")
            } compactTrailing: {
                Text(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 56)
            } minimal: {
                Image(systemName: "figure.stand")
            }
        }
    }
}
