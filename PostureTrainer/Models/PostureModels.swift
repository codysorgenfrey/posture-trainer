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

// MARK: - Schedule Phase

struct SchedulePhase: Identifiable {
    let id: Int
    let title: String
    let weekRange: ClosedRange<Int>
    let sessionMinutes: ClosedRange<Int>
    let daysPerWeek: ClosedRange<Int>
    let tips: [String]
    let focusDescription: String
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
