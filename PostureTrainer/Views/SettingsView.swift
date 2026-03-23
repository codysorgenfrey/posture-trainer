import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: PostureStore
    @State private var showingResetAlert = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Reminder") {
                    Toggle("Enable Reminder", isOn: $store.remindersEnabled)
                        .onChange(of: store.remindersEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.scheduleDailyReminder(
                                    hour: store.reminderHour,
                                    minute: store.reminderMinute
                                )
                            } else {
                                NotificationManager.shared.cancelAllReminders()
                            }
                            store.save()
                        }

                    if store.remindersEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: reminderTime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            store.reminderHour = components.hour ?? 9
                            store.reminderMinute = components.minute ?? 0
                            NotificationManager.shared.scheduleDailyReminder(
                                hour: store.reminderHour,
                                minute: store.reminderMinute
                            )
                            store.save()
                        }
                    }
                }

                Section("Micro-Check Reminders") {
                    Button {
                        NotificationManager.shared.scheduleMicroCheckReminders()
                    } label: {
                        Label("Enable Posture Check Reminders", systemImage: "bell.badge")
                    }

                    Text("Sends gentle reminders at 10 AM, 2 PM, and 5 PM to check your posture.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Program") {
                    if let start = store.programStartDate {
                        HStack {
                            Text("Started")
                            Spacer()
                            Text(start, style: .date)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Current Week")
                            Spacer()
                            Text("\(store.currentWeek)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset Program", systemImage: "arrow.counterclockwise")
                    }
                }

                Section("Stats") {
                    let info = store.streakInfo
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(info.totalSessions)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Total Minutes")
                        Spacer()
                        Text("\(info.totalMinutes)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(info.currentStreak) days")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Longest Streak")
                        Spacer()
                        Text("\(info.longestStreak) days")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Program?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetProgram()
                }
            } message: {
                Text("This will delete all sessions and reset your program start date. This cannot be undone.")
            }
            .onAppear {
                var components = DateComponents()
                components.hour = store.reminderHour
                components.minute = store.reminderMinute
                reminderTime = Calendar.current.date(from: components) ?? Date()
            }
        }
    }
}
