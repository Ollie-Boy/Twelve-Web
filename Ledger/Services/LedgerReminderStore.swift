import Foundation
import UserNotifications

enum LedgerReminderStore {
    private static let enabledKey = "ledger.dailyReminder.enabled"
    private static let hourKey = "ledger.dailyReminder.hour"
    private static let minuteKey = "ledger.dailyReminder.minute"
    private static let notifId = "ledger.dailyReminder"

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
            return (0...23).contains(h) ? h : 19
        }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }

    static var minute: Int {
        get {
            let m = UserDefaults.standard.integer(forKey: minuteKey)
            return (0...59).contains(m) ? m : 30
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
        content.title = "Ledger"
        content.body = "Quick check-in: log today’s spending or income."
        content.sound = .default
        let req = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)
        try? await center.add(req)
    }
}
