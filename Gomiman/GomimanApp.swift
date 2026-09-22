import SwiftUI
import UserNotifications
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif

        NotificationManager.shared.configure()
        NotificationManager.shared.registerBackgroundTask()

        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif

        return true
    }
}

@main
struct GomimanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
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
                    AnalyticsManager.shared.logEvent(name: "app_open")
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                NotificationManager.shared.scheduleAppRefresh()
            }
        }
    }
}
