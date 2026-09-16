import Foundation
import EventKit

public struct CalendarAccountItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let sourceTitle: String
    public let isSubscribed: Bool

    public init(id: String, title: String, sourceTitle: String, isSubscribed: Bool) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
        self.isSubscribed = isSubscribed
    }
}

public enum CalendarRegisterResult: Sendable {
    case success(count: Int)
    case noSchedules
    case noCalendarFound
    case permissionDenied
    case failed(error: String)
}

public final class CalendarManager: @unchecked Sendable {
    public static let shared = CalendarManager()

    public static let eventTag = "ゴミマン"
    public static let eventSuffix = " (ゴミマン)"
    public static let eventDescription = "ゴミマンによって登録されたごみ収集予定"

    private let eventStore = EKEventStore()

    public init() {}

    // MARK: - Permissions

    public func hasCalendarPermission() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    public func requestCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Calendars

    public func getWritableCalendars() -> [CalendarAccountItem] {
        guard hasCalendarPermission() else { return [] }
        let calendars = eventStore.calendars(for: .event)
        return calendars.filter { $0.allowsContentModifications }.map { cal in
            CalendarAccountItem(
                id: cal.calendarIdentifier,
                title: cal.title,
                sourceTitle: cal.source.title,
                isSubscribed: cal.isSubscribed
            )
        }
    }

    public func getDefaultCalendar() -> CalendarAccountItem? {
        guard let defaultCal = eventStore.defaultCalendarForNewEvents else {
            return getWritableCalendars().first
        }
        return CalendarAccountItem(
            id: defaultCal.calendarIdentifier,
            title: defaultCal.title,
            sourceTitle: defaultCal.source.title,
            isSubscribed: defaultCal.isSubscribed
        )
    }

    // MARK: - Event Registration

    public func registerEvents(
        models: [GarbageCollectionModel],
        periodIndex: Int, // 0: 7 days, 1: 30 days, 2: 60 days
        targetCalendarIdentifier: String? = nil
    ) async -> CalendarRegisterResult {
        guard hasCalendarPermission() else {
            return .permissionDenied
        }
        guard !models.isEmpty else {
            return .noSchedules
        }

        let calendars = eventStore.calendars(for: .event)
        let targetCalendar: EKCalendar?
        if let id = targetCalendarIdentifier {
            targetCalendar = calendars.first { $0.calendarIdentifier == id }
        } else {
            targetCalendar = eventStore.defaultCalendarForNewEvents ?? calendars.first { $0.allowsContentModifications }
        }

        guard let calendar = targetCalendar, calendar.allowsContentModifications else {
            return .noCalendarFound
        }

        // Clean up existing Gomiman events first to prevent duplicates
        _ = await resetEvents()

        let daysCount: Int
        switch periodIndex {
        case 0: daysCount = 7
        case 1: daysCount = 30
        case 2: daysCount = 60
        default: daysCount = 30
        }

        let sysCalendar = Calendar.current
        let today = sysCalendar.startOfDay(for: Date())
        var addedCount = 0

        for i in 0..<daysCount {
            guard let targetDate = sysCalendar.date(byAdding: .day, value: i, to: today) else { continue }
            let types = DateUtils.getGarbageTypes(for: targetDate, models: models, calendar: sysCalendar)
            if !types.isEmpty {
                let event = EKEvent(eventStore: eventStore)
                event.calendar = calendar
                event.isAllDay = true
                event.startDate = targetDate
                event.endDate = targetDate

                let typesTitle = types.map { $0.typeName }.joined(separator: ", ")
                event.title = "\(typesTitle)\(Self.eventSuffix)"
                event.notes = Self.eventDescription

                do {
                    try eventStore.save(event, span: .thisEvent, commit: false)
                    addedCount += 1
                } catch {
                    // Continue saving subsequent events
                }
            }
        }

        if addedCount > 0 {
            do {
                try eventStore.commit()
            } catch {
                return .failed(error: error.localizedDescription)
            }
        }

        return .success(count: addedCount)
    }

    // MARK: - Event Deletion / Reset

    public func resetEvents() async -> Int {
        guard hasCalendarPermission() else { return 0 }

        let sysCalendar = Calendar.current
        let now = Date()
        guard let startDate = sysCalendar.date(byAdding: .year, value: -1, to: now),
              let endDate = sysCalendar.date(byAdding: .year, value: 1, to: now) else {
            return 0
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        var deletedCount = 0
        for event in events {
            let titleMatch = event.title?.contains(Self.eventTag) == true
            let notesMatch = event.notes?.contains(Self.eventTag) == true
            if titleMatch || notesMatch {
                do {
                    try eventStore.remove(event, span: .thisEvent, commit: false)
                    deletedCount += 1
                } catch {
                    // Ignore and continue
                }
            }
        }

        if deletedCount > 0 {
            try? eventStore.commit()
        }

        return deletedCount
    }
}
