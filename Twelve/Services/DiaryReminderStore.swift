import Foundation
import UserNotifications

enum DiaryReminderStore {
    private static let enabledKey = "twelve.diaryReminder.enabled"
    private static let hourKey = "twelve.diaryReminder.hour"
    private static let minuteKey = "twelve.diaryReminder.minute"
    private static let notifId = "twelve.diaryReminder.daily"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if newValue {
                Task { await schedule() }
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifId])
            }
        }
    }

    static var hour: Int {
        get {
            let h = UserDefaults.standard.integer(forKey: hourKey)
            return (0...23).contains(h) ? h : 20
        }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }

    static var minute: Int {
        get {
            let m = UserDefaults.standard.integer(forKey: minuteKey)
            return (0...59).contains(m) ? m : 0
        }
        set { UserDefaults.standard.set(newValue, forKey: minuteKey) }
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    @MainActor
    static func schedule() async {
        let ok = await requestAuthorizationIfNeeded()
        guard ok else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notifId])
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Twelve"
        content.body = "A gentle moment to jot a line in your diary."
        content.sound = .default
        let req = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)
        try? await center.add(req)
    }
}
