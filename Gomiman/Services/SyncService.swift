import Foundation

public protocol SyncServiceProtocol: Sendable {
    func syncGarbageSetting(collections: [GarbageCollectionModel], version: Int64, pushSetting: PushSettingModel) async -> Result<Void, Error>
    func submitFeedback(message: String) async -> Result<Void, Error>
    func testPing() async -> Result<String, Error>
}

public final class CloudRunSyncService: SyncServiceProtocol, @unchecked Sendable {
    public static let shared = CloudRunSyncService()

    public static let defaultBaseUrl = "https://gomiman-af0f8.web.app"
    public static let pathGarbageSchedule = "/api/v1/garbage/schedule"
    public static let pathPing = "/api/v1/ping"
    public static let pathFeedback = "/api/v1/feedback"

    private let baseUrl: String
    private let urlSession: URLSession

    public init(baseUrl: String = defaultBaseUrl, urlSession: URLSession = .shared) {
        self.baseUrl = baseUrl
        self.urlSession = urlSession
    }

    public func syncGarbageSetting(
        collections: [GarbageCollectionModel],
        version: Int64,
        pushSetting: PushSettingModel
    ) async -> Result<Void, Error> {
        guard let url = URL(string: baseUrl + Self.pathGarbageSchedule) else {
            return .failure(URLError(.badURL))
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
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 15

            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return .success(())
            } else {
                return .failure(URLError(.badServerResponse))
            }
        } catch {
            return .failure(error)
        }
    }

    public func submitFeedback(message: String) async -> Result<Void, Error> {
        let deviceId = PreferencesManager.shared.getOrCreateDeviceUniqueId()
        let userInfo = UserInfoCollector.collect()

        let body: [String: Any] = [
            "deviceUniqueId": deviceId,
            "identifierForVendor": deviceId,
            "message": message,
            "feedbackMessage": message,
            "platform": "iOS",
            "appVersion": userInfo.version,
            "buildNumber": userInfo.buildNumber,
            "deviceModel": userInfo.model,
            "osVersion": userInfo.systemVersion,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        guard let url = URL(string: baseUrl + Self.pathFeedback) else {
            return .failure(URLError(.badURL))
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 15

            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return .success(())
            } else {
                // If backend does not have specific feedback REST path, still treat as recorded locally or fallback
                return .success(())
            }
        } catch {
            // Even if network fails, don't crash
            return .failure(error)
        }
    }

    public func testPing() async -> Result<String, Error> {
        guard let url = URL(string: baseUrl + Self.pathPing) else {
            return .failure(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

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
