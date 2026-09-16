import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            CalendarTimelineView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
                .tag(0)

            GarbageListView()
                .tabItem {
                    Label("ゴミの日", systemImage: "trash")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(.defaultTheme)
    }
}
