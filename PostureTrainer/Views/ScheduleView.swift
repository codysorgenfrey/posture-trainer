import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var store: PostureStore
    @State private var editingWeek: ScheduleWeek?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.scheduleWeeks) { week in
                    Section {
                        WeekCard(
                            week: week,
                            isCurrent: store.currentWeek == week.weekNumber && store.programStarted
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { editingWeek = week }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        store.deleteWeek(store.scheduleWeeks[index])
                    }
                }
                .onMove { source, destination in
                    store.moveWeek(from: source, to: destination)
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.addWeek()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingWeek) { week in
                EditWeekSheet(week: week) { updated in
                    store.updateWeek(updated)
                }
            }
        }
    }
}

// MARK: - Week Card

struct WeekCard: View {
    let week: ScheduleWeek
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Week \(week.weekNumber)")
                    .font(.headline)
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

            HStack(spacing: 20) {
                Label("\(week.minutesPerDay) min/day", systemImage: "clock")
                Label("\(week.daysPerWeek) days/wk", systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .listRowBackground(isCurrent ? Color.primary.opacity(0.08) : nil)
    }
}

// MARK: - Edit Week Sheet

struct EditWeekSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var week: ScheduleWeek
    let onSave: (ScheduleWeek) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Days Per Week") {
                    Stepper("\(week.daysPerWeek) days", value: $week.daysPerWeek, in: 1...7)
                }

                Section("Minutes Per Day") {
                    Stepper("\(week.minutesPerDay) minutes", value: $week.minutesPerDay, in: 5...180, step: 5)
                }
            }
            .navigationTitle("Week \(week.weekNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(week)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}
