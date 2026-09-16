import Foundation

public struct PushSettingModel: Codable, Equatable, Sendable {
    public var collectionDayBefore: Bool
    /// 0: 19:00, 1: 20:00, 2: 21:00, 3: 22:00, 4: 23:00
    public var selectedTimeDayBefore: Int
    public var collectionDayAfter: Bool
    /// 0: 05:00, 1: 06:00, 2: 07:00, 3: 08:00, 4: 09:00
    public var selectedTimeDayAfter: Int

    public init(
        collectionDayBefore: Bool = true,
        selectedTimeDayBefore: Int = 1,
        collectionDayAfter: Bool = false,
        selectedTimeDayAfter: Int = 0
    ) {
        self.collectionDayBefore = collectionDayBefore
        self.selectedTimeDayBefore = selectedTimeDayBefore
        self.collectionDayAfter = collectionDayAfter
        self.selectedTimeDayAfter = selectedTimeDayAfter
    }

    public func getDayBeforeHour() -> Int {
        switch selectedTimeDayBefore {
        case 0: return 19
        case 1: return 20
        case 2: return 21
        case 3: return 22
        case 4: return 23
        default: return 20
        }
    }

    public func getDayAfterHour() -> Int {
        switch selectedTimeDayAfter {
        case 0: return 5
        case 1: return 6
        case 2: return 7
        case 3: return 8
        case 4: return 9
        default: return 5
        }
    }

    public func toDictionary() -> [String: Any] {
        return [
            "collectionDayBefore": collectionDayBefore,
            "selectedTimeDayBefore": selectedTimeDayBefore,
            "collectionDayAfter": collectionDayAfter,
            "selectedTimeDayAfter": selectedTimeDayAfter
        ]
    }
}
