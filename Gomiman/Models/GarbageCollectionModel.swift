import Foundation

public struct GarbageCollectionModel: Identifiable, Codable, Equatable, Sendable {
    public var id: Int64?
    /// 1: 毎週 (Every week), 2: 隔週 (Bi-weekly)
    public var weekStatus: Int
    /// Weeks of month: 1 to 5 (when bi-weekly)
    public var weeks: [Int]
    /// Garbage types: 1 to 7
    public var garbageTypes: [Int]
    /// Days of week: 1 (Mon) to 7 (Sun)
    public var days: [Int]
    /// Version timestamp to prevent backend from sending outdated push notifications
    public var version: Int64

    public static let weekStatusEveryWeek = 1
    public static let weekStatusBiweekly = 2

    public init(
        id: Int64? = nil,
        weekStatus: Int = 1,
        weeks: [Int] = [],
        garbageTypes: [Int] = [],
        days: [Int] = [],
        version: Int64 = 0
    ) {
        self.id = id
        self.weekStatus = weekStatus
        self.weeks = weeks
        self.garbageTypes = garbageTypes
        self.days = days
        self.version = version
    }

    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "weekStatus": weekStatus,
            "weeks": weeks,
            "garbageTypes": garbageTypes,
            "days": days,
            "version": version
        ]
        if let id = id {
            dict["id"] = id
        }
        return dict
    }
}
