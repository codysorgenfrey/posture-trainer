import SwiftUI

struct MicroCheckSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var checks: [MicroCheckItem] = Schedule.microChecks.map {
        MicroCheckItem(description: $0)
    }

    private var allChecked: Bool {
        checks.allSatisfy(\.isChecked)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        ForEach($checks) { $item in
                            Button {
                                item.isChecked.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isChecked ? .green : .secondary)
                                        .font(.title3)
                                    Text(item.description)
                                        .foregroundStyle(.primary)
                                        .strikethrough(item.isChecked, color: .secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Quick posture scan")
                    } footer: {
                        Text("Do this a few times per day, with or without the brace.")
                    }
                }

                if allChecked {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("Great posture! ✓")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green.opacity(0.1))
                }
            }
            .navigationTitle("Micro-Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
