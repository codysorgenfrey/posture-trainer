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
    let session: SessionLog

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var body: some View {
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
    }
}
