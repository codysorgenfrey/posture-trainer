import UserNotifications

final class NotificationManager: Sendable {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["posture-daily-reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Posture Training"
        content.body = "Time for your posture training session! 🧍"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "posture-daily-reminder", content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleMicroCheckReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["posture-micro-1", "posture-micro-2", "posture-micro-3"])

        let times: [(id: String, hour: Int)] = [
            ("posture-micro-1", 10),
            ("posture-micro-2", 14),
            ("posture-micro-3", 17)
        ]

        for time in times {
            let content = UNMutableNotificationContent()
            content.title = "Posture Check"
            content.body = "Quick scan: feet stable, sit bones engaged, ribcage stacked, shoulders down, chin tucked."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: time.id, content: content, trigger: trigger)
            center.add(request)
        }
    }

    func scheduleSessionComplete(afterSeconds seconds: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["posture-session-complete"])

        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = "Your posture training session is done. Great work! 💪"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "posture-session-complete", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelSessionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["posture-session-complete"])
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
