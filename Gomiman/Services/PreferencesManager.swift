import Foundation

public final class PreferencesManager: @unchecked Sendable {
    public static let shared = PreferencesManager()

    private let userDefaults: UserDefaults

    private enum Keys {
        static let dayBefore = "_collectionDayBeforeKey"
        static let timeDayBefore = "_selectedTimeDayBeforeKey"
        static let dayAfter = "_collectionDayAfterKey"
        static let timeDayAfter = "_selectedTimeDayAfterKey"
        static let firstTimeAdded = "_firstTimeAddedGarbageKey"
        static let garbageCollectionsJson = "_garbageCollectionsJsonKey"
        static let garbageScheduleVersion = "_garbageScheduleVersionKey"
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Push / Reminder Settings

    public func getPushSetting() -> PushSettingModel {
        let dayBefore = userDefaults.object(forKey: Keys.dayBefore) as? Bool ?? true
        let timeDayBefore = userDefaults.object(forKey: Keys.timeDayBefore) as? Int ?? 1
        let dayAfter = userDefaults.object(forKey: Keys.dayAfter) as? Bool ?? false
        let timeDayAfter = userDefaults.object(forKey: Keys.timeDayAfter) as? Int ?? 0
        return PushSettingModel(
            collectionDayBefore: dayBefore,
            selectedTimeDayBefore: timeDayBefore,
            collectionDayAfter: dayAfter,
            selectedTimeDayAfter: timeDayAfter
        )
    }

    public func savePushSetting(_ setting: PushSettingModel) {
        userDefaults.set(setting.collectionDayBefore, forKey: Keys.dayBefore)
        userDefaults.set(setting.selectedTimeDayBefore, forKey: Keys.timeDayBefore)
        userDefaults.set(setting.collectionDayAfter, forKey: Keys.dayAfter)
        userDefaults.set(setting.selectedTimeDayAfter, forKey: Keys.timeDayAfter)
    }

    // MARK: - First Time Added

    public func isFirstTimeAddedGarbage() -> Bool {
        return userDefaults.string(forKey: Keys.firstTimeAdded) == nil
    }

    public func markFirstTimeAddedGarbage() {
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))
        userDefaults.set(timestamp, forKey: Keys.firstTimeAdded)
    }

    // MARK: - Garbage Collections Persistence

    public func getGarbageCollections() -> [GarbageCollectionModel] {
        guard let jsonString = userDefaults.string(forKey: Keys.garbageCollectionsJson),
              let data = jsonString.data(using: .utf8) else {
            return []
        }
        do {
            return try JSONDecoder().decode([GarbageCollectionModel].self, from: data)
        } catch {
            return []
        }
    }

    public func saveGarbageCollections(_ collections: [GarbageCollectionModel]) {
        do {
            let data = try JSONEncoder().encode(collections)
            if let jsonString = String(data: data, encoding: .utf8) {
                userDefaults.set(jsonString, forKey: Keys.garbageCollectionsJson)
            }
        } catch {
            // Silently ignore or log error
        }
    }

    // MARK: - Version

    public func getGarbageScheduleVersion() -> Int64 {
        return Int64(userDefaults.integer(forKey: Keys.garbageScheduleVersion))
    }

    public func setGarbageScheduleVersion(_ version: Int64) {
        userDefaults.set(Int(version), forKey: Keys.garbageScheduleVersion)
    }

    @discardableResult
    public func updateGarbageScheduleVersion() -> Int64 {
        let newVersion = Int64(Date().timeIntervalSince1970 * 1000)
        setGarbageScheduleVersion(newVersion)
        return newVersion
    }
}
