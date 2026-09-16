import SwiftUI
import UserNotifications
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif

        AppCheckManager.shared.initialize()
        FCMManager.shared.configure()

        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }
}

@main
struct GomimanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
                        // Sync base device metadata to Firestore on launch (matching Android GomimanApp)
                        // Notification permission is explicitly NOT requested here.
                        _ = await CloudRunSyncService.shared.syncBaseInfo()
                    }
                }
        }
    }
}
