import Foundation

class PostureStore: ObservableObject {
    @Published var sessions: [SessionLog] = []
    @Published var programStartDate: Date?
    @Published var currentWeek: Int = 0 {
        didSet { save() }
    }
    @Published var reminderHour: Int = 9
    @Published var reminderMinute: Int = 0
    @Published var remindersEnabled: Bool = false
    @Published var microCheckRemindersEnabled: Bool = false
    @Published var scheduleWeeks: [ScheduleWeek] = Schedule.defaultWeeks

    private let sessionsKey = "posture_sessions"
    private let startDateKey = "posture_start_date"
    private let currentWeekKey = "posture_current_week"
    private let reminderHourKey = "posture_reminder_hour"
    private let reminderMinuteKey = "posture_reminder_minute"
    private let remindersEnabledKey = "posture_reminders_enabled"
    private let microCheckRemindersEnabledKey = "posture_micro_check_enabled"
    private let scheduleWeeksKey = "posture_schedule_weeks"
    private var isLoading = false

    init() {
        load()
    }

    // MARK: - Persistence

    func save() {
        guard !isLoading else { return }
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
        if let startDate = programStartDate {
            UserDefaults.standard.set(startDate.timeIntervalSince1970, forKey: startDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: startDateKey)
        }
        UserDefaults.standard.set(currentWeek, forKey: currentWeekKey)
        UserDefaults.standard.set(reminderHour, forKey: reminderHourKey)
        UserDefaults.standard.set(reminderMinute, forKey: reminderMinuteKey)
        UserDefaults.standard.set(remindersEnabled, forKey: remindersEnabledKey)
        UserDefaults.standard.set(microCheckRemindersEnabled, forKey: microCheckRemindersEnabledKey)
        if let data = try? JSONEncoder().encode(scheduleWeeks) {
            UserDefaults.standard.set(data, forKey: scheduleWeeksKey)
        }
    }

    func load() {
        isLoading = true
        defer {
            isLoading = false
            refreshCurrentWeekIfNeeded()
        }
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([SessionLog].self, from: data) {
            sessions = decoded
        }
        let startInterval = UserDefaults.standard.double(forKey: startDateKey)
        if startInterval > 0 {
            programStartDate = Date(timeIntervalSince1970: startInterval)
        }
        if let storedWeek = UserDefaults.standard.object(forKey: currentWeekKey) as? Int {
            currentWeek = storedWeek
        } else if let start = programStartDate {
            // Migrate from previous date-derived value.
            let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
            currentWeek = max(1, (days / 7) + 1)
        }
        reminderHour = UserDefaults.standard.object(forKey: reminderHourKey) as? Int ?? 9
        reminderMinute = UserDefaults.standard.object(forKey: reminderMinuteKey) as? Int ?? 0
        remindersEnabled = UserDefaults.standard.bool(forKey: remindersEnabledKey)
        microCheckRemindersEnabled = UserDefaults.standard.bool(forKey: microCheckRemindersEnabledKey)
        if let data = UserDefaults.standard.data(forKey: scheduleWeeksKey),
           let decoded = try? JSONDecoder().decode([ScheduleWeek].self, from: data) {
            scheduleWeeks = decoded
        }
    }

    // MARK: - Program Week

    var currentScheduleWeek: ScheduleWeek? {
        scheduleWeeks.first { $0.weekNumber == currentWeek }
    }

    /// Week the user is expected to be on based on the program start date.
    /// Returns nil if the program hasn't started.
    var expectedWeekFromStartDate: Int? {
        guard let start = programStartDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        return max(1, (days / 7) + 1)
    }

    /// Auto-advance `currentWeek` to match the program start date when the
    /// calendar has rolled into a new program week (e.g. on Monday). Only
    /// advances forward, never backward, so manual jumps ahead are preserved.
    func refreshCurrentWeekIfNeeded() {
        guard let expected = expectedWeekFromStartDate else { return }
        let maxWeek = scheduleWeeks.map(\.weekNumber).max() ?? expected
        let target = min(expected, maxWeek)
        if target > currentWeek {
            currentWeek = target
        }
    }

    func scheduleWeek(forWeek week: Int) -> ScheduleWeek? {
        scheduleWeeks.first { $0.weekNumber == week }
    }

    var programStarted: Bool {
        programStartDate != nil
    }

    // MARK: - Session Management

    func logSession(durationMinutes: Int, date: Date = Date(), notes: String = "") {
        let session = SessionLog(
            date: date,
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
        currentWeek = 1
        save()
    }

    func resetProgram() {
        programStartDate = nil
        currentWeek = 0
        sessions = []
        save()
    }

    func updateSessionWeek(_ session: SessionLog, weekNumber: Int) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].weekNumber = weekNumber
        save()
    }

    func updateSession(_ session: SessionLog) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index] = session
        save()
    }

    // MARK: - Schedule Management

    func addWeek() {
        let nextWeekNumber = (scheduleWeeks.map(\.weekNumber).max() ?? 0) + 1
        let newWeek = ScheduleWeek(weekNumber: nextWeekNumber, daysPerWeek: 3, minutesPerDay: 30)
        scheduleWeeks.append(newWeek)
        save()
    }

    func deleteWeek(_ week: ScheduleWeek) {
        scheduleWeeks.removeAll { $0.id == week.id }
        renumberWeeks()
        save()
    }

    func updateWeek(_ week: ScheduleWeek) {
        if let index = scheduleWeeks.firstIndex(where: { $0.id == week.id }) {
            scheduleWeeks[index] = week
            save()
        }
    }

    func moveWeek(from source: IndexSet, to destination: Int) {
        scheduleWeeks.move(fromOffsets: source, toOffset: destination)
        renumberWeeks()
        save()
    }

    func resetScheduleToDefault() {
        scheduleWeeks = Schedule.defaultWeeks
        save()
    }

    private func renumberWeeks() {
        for i in scheduleWeeks.indices {
            scheduleWeeks[i].weekNumber = i + 1
        }
    }

    // MARK: - Streak Calculation

    /// Maximum allowed gap (in days) between sessions, based on the schedule
    /// week that was active on `date`. Computed from `programStartDate` so it
    /// reflects the actual schedule on that calendar day rather than the
    /// stamped week number on a session (which can drift if the user changes
    /// the current week manually).
    private func maxAllowedGap(forDate date: Date) -> Int {
        guard let start = programStartDate else { return 1 }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        let week = max(1, (days / 7) + 1)
        if let scheduleWeek = scheduleWeek(forWeek: week) {
            // e.g. 5 days/week → max gap 3, 3 days/week → max gap 5
            return 7 - scheduleWeek.daysPerWeek + 1
        }
        return 1 // No active week: require consecutive days
    }

    var streakInfo: StreakInfo {
        let calendar = Calendar.current

        // Collapse to one entry per calendar day.
        let sortedDates = Set(sessions.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)

        guard !sortedDates.isEmpty else {
            return StreakInfo(currentStreak: 0, longestStreak: 0, totalSessions: 0, totalMinutes: 0)
        }

        // Current streak
        var currentStreak = 0
        let today = calendar.startOfDay(for: Date())

        // Allow the most recent session to be within today's allowed gap.
        // Use today's schedule week so that progressing into a stricter or
        // more lenient week doesn't retroactively break the streak.
        if let first = sortedDates.first,
           calendar.dateComponents([.day], from: first, to: today).day ?? 99 <= maxAllowedGap(forDate: today) {
            currentStreak = 1
            var previousDate = first
            for date in sortedDates.dropFirst() {
                let diff = calendar.dateComponents([.day], from: date, to: previousDate).day ?? 0
                let allowedGap = maxAllowedGap(forDate: date)
                if diff <= allowedGap {
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
            let allowedGap = maxAllowedGap(forDate: ascending[i - 1])
            if diff <= allowedGap {
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

    var hasSessionToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions.contains { calendar.startOfDay(for: $0.date) == today }
    }

    /// Whether the user's schedule expects a session today and they haven't done one yet.
    var isSessionDueToday: Bool {
        guard programStarted, !hasSessionToday else { return false }
        guard let week = currentScheduleWeek else { return false }
        // If they still have remaining sessions to hit this week's target, it's a session day.
        return sessionsThisWeek < week.daysPerWeek
    }

    func sessionsForWeek(_ week: Int) -> [SessionLog] {
        sessions.filter { $0.weekNumber == week }
    }
}
