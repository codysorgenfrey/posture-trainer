import Foundation

struct Schedule {
    static let phases: [SchedulePhase] = [
        SchedulePhase(
            id: 1,
            title: "Short, Easy Intro",
            weekRange: 1...2,
            sessionMinutes: 20...30,
            daysPerWeek: 4...5,
            tips: [
                "Wear during low-intensity, mostly stationary activities",
                "Computer work, reading, or light chores at home",
                "After removing, maintain tall/open posture for 5–10 min",
                "If 30 min feels like too much, stay at 20 min"
            ],
            focusDescription: "Get used to the brace without irritation."
        ),
        SchedulePhase(
            id: 2,
            title: "Build a Solid Daily Block",
            weekRange: 3...4,
            sessionMinutes: 45...60,
            daysPerWeek: 5...5,
            tips: [
                "Keep it to a consistent window each day",
                "Example: first hour of focused work, or early evening",
                "After removing, check posture over the next hour",
                "Gently correct yourself when you notice slouching"
            ],
            focusDescription: "Give your body a clearer 'ideal posture' window each day."
        ),
        SchedulePhase(
            id: 3,
            title: "Same Length, Less Dependence",
            weekRange: 5...6,
            sessionMinutes: 45...60,
            daysPerWeek: 3...4,
            tips: [
                "Choose your 'worst posture' time (afternoon slump, long meetings)",
                "Pair with a 5–10 min strength routine after removing",
                "Rows (band or dumbbells), light shoulder work",
                "Plank or dead bug exercises",
                "Think of brace as a form teacher, not support gear"
            ],
            focusDescription: "Maintain the same block but rely more on your muscles."
        ),
        SchedulePhase(
            id: 4,
            title: "Phase Out to Occasional Use",
            weekRange: 7...8,
            sessionMinutes: 20...30,
            daysPerWeek: 2...3,
            tips: [
                "Use only when extra tired, long sit, or feeling slouchy",
                "Keep up posture checks on non-brace days",
                "Continue light strength work regularly"
            ],
            focusDescription: "Mainly use the brace as a reminder on tougher days."
        )
    ]

    static let microChecks: [String] = [
        "Feet stable, not wrapped around chair legs",
        "Hips not tucked under; sit on your sit bones",
        "Ribcage stacked over pelvis, not flared forward",
        "Shoulders gently down and back, not yanked",
        "Head over shoulders, chin slightly tucked"
    ]

    static func currentPhase(forWeek week: Int) -> SchedulePhase? {
        phases.first { $0.weekRange.contains(week) }
    }
}
