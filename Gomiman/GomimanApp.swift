import SwiftUI
import UserNotifications

@main
struct GomimanApp: App {
    @State private var viewModel = GarbageViewModel()

    init() {
        // Configure native navigation bar appearance to match clean white styling
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.defaultTheme)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(viewModel)
                .onAppear {
                    viewModel.loadData()
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                    }
                }
        }
    }
}
