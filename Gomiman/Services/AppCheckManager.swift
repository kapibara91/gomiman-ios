import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAppCheck)
import FirebaseAppCheck
#endif

public final class AppCheckManager: @unchecked Sendable {
    public static let shared = AppCheckManager()

    private var isInitialized = false
    private let lock = NSLock()

    private init() {}

    public func initialize() {
        lock.lock()
        defer { lock.unlock() }

        guard !isInitialized else { return }

        #if canImport(FirebaseAppCheck)
        #if DEBUG
        let envToken = ProcessInfo.processInfo.environment["AppCheckDebugToken"]
            ?? ProcessInfo.processInfo.environment["FIRAAppCheckDebugToken"]
        if let token = envToken {
            print("[AppCheckManager] Using AppCheckDebugToken from environment: \(token)")
        } else {
            print("[AppCheckManager] No AppCheckDebugToken in environment, Firebase will auto-generate one.")
        }
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("[AppCheckManager] Initialized with AppCheckDebugProviderFactory")
        #else
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("[AppCheckManager] Initialized with DeviceCheckProviderFactory")
        #endif
        #endif

        isInitialized = true
    }

    /// Retrieve a valid Firebase App Check token.
    /// - Parameter forceRefresh: If true, forces a token refresh even if cached token is valid.
    /// - Returns: The token string, or nil if retrieval failed.
    public func getAppCheckToken(forceRefresh: Bool = false) async -> String? {
        #if canImport(FirebaseAppCheck)
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: forceRefresh)
            #if DEBUG
            print("[AppCheckManager] Obtained token length: \(token.token.count), expires: \(token.expirationDate)")
            #endif
            return token.token
        } catch {
            #if DEBUG
            print("[AppCheckManager] Failed to obtain App Check token: \(error.localizedDescription)")
            #endif
            return nil
        }
        #else
        return nil
        #endif
    }
}
