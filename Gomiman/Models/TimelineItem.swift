import Foundation

public struct TimelineItem: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let daysAfter: Int
    public let types: [GarbageType]

    public init(date: Date, daysAfter: Int, types: [GarbageType]) {
        self.date = date
        self.daysAfter = daysAfter
        self.types = types
    }
}
