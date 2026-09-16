import Foundation

public protocol SyncServiceProtocol: Sendable {
    func syncGarbageSetting(collections: [GarbageCollectionModel], version: Int64, pushSetting: PushSettingModel) async -> Result<Void, Error>
    func submitFeedback(message: String) async -> Result<Void, Error>
    func testPing() async -> Result<String, Error>
    func syncBaseInfo() async -> Result<Void, Error>
}

public final class CloudRunSyncService: SyncServiceProtocol, @unchecked Sendable {
    public static let shared = CloudRunSyncService()

    public static let defaultBaseUrl = "https://gomiman-af0f8.web.app"
    public static let appCheckHeader = "X-Firebase-AppCheck"

    public static let pathGarbageSchedule = "/api/v1/garbage/schedule"
    public static let pathPing = "/api/v1/ping"
    public static let pathFeedback = "/api/v1/feedback"

    private let baseUrl: String
    private let urlSession: URLSession

    public init(baseUrl: String = defaultBaseUrl, urlSession: URLSession = .shared) {
        self.baseUrl = baseUrl
        self.urlSession = urlSession
    }

    /// Syncs base device metadata directly to Firestore 'users' collection
    public func syncBaseInfo() async -> Result<Void, Error> {
        let userInfo = UserInfoCollector.collect(fcmToken: FCMManager.shared.currentFCMToken)
        return await FirestoreSyncService.shared.syncBaseInfo(userInfo)
    }

    /// Primary sync: Cloud Run /api/v1/garbage/schedule with App Check header.
    /// Fallback: Direct Firestore write to 'users/{docId}' if Cloud Run fails.
    public func syncGarbageSetting(
        collections: [GarbageCollectionModel],
        version: Int64,
        pushSetting: PushSettingModel
    ) async -> Result<Void, Error> {
        guard let url = URL(string: baseUrl + Self.pathGarbageSchedule) else {
            return await FirestoreSyncService.shared.syncGarbageSettingDirectly(collections: collections, version: version)
        }

        let deviceId = PreferencesManager.shared.getOrCreateDeviceUniqueId()
        let body: [String: Any] = [
            "identifierForVendor": deviceId,
            "deviceUniqueId": deviceId,
            "userGarbageInfo": collections.map { $0.toDictionary() },
            "version": version,
            "scheduleVersion": version,
            "pushSetting": pushSetting.toDictionary()
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])

            // First attempt with cached or standard App Check token
            let token = await AppCheckManager.shared.getAppCheckToken(forceRefresh: false)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let t = token {
                request.setValue(t, forHTTPHeaderField: Self.appCheckHeader)
            }
            request.httpBody = jsonData
            request.timeoutInterval = 15

            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    #if DEBUG
                    print("[CloudRunSync] Successfully synced garbage setting to Cloud Run")
                    #endif
                    return .success(())
                }

                // If 401 or 403, retry once with force-refreshed App Check token
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    #if DEBUG
                    print("[CloudRunSync] HTTP \(httpResponse.statusCode). Retrying with force-refreshed App Check token...")
                    #endif
                    if let freshToken = await AppCheckManager.shared.getAppCheckToken(forceRefresh: true) {
                        var retryRequest = request
                        retryRequest.setValue(freshToken, forHTTPHeaderField: Self.appCheckHeader)
                        let (_, retryResp) = try await urlSession.data(for: retryRequest)
                        if let retryHttp = retryResp as? HTTPURLResponse, (200...299).contains(retryHttp.statusCode) {
                            return .success(())
                        }
                    }
                }
            }

            // If Cloud Run request was not successful, fallback to Firestore write
            #if DEBUG
            print("[CloudRunSync] Cloud Run failed. Falling back to direct Firestore write...")
            #endif
            return await FirestoreSyncService.shared.syncGarbageSettingDirectly(collections: collections, version: version)
        } catch {
            #if DEBUG
            print("[CloudRunSync] Cloud Run exception: \(error.localizedDescription). Falling back to Firestore...")
            #endif
            return await FirestoreSyncService.shared.syncGarbageSettingDirectly(collections: collections, version: version)
        }
    }

    /// Submits user feedback directly to Firestore 'feedback' collection
    public func submitFeedback(message: String) async -> Result<Void, Error> {
        return await FirestoreSyncService.shared.submitFeedback(message: message)
    }

    public func testPing() async -> Result<String, Error> {
        guard let url = URL(string: baseUrl + Self.pathPing) else {
            return .failure(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        if let token = await AppCheckManager.shared.getAppCheckToken(forceRefresh: false) {
            request.setValue(token, forHTTPHeaderField: Self.appCheckHeader)
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
               let str = String(data: data, encoding: .utf8) {
                return .success(str)
            } else {
                return .failure(URLError(.badServerResponse))
            }
        } catch {
            return .failure(error)
        }
    }
}
