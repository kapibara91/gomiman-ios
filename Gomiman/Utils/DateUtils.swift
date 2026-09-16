import Foundation

public enum DateUtils {
    public static let weekdayInHanji = ["", "月", "火", "水", "木", "金", "土", "日"]
    public static let weekdayEn = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    /// Converts Gregorian calendar year to Japanese era year (e.g. 2026 -> 令和 8年)
    public static func convertJPYear(_ year: Int) -> String {
        switch year {
        case ..<1868:
            return "明治より前です"
        case ..<1912:
            return "明治 \(year - 33 - 1900)年"
        case ..<1926:
            return "大正 \(year - 11 - 1900)年"
        case ..<1989:
            return "昭和 \(year - 25 - 1900)年"
        case ..<2019:
            return "平成 \(year + 12 - 2000)年"
        default:
            let reiwaYear = year - 18 - 2000
            return reiwaYear == 1 ? "令和 元年" : "令和 \(reiwaYear)年"
        }
    }

    /// Returns ISO weekday: 1 (Mon) to 7 (Sun)
    public static func isoWeekday(for date: Date, calendar: Calendar = .current) -> Int {
        // Apple calendar: Sunday is 1, Monday is 2, ..., Saturday is 7
        let weekday = calendar.component(.weekday, from: date)
        // Convert to ISO 1 (Mon) .. 7 (Sun)
        return weekday == 1 ? 7 : weekday - 1
    }

    /// Checks which occurrence (1st, 2nd, etc.) of a weekday the given date is in its month.
    /// - Parameters:
    ///   - date: The date to inspect.
    ///   - targetWeekday: 1 (Mon) to 7 (Sun).
    /// - Returns: 1..5 if date matches targetWeekday, or 0 if not.
    public static func getWeekdayOfMonth(for date: Date, targetWeekday: Int, calendar: Calendar = .current) -> Int {
        let currentIsoWeekday = isoWeekday(for: date, calendar: calendar)
        if currentIsoWeekday != targetWeekday {
            return 0
        }

        let dayOfMonth = calendar.component(.day, from: date)
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return 0
        }

        let firstDayIsoWeekday = isoWeekday(for: startOfMonth, calendar: calendar)
        let firstWeekday: Int
        if firstDayIsoWeekday <= targetWeekday {
            firstWeekday = targetWeekday - firstDayIsoWeekday + 1
        } else {
            firstWeekday = targetWeekday - firstDayIsoWeekday + 1 + 7
        }

        if dayOfMonth < firstWeekday {
            return 0
        }
        return (dayOfMonth - firstWeekday) / 7 + 1
    }

    /// Finds all garbage types scheduled for a specific date.
    public static func getGarbageTypes(for date: Date, models: [GarbageCollectionModel], calendar: Calendar = .current) -> [GarbageType] {
        var result = Set<GarbageType>()
        let currentIsoWeekday = isoWeekday(for: date, calendar: calendar)

        for model in models {
            guard model.days.contains(currentIsoWeekday) else { continue }

            if model.weekStatus == GarbageCollectionModel.weekStatusEveryWeek {
                for typeId in model.garbageTypes {
                    if let type = GarbageType.from(id: typeId) {
                        result.insert(type)
                    }
                }
            } else if model.weekStatus == GarbageCollectionModel.weekStatusBiweekly {
                let occurrence = getWeekdayOfMonth(for: date, targetWeekday: currentIsoWeekday, calendar: calendar)
                if model.weeks.contains(occurrence) {
                    for typeId in model.garbageTypes {
                        if let type = GarbageType.from(id: typeId) {
                            result.insert(type)
                        }
                    }
                }
            }
        }

        return result.sorted { $0.id < $1.id }
    }

    /// Formats schedule string like: "毎週 月・水曜日" or "第1・第3週 火曜日"
    public static func formatScheduleSummary(_ model: GarbageCollectionModel) -> String {
        let weeksStr: String
        if model.weekStatus == GarbageCollectionModel.weekStatusEveryWeek {
            weeksStr = "毎週"
        } else {
            weeksStr = model.weeks.sorted().map { "第\($0)週" }.joined(separator: "・")
        }

        let daysStr = model.days.sorted().compactMap { day in
            (day >= 1 && day <= 7) ? weekdayInHanji[day] : nil
        }.joined(separator: "・") + "曜日"

        return "\(weeksStr) \(daysStr)"
    }
}
