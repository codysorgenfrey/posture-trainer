import ActivityKit
import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var store: PostureStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase

    @State private var targetMinutes: Double = 30
    @State private var isRunning = false
    @State private var elapsedSeconds: Int = 0
    @State private var sessionStartDate: Date?
    @State private var timer: Timer?
    @State private var sessionFinished = false
    @State private var activity: Activity<PostureSessionAttributes>?

    private var targetSeconds: Int { Int(targetMinutes) * 60 }
    private var remainingSeconds: Int { max(targetSeconds - elapsedSeconds, 0) }
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(Double(elapsedSeconds) / Double(targetSeconds), 1.0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if !isRunning && !sessionFinished {
                    durationPicker
                } else if sessionFinished {
                    completedView
                } else {
                    timerView
                }
            }
            .padding()
            .navigationTitle(sessionFinished ? "Session Complete" : (isRunning ? "In Progress" : "Start Session"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isRunning {
                        Button("Close") { dismiss() }
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active, isRunning, let start = sessionStartDate {
                    elapsedSeconds = Int(Date().timeIntervalSince(start))
                    if elapsedSeconds >= targetSeconds {
                        completeSession()
                    }
                }
            }
        }
    }

    // MARK: - Duration Picker (pre-start)

    private var durationPicker: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.stand")
                .font(.system(size: 50))
                .foregroundStyle(.primary)

            Text("How long?")
                .font(.title2.bold())

            Text("\(Int(targetMinutes)) minutes")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Slider(value: $targetMinutes, in: 5...90, step: 5)
                .tint(.primary)
                .padding(.horizontal)

            if let phase = store.currentPhase {
                Text("Recommended: \(phase.sessionMinutes.lowerBound)–\(phase.sessionMinutes.upperBound) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                startSession()
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Active Timer

    private var timerView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 4) {
                    Text(timeString(remainingSeconds))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            Text("\(timeString(elapsedSeconds)) elapsed of \(Int(targetMinutes)) min")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 16) {
                Button(role: .destructive) {
                    cancelSession()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    finishEarly()
                } label: {
                    Label("Finish", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)

            Text("Great work!")
                .font(.title.bold())

            let minutes = max(elapsedSeconds / 60, 1)
            Text("\(minutes) minute\(minutes == 1 ? "" : "s") logged")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Helpers

    private func timeString(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startSession() {
        isRunning = true
        elapsedSeconds = 0
        let now = Date()
        sessionStartDate = now
        scheduleCompletionNotification()
        startLiveActivity(startDate: now)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let start = sessionStartDate else { return }
            elapsedSeconds = Int(Date().timeIntervalSince(start))
            if elapsedSeconds >= targetSeconds {
                completeSession()
            }
        }
    }

    private func completeSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        sessionFinished = true
        endLiveActivity()
        let minutes = max(elapsedSeconds / 60, 1)
        store.logSession(durationMinutes: minutes, notes: "Live session")
    }

    private func finishEarly() {
        NotificationManager.shared.cancelSessionNotification()
        completeSession()
    }

    private func cancelSession() {
        timer?.invalidate()
        timer = nil
        NotificationManager.shared.cancelSessionNotification()
        endLiveActivity()
        isRunning = false
        dismiss()
    }

    private func scheduleCompletionNotification() {
        NotificationManager.shared.scheduleSessionComplete(afterSeconds: targetSeconds)
    }

    private func startLiveActivity(startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let endDate = startDate.addingTimeInterval(TimeInterval(targetSeconds))
        let attributes = PostureSessionAttributes(
            targetMinutes: Int(targetMinutes),
            startDate: startDate,
            endDate: endDate
        )
        let state = PostureSessionAttributes.ContentState()
        let content = ActivityContent(state: state, staleDate: endDate)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    private func endLiveActivity() {
        let currentActivity = activity
        activity = nil
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
        }
    }
}
