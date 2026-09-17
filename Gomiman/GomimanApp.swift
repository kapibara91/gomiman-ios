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

public enum FirebaseInitializer: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var isConfigured = false

    public static func configureIfNeeded() {
        lock.lock()
        defer { lock.unlock() }

        guard !isConfigured else { return }

        #if canImport(FirebaseAppCheck)
        AppCheckManager.shared.initialize()
        #endif

        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif

        isConfigured = true
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseInitializer.configureIfNeeded()
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
        // 1. Initialize Firebase App Check & FirebaseApp safely
        FirebaseInitializer.configureIfNeeded()

        // 2. Configure FCM delegate
        FCMManager.shared.configure()

        // 3. Initialize Google Mobile Ads SDK
        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif

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
