import Foundation
import UserNotifications

public final class NotificationManager: @unchecked Sendable {
    public static let shared = NotificationManager()

    public static let categoryIdentifier = "GOMIMAN_REMINDER"

    private let center = UNUserNotificationCenter.current()

    public init() {}

    // MARK: - Permission

    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Local Notifications

    public func rescheduleNotifications(
        models: [GarbageCollectionModel],
        pushSetting: PushSettingModel
    ) async {
        // Clear previously scheduled notifications
        center.removeAllPendingNotificationRequests()

        guard !models.isEmpty else { return }
        guard pushSetting.collectionDayBefore || pushSetting.collectionDayAfter else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Schedule upcoming 30 days
        for dayOffset in 0..<30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let types = DateUtils.getGarbageTypes(for: targetDate, models: models, calendar: calendar)
            guard !types.isEmpty else { continue }

            let typesStr = types.map { "【\($0.typeName)】" }.joined(separator: " ")

            // 1. Day Before Notification
            if pushSetting.collectionDayBefore {
                guard let notificationDate = calendar.date(byAdding: .day, value: -1, to: targetDate) else { continue }
                let hour = pushSetting.getDayBeforeHour()

                var components = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                components.hour = hour
                components.minute = 0
                components.second = 0

                if let triggerDate = calendar.date(from: components), triggerDate > Date() {
                    let content = UNMutableNotificationContent()
                    content.title = "明日はゴミの収集日です"
                    content.body = "明日は \(typesStr) の収集日です。準備をお忘れなく！"
                    content.sound = .default
                    content.categoryIdentifier = Self.categoryIdentifier

                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "gomiman_before_\(dayOffset)_\(hour)",
                        content: content,
                        trigger: trigger
                    )
                    try? await center.add(request)
                }
            }

            // 2. Day Of (After) Notification
            if pushSetting.collectionDayAfter {
                let hour = pushSetting.getDayAfterHour()

                var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                components.hour = hour
                components.minute = 0
                components.second = 0

                if let triggerDate = calendar.date(from: components), triggerDate > Date() {
                    let content = UNMutableNotificationContent()
                    content.title = "今日はゴミの収集日です"
                    content.body = "本日は \(typesStr) の収集日です。"
                    content.sound = .default
                    content.categoryIdentifier = Self.categoryIdentifier

                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "gomiman_day_\(dayOffset)_\(hour)",
                        content: content,
                        trigger: trigger
                    )
                    try? await center.add(request)
                }
            }
        }
    }
}
