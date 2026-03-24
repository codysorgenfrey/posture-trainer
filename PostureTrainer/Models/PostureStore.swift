import Foundation

class PostureStore: ObservableObject {
    @Published var sessions: [SessionLog] = []
    @Published var programStartDate: Date?
    @Published var reminderHour: Int = 9
    @Published var reminderMinute: Int = 0
    @Published var remindersEnabled: Bool = false
    @Published var microCheckRemindersEnabled: Bool = false

    private let sessionsKey = "posture_sessions"
    private let startDateKey = "posture_start_date"
    private let reminderHourKey = "posture_reminder_hour"
    private let reminderMinuteKey = "posture_reminder_minute"
    private let remindersEnabledKey = "posture_reminders_enabled"
    private let microCheckRemindersEnabledKey = "posture_micro_check_enabled"

    init() {
        load()
    }

    // MARK: - Persistence

    func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
        if let startDate = programStartDate {
            UserDefaults.standard.set(startDate.timeIntervalSince1970, forKey: startDateKey)
        }
        UserDefaults.standard.set(reminderHour, forKey: reminderHourKey)
        UserDefaults.standard.set(reminderMinute, forKey: reminderMinuteKey)
        UserDefaults.standard.set(remindersEnabled, forKey: remindersEnabledKey)
        UserDefaults.standard.set(microCheckRemindersEnabled, forKey: microCheckRemindersEnabledKey)
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([SessionLog].self, from: data) {
            sessions = decoded
        }
        let startInterval = UserDefaults.standard.double(forKey: startDateKey)
        if startInterval > 0 {
            programStartDate = Date(timeIntervalSince1970: startInterval)
        }
        reminderHour = UserDefaults.standard.object(forKey: reminderHourKey) as? Int ?? 9
        reminderMinute = UserDefaults.standard.object(forKey: reminderMinuteKey) as? Int ?? 0
        remindersEnabled = UserDefaults.standard.bool(forKey: remindersEnabledKey)
        microCheckRemindersEnabled = UserDefaults.standard.bool(forKey: microCheckRemindersEnabledKey)
    }

    // MARK: - Program Week

    var currentWeek: Int {
        guard let start = programStartDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(1, (days / 7) + 1)
    }

    var currentPhase: SchedulePhase? {
        Schedule.currentPhase(forWeek: currentWeek)
    }

    var programStarted: Bool {
        programStartDate != nil
    }

    // MARK: - Session Management

    func logSession(durationMinutes: Int, notes: String = "") {
        let session = SessionLog(
            durationMinutes: durationMinutes,
            weekNumber: max(currentWeek, 1),
            notes: notes
        )
        sessions.append(session)
        save()
    }

    func deleteSession(_ session: SessionLog) {
        sessions.removeAll { $0.id == session.id }
        save()
    }

    func startProgram() {
        programStartDate = Calendar.current.startOfDay(for: Date())
        save()
    }

    func resetProgram() {
        programStartDate = nil
        sessions = []
        save()
    }

    // MARK: - Streak Calculation

    var streakInfo: StreakInfo {
        let calendar = Calendar.current
        let sortedDates = Set(sessions.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)

        guard !sortedDates.isEmpty else {
            return StreakInfo(currentStreak: 0, longestStreak: 0, totalSessions: 0, totalMinutes: 0)
        }

        // Current streak
        var currentStreak = 0
        let today = calendar.startOfDay(for: Date())

        // Allow today or yesterday as the start
        if let first = sortedDates.first,
           calendar.dateComponents([.day], from: first, to: today).day ?? 99 <= 1 {
            currentStreak = 1
            var previousDate = first
            for date in sortedDates.dropFirst() {
                let diff = calendar.dateComponents([.day], from: date, to: previousDate).day ?? 0
                if diff == 1 {
                    currentStreak += 1
                    previousDate = date
                } else {
                    break
                }
            }
        }

        // Longest streak
        var longestStreak = 0
        var tempStreak = 1
        let ascending = sortedDates.reversed().map { $0 }
        for i in 1..<ascending.count {
            let diff = calendar.dateComponents([.day], from: ascending[i - 1], to: ascending[i]).day ?? 0
            if diff == 1 {
                tempStreak += 1
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
            }
        }
        longestStreak = max(longestStreak, tempStreak)

        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalSessions: sessions.count,
            totalMinutes: totalMinutes
        )
    }

    // MARK: - This Week Stats

    var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date()).date ?? Date()
        return sessions.filter { $0.date >= startOfWeek }.count
    }

    func sessionsForWeek(_ week: Int) -> [SessionLog] {
        sessions.filter { $0.weekNumber == week }
    }
}
