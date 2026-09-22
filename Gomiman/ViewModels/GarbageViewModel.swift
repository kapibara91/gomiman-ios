import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
public final class GarbageViewModel {
    public var garbageModels: [GarbageCollectionModel] = []
    public var pushSetting: PushSettingModel = PushSettingModel()
    public var scheduleVersion: Int64 = 0

    public var timelineItems: [TimelineItem] = []
    public var todayGarbageTypes: [GarbageType] = []
    public var isCollectedToday: Bool = false

    private let preferencesManager: PreferencesManager
    private let notificationManager: NotificationManager

    public init(
        preferencesManager: PreferencesManager = .shared,
        notificationManager: NotificationManager = .shared
    ) {
        self.preferencesManager = preferencesManager
        self.notificationManager = notificationManager
    }

    public func loadData() {
        self.garbageModels = preferencesManager.getGarbageCollections()
        self.pushSetting = preferencesManager.getPushSetting()
        self.scheduleVersion = preferencesManager.getGarbageScheduleVersion()

        recalculateTimeline()

        // Reschedule local alerts
        Task {
            await notificationManager.rescheduleNotifications(
                models: garbageModels,
                pushSetting: pushSetting
            )
        }
    }

    public func recalculateTimeline() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentHour = calendar.component(.hour, from: Date())
        self.isCollectedToday = currentHour >= 9

        self.todayGarbageTypes = DateUtils.getGarbageTypes(for: today, models: garbageModels, calendar: calendar)

        var items: [TimelineItem] = []
        if !garbageModels.isEmpty {
            for dayOffset in 1...60 {
                guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let types = DateUtils.getGarbageTypes(for: futureDate, models: garbageModels, calendar: calendar)
                if !types.isEmpty {
                    items.append(TimelineItem(date: futureDate, daysAfter: dayOffset, types: types))
                }
            }
        }
        self.timelineItems = items
    }

    public func addGarbageCollection(_ model: GarbageCollectionModel) {
        var updatedList = garbageModels

        // Deduplication safety check: if an identical item already exists, do not re-insert
        let isDuplicate = updatedList.contains { existing in
            existing.weekStatus == model.weekStatus &&
            existing.weeks.sorted() == model.weeks.sorted() &&
            existing.days.sorted() == model.days.sorted() &&
            existing.garbageTypes.sorted() == model.garbageTypes.sorted()
        }
        if isDuplicate {
            return
        }

        let maxId = updatedList.compactMap { $0.id }.max() ?? 0
        let newId = maxId + 1
        let newVersion = preferencesManager.updateGarbageScheduleVersion()

        var newModel = model
        newModel.id = newId
        newModel.version = newVersion

        updatedList.append(newModel)

        preferencesManager.saveGarbageCollections(updatedList)

        self.garbageModels = updatedList
        self.scheduleVersion = newVersion

        recalculateTimeline()

        Task {
            await notificationManager.rescheduleNotifications(
                models: updatedList,
                pushSetting: pushSetting
            )
        }

        AnalyticsManager.shared.logAddGarbage(
            types: model.garbageTypes,
            isEveryWeek: model.weekStatus == GarbageCollectionModel.weekStatusEveryWeek
        )
    }

    public func deleteGarbageCollection(id: Int64) {
        let updatedList = garbageModels.filter { $0.id != id }
        let newVersion = preferencesManager.updateGarbageScheduleVersion()

        preferencesManager.saveGarbageCollections(updatedList)

        self.garbageModels = updatedList
        self.scheduleVersion = newVersion

        recalculateTimeline()

        Task {
            await notificationManager.rescheduleNotifications(
                models: updatedList,
                pushSetting: pushSetting
            )
        }

        AnalyticsManager.shared.logDeleteGarbage(id: id)
    }

    public func resetAllGarbageCollections() {
        let newVersion = preferencesManager.updateGarbageScheduleVersion()

        preferencesManager.saveGarbageCollections([])

        self.garbageModels = []
        self.scheduleVersion = newVersion

        recalculateTimeline()

        Task {
            await notificationManager.rescheduleNotifications(
                models: [],
                pushSetting: pushSetting
            )
        }

        AnalyticsManager.shared.logResetGarbage()
    }

    public func updatePushSetting(_ newSetting: PushSettingModel) {
        self.pushSetting = newSetting
        preferencesManager.savePushSetting(newSetting)
        let newVersion = preferencesManager.updateGarbageScheduleVersion()
        self.scheduleVersion = newVersion

        Task {
            await notificationManager.rescheduleNotifications(
                models: garbageModels,
                pushSetting: newSetting
            )
        }

        AnalyticsManager.shared.logUpdatePushSetting(
            dayBefore: newSetting.collectionDayBefore,
            dayBeforeHour: newSetting.getDayBeforeHour(),
            dayAfter: newSetting.collectionDayAfter,
            dayAfterHour: newSetting.getDayAfterHour()
        )
    }
}
