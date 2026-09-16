import SwiftUI

public struct SettingsView: View {
    @Environment(GarbageViewModel.self) private var viewModel

    @State private var showingCalendarResetAlert = false
    @State private var showingGarbageResetAlert = false
    @State private var alertMessage = ""
    @State private var showingFeedback = false
    @State private var showingPushSettings = false
    @State private var showingCalendarAppend = false

    private let calendarManager = CalendarManager.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 16)

                    // App Icon & Info
                    Image("icon_1024")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                    Spacer().frame(height: 14)

                    Text("ゴミマン")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.defaultTheme)

                    Text("Ver 1.5.0")
                        .font(.system(size: 14))
                        .foregroundColor(.customTextSecondary)

                    Spacer().frame(height: 32)

                    // Settings Group Card
                    VStack(spacing: 0) {
                        settingsRow(title: "カレンダーの予定を削除") {
                            showingCalendarResetAlert = true
                        }

                        rowDivider

                        settingsRow(title: "ごみ収集日のリセット") {
                            showingGarbageResetAlert = true
                        }

                        rowDivider

                        settingsRow(title: "通知設定") {
                            showingPushSettings = true
                        }

                        rowDivider

                        settingsRow(title: "カレンダーに登録") {
                            showingCalendarAppend = true
                        }

                        rowDivider

                        settingsRow(title: "アプリを評価する") {
                            openAppStoreReview()
                        }

                        rowDivider

                        settingsRow(title: "ご意見・ご要望") {
                            showingFeedback = true
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.defaultTheme, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 36)
                }
            }
            .background(Color.white)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingPushSettings) {
                PushSettingView()
            }
            .navigationDestination(isPresented: $showingCalendarAppend) {
                CalendarAppendView()
            }
            .navigationDestination(isPresented: $showingFeedback) {
                FeedbackView()
            }
            .alert("カレンダー予定の削除", isPresented: $showingCalendarResetAlert) {
                Button("削除", role: .destructive) {
                    Task {
                        let count = await calendarManager.resetEvents()
                        alertMessage = count > 0 ? "カレンダーの予定を\(count)件削除しました。" : "削除対象のカレンダー予定がありませんでした。"
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("端末のカレンダーから、ゴミマンが登録した収集予定をすべて削除します。\nよろしいですか？")
            }
            .alert("ごみ収集日のリセット", isPresented: $showingGarbageResetAlert) {
                Button("リセット", role: .destructive) {
                    viewModel.resetAllGarbageCollections()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("登録されているすべての収集日設定が削除されます。\nリセットしてもよろしいですか？")
            }
        }
    }

    private var rowDivider: some View {
        Divider()
            .background(Color.customDivider)
            .padding(.leading, 16)
    }

    private func settingsRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.defaultTheme)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.customTextSecondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
        }
        .buttonStyle(.plain)
    }

    private func openAppStoreReview() {
        // Direct App Store URL for bundle co.jp.kpbr.gomiman
        if let url = URL(string: "https://apps.apple.com/app/id6740049444?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}
