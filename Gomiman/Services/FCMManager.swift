import Foundation
import UIKit
import UserNotifications
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

public final class FCMManager: NSObject, @unchecked Sendable {
    public static let shared = FCMManager()

    public private(set) var currentFCMToken: String? = nil

    private override init() {
        super.init()
    }

    public func configure() {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
        #endif
        UNUserNotificationCenter.current().delegate = self
    }

    /// Explicitly request push notification permissions and register for remote notifications.
    /// This is ONLY invoked when the user enters PushSettingView.
    public func requestPushPermissionAndRegister() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                #if canImport(FirebaseMessaging)
                if let token = try? await Messaging.messaging().token() {
                    self.currentFCMToken = token
                    _ = await FirestoreSyncService.shared.syncFCMToken(token)
                }
                #endif
            }
            return granted
        } catch {
            return false
        }
    }
}

#if canImport(FirebaseMessaging)
extension FCMManager: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, !token.isEmpty else { return }
        self.currentFCMToken = token
        #if DEBUG
        print("[FCMManager] Refreshed FCM token received: \(token)")
        #endif

        Task {
            _ = await FirestoreSyncService.shared.syncFCMToken(token)
        }
    }
}
#endif

extension FCMManager: UNUserNotificationCenterDelegate {
    /// Receive notification when app is in the foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        #if DEBUG
        print("[FCMManager] Foreground notification received: \(notification.request.content.title)")
        #endif
        completionHandler([.banner, .badge, .sound])
    }

    /// User tapped notification
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        #if DEBUG
        print("[FCMManager] User opened notification: \(response.notification.request.content.title)")
        #endif
        completionHandler()
    }
}
