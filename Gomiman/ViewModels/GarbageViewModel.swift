import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
public final class GarbageViewModel {
    public var garbageModels: [GarbageCollectionModel] = []
    public var pushSetting: PushSettingModel = PushSettingModel()
    public var isSynced: Bool = false
    public var scheduleVersion: Int64 = 0

    public var timelineItems: [TimelineItem] = []
    public var todayGarbageTypes: [GarbageType] = []
    public var isCollectedToday: Bool = false
    public var isSyncing: Bool = false

    private let preferencesManager: PreferencesManager
    private let notificationManager: NotificationManager
    private let syncService: SyncServiceProtocol

    public init(
        preferencesManager: PreferencesManager = .shared,
        notificationManager: NotificationManager = .shared,
        syncService: SyncServiceProtocol = CloudRunSyncService.shared
    ) {
        self.preferencesManager = preferencesManager
        self.notificationManager = notificationManager
        self.syncService = syncService
    }

    public func loadData() {
        self.garbageModels = preferencesManager.getGarbageCollections()
        self.pushSetting = preferencesManager.getPushSetting()
        self.isSynced = preferencesManager.isGarbageSettingSynced()
        self.scheduleVersion = preferencesManager.getGarbageScheduleVersion()

        recalculateTimeline()

        // Reschedule local alerts
        Task {
            await notificationManager.rescheduleNotifications(
                models: garbageModels,
                pushSetting: pushSetting
            )
        }

        // Auto sync if unsynced
        if !isSynced && !garbageModels.isEmpty {
            syncWithServer()
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
        preferencesManager.setGarbageSettingSynced(false)

        self.garbageModels = updatedList
        self.scheduleVersion = newVersion
        self.isSynced = false

        recalculateTimeline()

        Task {
            await notificationManager.rescheduleNotifications(
                models: updatedList,
                pushSetting: pushSetting
            )
        }

        syncWithServer()
    }

    public func deleteGarbageCollection(id: Int64) {
        let updatedList = garbageModels.filter { $0.id != id }
        let newVersion = preferencesManager.updateGarbageScheduleVersion()

        preferencesManager.saveGarbageCollections(updatedList)
        preferencesManager.setGarbageSettingSynced(false)

        self.garbageModels = updatedList
        self.scheduleVersion = newVersion
        self.isSynced = false

        recalculateTimeline()

        Task {
            await notificationManager.rescheduleNotifications(
                models: updatedList,
                pushSetting: pushSetting
            )
        }

        syncWithServer()
    }

    public func resetAllGarbageCollections() {
        let newVersion = preferencesManager.updateGarbageScheduleVersion()

        preferencesManager.saveGarbageCollections([])
        preferencesManager.setGarbageSettingSynced(false)

        self.garbageModels = []
        self.scheduleVersion = newVersion
        self.isSynced = false

        recalculateTimeline()

        Task {
            await notificationManager.rescheduleNotifications(
                models: [],
                pushSetting: pushSetting
            )
        }

        syncWithServer()
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

        syncWithServer()
    }

    public func syncWithServer() {
        guard !isSyncing else { return }
        isSyncing = true

        let collections = self.garbageModels
        let version = self.scheduleVersion
        let setting = self.pushSetting

        Task {
            let result = await syncService.syncGarbageSetting(
                collections: collections,
                version: version,
                pushSetting: setting
            )
            isSyncing = false
            if case .success = result {
                self.isSynced = true
                self.preferencesManager.setGarbageSettingSynced(true)
            }
        }
    }
}
