import Foundation
import UserNotifications
import BackgroundTasks

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = NotificationManager()

    public static let categoryIdentifier = "GOMIMAN_REMINDER"
    public static let backgroundTaskIdentifier = "co.jp.bms.gomiman.refresh"

    private let center = UNUserNotificationCenter.current()

    public override init() {
        super.init()
    }

    public func configure() {
        center.delegate = self
    }

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

    // MARK: - Foreground Presentation & Tap Delegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        #if DEBUG
        print("[NotificationManager] Foreground notification received: \(notification.request.content.title)")
        #endif
        completionHandler([.banner, .badge, .sound])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        #if DEBUG
        print("[NotificationManager] User opened notification: \(response.notification.request.content.title)")
        #endif
        completionHandler()
    }

    // MARK: - Background App Refresh

    public func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self?.handleAppRefresh(task: refreshTask)
        }
    }

    public func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        // Earliest begin date: 7 days later
        request.earliestBeginDate = Date(timeIntervalSinceNow: 7 * 24 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("[NotificationManager] Successfully submitted BGAppRefreshTask")
            #endif
        } catch {
            #if DEBUG
            print("[NotificationManager] Failed to submit BGAppRefreshTask: \(error.localizedDescription)")
            #endif
        }
    }

    private final class UncheckedTaskBox: @unchecked Sendable {
        let task: BGAppRefreshTask
        init(_ task: BGAppRefreshTask) {
            self.task = task
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Reschedule next background refresh
        scheduleAppRefresh()

        let taskBox = UncheckedTaskBox(task)

        task.expirationHandler = {
            #if DEBUG
            print("[NotificationManager] BGAppRefreshTask expired before completion")
            #endif
        }

        Task {
            let models = PreferencesManager.shared.getGarbageCollections()
            let setting = PreferencesManager.shared.getPushSetting()
            await rescheduleNotifications(models: models, pushSetting: setting)
            taskBox.task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Schedule Local Notifications (Hybrid: Repeating + Specific)

    public func rescheduleNotifications(
        models: [GarbageCollectionModel],
        pushSetting: PushSettingModel
    ) async {
        // Clear previously scheduled notifications
        center.removeAllPendingNotificationRequests()

        guard !models.isEmpty else { return }
        guard pushSetting.collectionDayBefore || pushSetting.collectionDayAfter else { return }

        var scheduledCount = 0

        // Step 1: Classify each ISO weekday (1: Mon ... 7: Sun)
        // If all models on that weekday are EveryWeek, we can schedule weekly repeating notifications (repeats: true).
        // If any model on that weekday is Biweekly (specific weeks), we schedule specific dates (repeats: false).
        var isWeekdayEveryWeekOnly: [Int: Bool] = [:]
        for day in 1...7 {
            let dayModels = models.filter { $0.days.contains(day) }
            if dayModels.isEmpty {
                isWeekdayEveryWeekOnly[day] = false
            } else {
                let hasBiweekly = dayModels.contains { $0.weekStatus == GarbageCollectionModel.weekStatusBiweekly }
                isWeekdayEveryWeekOnly[day] = !hasBiweekly
            }
        }

        // Step 2: Schedule repeating weekly notifications for EveryWeek-only weekdays
        for day in 1...7 where isWeekdayEveryWeekOnly[day] == true {
            let dayModels = models.filter { $0.days.contains(day) }
            var typeIds = Set<Int>()
            var types: [GarbageType] = []
            for model in dayModels {
                for tid in model.garbageTypes {
                    if !typeIds.contains(tid), let type = GarbageType.from(id: tid) {
                        typeIds.insert(tid)
                        types.append(type)
                    }
                }
            }
            guard !types.isEmpty else { continue }
            types.sort { $0.id < $1.id }
            let typesStr = types.map { "【\($0.typeName)】" }.joined(separator: " ")

            // Apple Calendar weekday: 1 is Sunday, 2 is Monday, ..., 7 is Saturday
            let appleDayOfWeekday = (day % 7) + 1

            // 1. Day Before (repeats: true)
            if pushSetting.collectionDayBefore && scheduledCount < 60 {
                let dayBeforeIso = day == 1 ? 7 : day - 1
                let appleDayBeforeWeekday = (dayBeforeIso % 7) + 1
                let hour = pushSetting.getDayBeforeHour()

                var components = DateComponents()
                components.weekday = appleDayBeforeWeekday
                components.hour = hour
                components.minute = 0
                components.second = 0

                let content = UNMutableNotificationContent()
                content.title = "明日はゴミの収集日です"
                content.body = "明日は \(typesStr) の収集日です。準備をお忘れなく！"
                content.sound = .default
                content.categoryIdentifier = Self.categoryIdentifier

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "gomiman_repeating_before_\(day)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
                scheduledCount += 1
            }

            // 2. Day Of (repeats: true)
            if pushSetting.collectionDayAfter && scheduledCount < 60 {
                let hour = pushSetting.getDayAfterHour()

                var components = DateComponents()
                components.weekday = appleDayOfWeekday
                components.hour = hour
                components.minute = 0
                components.second = 0

                let content = UNMutableNotificationContent()
                content.title = "今日はゴミの収集日です"
                content.body = "本日は \(typesStr) の収集日です。"
                content.sound = .default
                content.categoryIdentifier = Self.categoryIdentifier

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "gomiman_repeating_day_\(day)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
                scheduledCount += 1
            }
        }

        // Step 3: For weekdays with biweekly rules, schedule specific dates (repeats: false) for the upcoming 45 days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<45 {
            guard scheduledCount < 60 else { break }
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let isoWeekday = DateUtils.isoWeekday(for: targetDate, calendar: calendar)

            // Skip weekdays that are already fully handled by weekly repeating notifications
            if isWeekdayEveryWeekOnly[isoWeekday] == true {
                continue
            }

            let types = DateUtils.getGarbageTypes(for: targetDate, models: models, calendar: calendar)
            guard !types.isEmpty else { continue }

            let typesStr = types.map { "【\($0.typeName)】" }.joined(separator: " ")

            // 1. Day Before Notification
            if pushSetting.collectionDayBefore && scheduledCount < 60 {
                guard let notificationDate = calendar.date(byAdding: .day, value: -1, to: targetDate) else { continue }
                let hour = pushSetting.getDayBeforeHour()

                var components = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                components.hour = hour
                components.minute = 0
                components.second = 0

                if let triggerDate = calendar.date(from: components), triggerDate > Date() {
                    let content = UNMutableNotificationContent()
                    content.title = "明日はゴミの収集日です"
                    content.body = "明日は \(typesStr) の収集日です。准备をお忘れなく！"
                    content.sound = .default
                    content.categoryIdentifier = Self.categoryIdentifier

                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "gomiman_specific_before_\(dayOffset)_\(hour)",
                        content: content,
                        trigger: trigger
                    )
                    try? await center.add(request)
                    scheduledCount += 1
                }
            }

            // 2. Day Of Notification
            if pushSetting.collectionDayAfter && scheduledCount < 60 {
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
                        identifier: "gomiman_specific_day_\(dayOffset)_\(hour)",
                        content: content,
                        trigger: trigger
                    )
                    try? await center.add(request)
                    scheduledCount += 1
                }
            }
        }

        #if DEBUG
        print("[NotificationManager] Rescheduled notifications completed. Total scheduled requests: \(scheduledCount)")
        #endif
    }
}
