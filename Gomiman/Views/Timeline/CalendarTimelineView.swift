import SwiftUI

public struct CalendarTimelineView: View {
    @Environment(GarbageViewModel.self) private var viewModel
    @State private var showingCalendarAppend = false
    @State private var showingGarbageAdd = false

    public init() {}

    private var today: Date { Date() }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header: Big Day of Week + Date + Append button
                timelineHeader

                // Today's garbage collection status row
                todayGarbageRow

                Divider()
                    .background(Color.customDivider)

                if viewModel.garbageModels.isEmpty {
                    Spacer()
                    emptyScheduleView
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.timelineItems.enumerated()), id: \.element.id) { index, item in
                                TimelineListItemView(
                                    item: item,
                                    isLast: index == viewModel.timelineItems.count - 1
                                )
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }

                BannerAdView(adUnitId: AdConstants.getTimelineBannerUnitId())
                    .padding(.vertical, 4)
            }
            .background(Color.white)
            .navigationDestination(isPresented: $showingCalendarAppend) {
                CalendarAppendView()
            }
            .sheet(isPresented: $showingGarbageAdd) {
                GarbageAddView()
            }
            .onAppear {
                viewModel.recalculateTimeline()
            }
        }
    }

    // MARK: - Header

    private var timelineHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            let calendar = Calendar.current
            let weekdayIndex = DateUtils.isoWeekday(for: today, calendar: calendar)
            let weekdayName = (weekdayIndex >= 1 && weekdayIndex <= 7) ? DateUtils.weekdayInHanji[weekdayIndex] : ""
            let year = calendar.component(.year, from: today)
            let month = calendar.component(.month, from: today)
            let day = calendar.component(.day, from: today)

            Text(weekdayName)
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.defaultTheme)

            VStack(alignment: .leading, spacing: 2) {
                Text(DateUtils.convertJPYear(year))
                    .font(.system(size: 14))
                    .foregroundColor(.customTextSecondary)

                Text("\(month)月\(day)日")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.defaultTheme)
            }

            Spacer()

            if !viewModel.garbageModels.isEmpty {
                Button(action: { showingCalendarAppend = true }) {
                    Text("カレンダーに登録")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.defaultTheme)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.defaultTheme, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Today Row

    private var todayGarbageRow: some View {
        HStack(spacing: 8) {
            if viewModel.todayGarbageTypes.isEmpty {
                GarbageTypeBadgeView(title: "なし")
            } else {
                ForEach(viewModel.todayGarbageTypes) { type in
                    GarbageTypeBadgeView(title: type.shortName)
                }

                if viewModel.isCollectedToday {
                    Text("【収集済み】")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.defaultTheme)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyScheduleView: some View {
        VStack(spacing: 24) {
            Text("収集日の登録がありません")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.defaultTheme)

            Button(action: { showingGarbageAdd = true }) {
                Text("設定する")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.defaultTheme)
                    .frame(width: 100, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.defaultTheme, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 40)
    }
}

// MARK: - Timeline List Item

private struct TimelineListItemView: View {
    let item: TimelineItem
    let isLast: Bool

    private var headline: String {
        let calendar = Calendar.current
        let weekdayIndex = DateUtils.isoWeekday(for: item.date, calendar: calendar)
        let weekday = (weekdayIndex >= 1 && weekdayIndex <= 7) ? DateUtils.weekdayInHanji[weekdayIndex] : ""
        switch item.daysAfter {
        case 1: return "明日（\(weekday)）"
        case 2: return "明後日（\(weekday)）"
        default: return "\(item.daysAfter)日後（\(weekday)）"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Vertical timeline connecting line with node
            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(Color.customDivider)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 10)
                }

                Circle()
                    .stroke(Color.defaultTheme, lineWidth: 2)
                    .background(Circle().fill(Color.white))
                    .frame(width: 14, height: 14)
                    .padding(.top, 4)
            }
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text(headline)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.defaultTheme)

                HStack(spacing: 8) {
                    ForEach(item.types) { type in
                        GarbageTypeBadgeView(title: type.shortName)
                    }
                }
            }
            .padding(.bottom, 22)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
