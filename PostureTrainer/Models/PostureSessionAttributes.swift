import ActivityKit
import Foundation

struct PostureSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {}

    var targetMinutes: Int
    var startDate: Date
    var endDate: Date
}
