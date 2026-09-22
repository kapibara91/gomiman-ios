import SwiftUI

public struct SettingsView: View {
    @Environment(GarbageViewModel.self) private var viewModel

    @State private var showingCalendarResetAlert = false
    @State private var showingGarbageResetAlert = false
    @State private var isResettingEvents = false
    @State private var isResettingGarbage = false
    @State private var showingCompletionAlert = false
    @State private var completionAlertTitle = ""
    @State private var completionAlertMessage = ""
    @State private var showingPushSettings = false
    @State private var showingCalendarAppend = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5.1"
    }

    private let calendarManager = CalendarManager.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 16)

                    // App Icon & Info
                    Group {
                        if UIImage(named: "AppLogo") != nil {
                            Image("AppLogo")
                                .resizable()
                        } else if let appIcon = Bundle.main.appIcon {
                            Image(uiImage: appIcon)
                                .resizable()
                        } else {
                            Image(systemName: "trash.circle.fill")
                                .resizable()
                                .foregroundColor(.defaultTheme)
                        }
                    }
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)

                    Spacer().frame(height: 14)

                    Text("ゴミマン")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.defaultTheme)

                    Text("Ver \(appVersion)")
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
            .alert("カレンダー予定の削除", isPresented: $showingCalendarResetAlert) {
                Button("削除", role: .destructive) {
                    guard !isResettingEvents else { return }
                    isResettingEvents = true
                    Task {
                        let count = await calendarManager.resetEvents()
                        AnalyticsManager.shared.logCalendarReset(count: count)
                        isResettingEvents = false
                        completionAlertTitle = "カレンダー予定の削除"
                        completionAlertMessage = count > 0 ? "カレンダーの予定を\(count)件削除しました。" : "削除対象のカレンダー予定がありませんでした。"
                        showingCompletionAlert = true
                    }
                }
                .disabled(isResettingEvents)
                Button("キャンセル", role: .cancel) {}
                .disabled(isResettingEvents)
            } message: {
                Text("端末のカレンダーから、ゴミマンが登録した収集予定をすべて削除します。\nよろしいですか？")
            }
            .alert("ごみ収集日のリセット", isPresented: $showingGarbageResetAlert) {
                Button("リセット", role: .destructive) {
                    guard !isResettingGarbage else { return }
                    isResettingGarbage = true
                    viewModel.resetAllGarbageCollections()
                    isResettingGarbage = false
                    completionAlertTitle = "ごみ収集日のリセット"
                    completionAlertMessage = "ごみ収集日をリセットしました。"
                    showingCompletionAlert = true
                }
                .disabled(isResettingGarbage)
                Button("キャンセル", role: .cancel) {}
                .disabled(isResettingGarbage)
            } message: {
                Text("登録されているすべての収集日設定が削除されます。\nリセットしてもよろしいですか？")
            }
            .alert(completionAlertTitle, isPresented: $showingCompletionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(completionAlertMessage)
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
        // Direct App Store URL for bundle co.jp.bms.gomiman
        if let url = URL(string: "https://apps.apple.com/app/id6740049444?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

private extension Bundle {
    var appIcon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last,
           let image = UIImage(named: lastIcon) {
            return image
        }
        if let icons = infoDictionary?["CFBundleIcons~ipad"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last,
           let image = UIImage(named: lastIcon) {
            return image
        }
        return UIImage(named: "AppIcon")
    }
}
