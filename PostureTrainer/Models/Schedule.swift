import Foundation

struct Schedule {
    static let defaultWeeks: [ScheduleWeek] = [
        ScheduleWeek(weekNumber: 1, daysPerWeek: 4, minutesPerDay: 20),
        ScheduleWeek(weekNumber: 2, daysPerWeek: 5, minutesPerDay: 30),
        ScheduleWeek(weekNumber: 3, daysPerWeek: 5, minutesPerDay: 45),
        ScheduleWeek(weekNumber: 4, daysPerWeek: 5, minutesPerDay: 60),
        ScheduleWeek(weekNumber: 5, daysPerWeek: 4, minutesPerDay: 45),
        ScheduleWeek(weekNumber: 6, daysPerWeek: 3, minutesPerDay: 60),
        ScheduleWeek(weekNumber: 7, daysPerWeek: 3, minutesPerDay: 25),
        ScheduleWeek(weekNumber: 8, daysPerWeek: 2, minutesPerDay: 20),
    ]

    static let microChecks: [String] = [
        "Feet stable, not wrapped around chair legs",
        "Hips not tucked under; sit on your sit bones",
        "Ribcage stacked over pelvis, not flared forward",
        "Shoulders gently down and back, not yanked",
        "Head over shoulders, chin slightly tucked"
    ]
}
