import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

public final class AnalyticsManager: @unchecked Sendable {
    public static let shared = AnalyticsManager()

    private init() {}

    // MARK: - Generic Logging

    public func logEvent(name: String, parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: parameters)
        #if DEBUG
        print("[Analytics] Event logged: \(name), params: \(parameters ?? [:])")
        #endif
        #else
        #if DEBUG
        print("[Analytics] (canImport=false) Event: \(name), params: \(parameters ?? [:])")
        #endif
        #endif
    }

    public func logScreenView(screenName: String, screenClass: String? = nil) {
        #if canImport(FirebaseAnalytics)
        var params: [String: Any] = [
            AnalyticsParameterScreenName: screenName
        ]
        if let sc = screenClass {
            params[AnalyticsParameterScreenClass] = sc
        }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
        #if DEBUG
        print("[Analytics] Screen view: \(screenName)")
        #endif
        #endif
    }

    // MARK: - Specific Business Events

    public func logAddGarbage(types: [Int], isEveryWeek: Bool) {
        logEvent(
            name: "add_garbage_schedule",
            parameters: [
                "type_count": types.count,
                "is_every_week": isEveryWeek
            ]
        )
    }

    public func logDeleteGarbage(id: Int64) {
        logEvent(
            name: "delete_garbage_schedule",
            parameters: [
                "schedule_id": id
            ]
        )
    }

    public func logResetGarbage() {
        logEvent(name: "reset_all_garbage_schedules")
    }

    public func logUpdatePushSetting(dayBefore: Bool, dayBeforeHour: Int, dayAfter: Bool, dayAfterHour: Int) {
        logEvent(
            name: "update_push_setting",
            parameters: [
                "day_before": dayBefore,
                "day_before_hour": dayBeforeHour,
                "day_after": dayAfter,
                "day_after_hour": dayAfterHour
            ]
        )
    }

    public func logCalendarAppend(count: Int, periodIndex: Int) {
        logEvent(
            name: "calendar_append",
            parameters: [
                "event_count": count,
                "period_index": periodIndex
            ]
        )
    }

    public func logCalendarReset(count: Int) {
        logEvent(
            name: "calendar_reset",
            parameters: [
                "deleted_count": count
            ]
        )
    }
}
