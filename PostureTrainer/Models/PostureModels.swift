import Foundation

// MARK: - Session Log

struct SessionLog: Identifiable, Codable {
    let id: UUID
    let date: Date
    let durationMinutes: Int
    let weekNumber: Int
    let notes: String

    init(id: UUID = UUID(), date: Date = Date(), durationMinutes: Int, weekNumber: Int, notes: String = "") {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.weekNumber = weekNumber
        self.notes = notes
    }
}

// MARK: - Schedule Week

struct ScheduleWeek: Identifiable, Codable, Equatable {
    var id: UUID
    var weekNumber: Int
    var daysPerWeek: Int
    var minutesPerDay: Int

    init(id: UUID = UUID(), weekNumber: Int, daysPerWeek: Int, minutesPerDay: Int) {
        self.id = id
        self.weekNumber = weekNumber
        self.daysPerWeek = daysPerWeek
        self.minutesPerDay = minutesPerDay
    }
}

// MARK: - Streak Info

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let totalSessions: Int
    let totalMinutes: Int
}

// MARK: - Micro Check Item

struct MicroCheckItem: Identifiable {
    let id = UUID()
    let description: String
    var isChecked: Bool = false
}
