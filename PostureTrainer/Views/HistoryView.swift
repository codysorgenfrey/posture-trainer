import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: PostureStore

    private var groupedSessions: [(String, [SessionLog])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: store.sessions.sorted(by: { $0.date > $1.date })) {
            formatter.string(from: $0.date)
        }

        return grouped.sorted { a, b in
            guard let dateA = a.1.first?.date, let dateB = b.1.first?.date else { return false }
            return dateA > dateB
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Yet",
                        systemImage: "figure.stand",
                        description: Text("Log your first posture training session from the Today tab.")
                    )
                } else {
                    List {
                        ForEach(groupedSessions, id: \.0) { month, sessions in
                            Section(month) {
                                ForEach(sessions) { session in
                                    SessionRow(session: session)
                                }
                                .onDelete { offsets in
                                    for offset in offsets {
                                        store.deleteSession(sessions[offset])
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct SessionRow: View {
    @EnvironmentObject var store: PostureStore
    let session: SessionLog
    @State private var isEditing = false

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var body: some View {
        Button {
            isEditing = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dateFormatted)
                        .font(.subheadline.bold())
                    Spacer()
                    Text("Week \(session.weekNumber)")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack {
                    Label("\(session.durationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isEditing) {
            EditSessionSheet(session: session)
        }
    }
}

struct EditSessionSheet: View {
    @EnvironmentObject var store: PostureStore
    @Environment(\.dismiss) var dismiss

    let session: SessionLog

    @State private var sessionDate: Date
    @State private var duration: Double
    @State private var weekNumber: Int
    @State private var notes: String

    init(session: SessionLog) {
        self.session = session
        _sessionDate = State(initialValue: session.date)
        _duration = State(initialValue: Double(session.durationMinutes))
        _weekNumber = State(initialValue: session.weekNumber)
        _notes = State(initialValue: session.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $sessionDate, in: ...Date(), displayedComponents: [.date])

                    Picker("Week", selection: $weekNumber) {
                        ForEach(store.scheduleWeeks, id: \.weekNumber) { week in
                            Text("Week \(week.weekNumber)").tag(week.weekNumber)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration: \(Int(duration)) minutes")
                            .font(.headline)
                        Slider(value: $duration, in: 5...90, step: 5)
                            .tint(.primary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("How did it feel?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button(role: .destructive) {
                        store.deleteSession(session)
                        dismiss()
                    } label: {
                        Label("Delete Session", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = session
                        updated.date = sessionDate
                        updated.durationMinutes = Int(duration)
                        updated.weekNumber = weekNumber
                        updated.notes = notes
                        store.updateSession(updated)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
