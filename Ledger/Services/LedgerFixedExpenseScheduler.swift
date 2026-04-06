import Foundation
import UserNotifications

enum LedgerFixedExpenseScheduler {
    private static let prefix = "ledger.fixed."

    static func rescheduleAll(items: [LedgerFixedExpense]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)

        let ok = await LedgerReminderStore.requestAuthorizationIfNeeded()
        guard ok else { return }

        for item in items {
            let id = prefix + item.id
            var comps = DateComponents()
            comps.day = item.dayOfMonth
            comps.hour = 9
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "Ledger: \(item.title)"
            content.body = item.note.isEmpty ? "Recurring bill reminder." : item.note
            content.sound = .default
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(req)
        }
    }
}
