import SwiftUI
import EventKit

public struct CalendarAppendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GarbageViewModel.self) private var viewModel

    @State private var eventPeriod: Int = 1 // 0: 1 week, 1: 1 month, 2: 2 months
    @State private var writableCalendars: [CalendarAccountItem] = []
    @State private var selectedCalendar: CalendarAccountItem? = nil

    @State private var isRegistering = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var registrationSucceeded = false

    private let calendarManager = CalendarManager.shared

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Info Card
                VStack(alignment: .leading, spacing: 6) {
                    Text("※ 端末のカレンダーアプリに、設定したゴミ収集日（終日予定）を登録します。")
                        .font(.system(size: 13))
                        .foregroundColor(.defaultTheme)
                        .lineSpacing(4)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.defaultTheme.opacity(0.06))
                .cornerRadius(6)

                // Period Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("登録期間")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.defaultTheme)

                    HStack(spacing: 8) {
                        let periods = ["1週間", "1ヶ月", "2ヶ月"]
                        ForEach(0..<periods.count, id: \.self) { index in
                            SelectablePillView(
                                title: periods[index],
                                isSelected: eventPeriod == index,
                                height: 38
                            ) {
                                eventPeriod = index
                            }
                        }
                    }
                }

                // Summary / Confirmation Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("登録内容の確認")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.defaultTheme)

                    VStack(spacing: 12) {
                        HStack {
                            Text("登録対象日")
                                .font(.system(size: 14))
                                .foregroundColor(.customTextSecondary)
                            Spacer()
                            Text("収集日の当日（終日予定）")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.defaultTheme)
                        }

                        Divider()

                        HStack {
                            Text("登録期間")
                                .font(.system(size: 14))
                                .foregroundColor(.customTextSecondary)
                            Spacer()
                            let periodText = eventPeriod == 0 ? "今日から 1週間" : (eventPeriod == 1 ? "今日から 1ヶ月" : "今日から 2ヶ月")
                            Text(periodText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.defaultTheme)
                        }

                        if writableCalendars.count > 1 {
                            Divider()

                            HStack {
                                Text("登録先カレンダー")
                                    .font(.system(size: 14))
                                    .foregroundColor(.customTextSecondary)

                                Spacer()

                                Picker("", selection: $selectedCalendar) {
                                    ForEach(writableCalendars) { cal in
                                        Text(cal.title).tag(Optional(cal))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.defaultTheme)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.customCardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.customDivider, lineWidth: 1)
                    )
                }

                Spacer(minLength: 24)

                // Action Button
                Button(action: { doRegister() }) {
                    HStack(spacing: 8) {
                        if isRegistering {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isRegistering ? "登録中..." : "カレンダーに登録")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isRegistering ? Color.defaultTheme.opacity(0.6) : Color.defaultTheme)
                    .cornerRadius(6)
                }
                .disabled(isRegistering)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .navigationTitle("登録設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if registrationSucceeded {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .task {
            loadCalendars()
        }
    }

    private func loadCalendars() {
        if calendarManager.hasCalendarPermission() {
            let cals = calendarManager.getWritableCalendars()
            writableCalendars = cals
            selectedCalendar = calendarManager.getDefaultCalendar()
        }
    }

    private func doRegister() {
        if viewModel.garbageModels.isEmpty {
            alertTitle = "エラー"
            alertMessage = "登録可能な収集日がありません。「ゴミの日」で収集日を設定してください。"
            showingAlert = true
            return
        }

        isRegistering = true

        Task {
            if !calendarManager.hasCalendarPermission() {
                let granted = await calendarManager.requestCalendarAccess()
                if !granted {
                    isRegistering = false
                    alertTitle = "権限エラー"
                    alertMessage = "カレンダーへのアクセス権限が必要です。設定アプリで許可してください。"
                    showingAlert = true
                    return
                }
                loadCalendars()
            }

            let result = await calendarManager.registerEvents(
                models: viewModel.garbageModels,
                periodIndex: eventPeriod,
                targetCalendarIdentifier: selectedCalendar?.id
            )

            isRegistering = false

            switch result {
            case .success(let count):
                if count > 0 {
                    alertTitle = "完了"
                    alertMessage = "\(count)件の予定をカレンダーに登録しました。"
                    registrationSucceeded = true
                } else {
                    alertTitle = "通知"
                    alertMessage = "選択した期間内に該当するゴミ収集日がありませんでした。"
                }
            case .noSchedules:
                alertTitle = "エラー"
                alertMessage = "登録可能な収集日がありません。「ゴミの日」で収集日を設定してください。"
            case .noCalendarFound:
                alertTitle = "エラー"
                alertMessage = "書き込み可能なカレンダーが見つかりませんでした。"
            case .permissionDenied:
                alertTitle = "権限エラー"
                alertMessage = "カレンダーへのアクセス権限が必要です。"
            case .failed(let err):
                alertTitle = "エラー"
                alertMessage = "登録中にエラーが発生しました: \(err)"
            }
            showingAlert = true
        }
    }
}
