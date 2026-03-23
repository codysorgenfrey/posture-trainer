import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var store: PostureStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(Schedule.phases) { phase in
                    Section {
                        PhaseCard(phase: phase, isCurrent: store.currentPhase?.id == phase.id)
                    }
                }

                Section("Daily Micro-Checks") {
                    ForEach(Schedule.microChecks, id: \.self) { check in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.diamond")
                                .foregroundStyle(.primary)
                                .font(.caption)
                                .padding(.top, 2)
                            Text(check)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
        }
    }
}

struct PhaseCard: View {
    let phase: SchedulePhase
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weeks \(phase.weekRange.lowerBound)–\(phase.weekRange.upperBound)")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                    Text(phase.title)
                        .font(.headline)
                }
                Spacer()
                if isCurrent {
                    Text("CURRENT")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary)
                        .foregroundStyle(Color(.systemBackground))
                        .clipShape(Capsule())
                }
            }

            Text(phase.focusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                Label("\(phase.sessionMinutes.lowerBound)–\(phase.sessionMinutes.upperBound) min", systemImage: "clock")
                Label("\(phase.daysPerWeek.lowerBound)–\(phase.daysPerWeek.upperBound) days/wk", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Tips")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                ForEach(phase.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.primary)
                        Text(tip)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(isCurrent ? Color.primary.opacity(0.08) : nil)
    }
}
