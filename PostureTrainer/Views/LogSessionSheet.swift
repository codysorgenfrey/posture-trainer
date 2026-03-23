import SwiftUI

struct LogSessionSheet: View {
    @EnvironmentObject var store: PostureStore
    @Environment(\.dismiss) var dismiss
    @State private var duration: Double = 30
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration: \(Int(duration)) minutes")
                            .font(.headline)
                        Slider(value: $duration, in: 5...90, step: 5)
                            .tint(.primary)
                    }
                    .padding(.vertical, 4)

                    if let phase = store.currentPhase {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("Recommended: \(phase.sessionMinutes.lowerBound)–\(phase.sessionMinutes.upperBound) min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes (optional)") {
                    TextField("How did it feel?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.logSession(durationMinutes: Int(duration), notes: notes)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
