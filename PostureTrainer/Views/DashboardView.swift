import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: PostureStore
    @State private var showingLogSheet = false
    @State private var showingMicroChecks = false
    @State private var showingActiveSession = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !store.programStarted {
                        startProgramCard
                    } else {
                        currentWeekCard
                        streakCard
                        weekProgressCard
                        quickActionsCard
                    }
                }
                .padding()
            }
            .navigationTitle("Posture Trainer")
            .sheet(isPresented: $showingLogSheet) {
                LogSessionSheet()
            }
            .sheet(isPresented: $showingMicroChecks) {
                MicroCheckSheet()
            }
            .fullScreenCover(isPresented: $showingActiveSession) {
                ActiveSessionView()
            }
        }
    }

    // MARK: - Start Program

    private var startProgramCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.stand")
                .font(.system(size: 60))
                .foregroundStyle(.primary)

            Text("Welcome to Posture Trainer")
                .font(.title2.bold())

            Text("A customizable program to improve your posture using a posture brace, with gradual progression from daily use to occasional reminders.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                store.startProgram()
            } label: {
                Text("Start Program")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Current Week

    private var currentWeekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if store.currentScheduleWeek != nil {
                        Text("Week \(store.currentWeek) of \(store.scheduleWeeks.count)")
                            .font(.title3.bold())
                    } else {
                        Text("Program Complete! 🎉")
                            .font(.title3.bold())
                    }
                }
                Spacer()
                Image(systemName: "figure.stand")
                    .font(.title)
                    .foregroundStyle(.primary)
            }

            if let week = store.currentScheduleWeek {
                Divider()

                HStack(spacing: 24) {
                    VStack {
                        Text("\(week.minutesPerDay)")
                            .font(.headline)
                        Text("min/day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(week.daysPerWeek)")
                            .font(.headline)
                        Text("days/week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak

    private var streakCard: some View {
        let info = store.streakInfo
        return HStack(spacing: 16) {
            streakStat(value: "\(info.currentStreak)", label: "Current\nStreak", icon: "flame.fill", color: .orange)
            streakStat(value: "\(info.longestStreak)", label: "Longest\nStreak", icon: "trophy.fill", color: .yellow)
            streakStat(value: "\(info.totalSessions)", label: "Total\nSessions", icon: "checkmark.circle.fill", color: .green)
            streakStat(value: "\(info.totalMinutes)", label: "Total\nMinutes", icon: "clock.fill", color: .blue)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func streakStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Week Progress

    private var weekProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                if let week = store.currentScheduleWeek {
                    Text("\(store.sessionsThisWeek) / \(week.daysPerWeek) sessions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let week = store.currentScheduleWeek {
                let target = Double(week.daysPerWeek)
                let progress = min(Double(store.sessionsThisWeek) / max(target, 1), 1.0)
                ProgressView(value: progress)
                    .tint(.primary)
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick Actions

    private var quickActionsCard: some View {
        VStack(spacing: 12) {
            Button {
                showingActiveSession = true
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack(spacing: 12) {
                Button {
                    showingLogSheet = true
                } label: {
                    Label("Log Past", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.secondary.opacity(0.15))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    showingMicroChecks = true
                } label: {
                    Label("Micro-Check", systemImage: "checklist")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.secondary.opacity(0.15))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}
