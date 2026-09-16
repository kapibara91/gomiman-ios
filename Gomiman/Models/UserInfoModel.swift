import Foundation

public struct UserInfoModel: Codable, Sendable {
    public var deviceUniqueId: String?
    public var fcmToken: String?
    public var version: String
    public var buildNumber: String
    public var timeZoneOffsetInHours: Int
    public var platform: String
    public var isPhysicalDevice: Bool
    public var brand: String
    public var model: String
    public var device: String
    public var name: String
    public var systemVersion: String

    public init(
        deviceUniqueId: String? = nil,
        fcmToken: String? = nil,
        version: String = "1.5.0",
        buildNumber: String = "8",
        timeZoneOffsetInHours: Int = 9,
        platform: String = "iOS",
        isPhysicalDevice: Bool = true,
        brand: String = "Apple",
        model: String = "",
        device: String = "",
        name: String = "",
        systemVersion: String = ""
    ) {
        self.deviceUniqueId = deviceUniqueId
        self.fcmToken = fcmToken
        self.version = version
        self.buildNumber = buildNumber
        self.timeZoneOffsetInHours = timeZoneOffsetInHours
        self.platform = platform
        self.isPhysicalDevice = isPhysicalDevice
        self.brand = brand
        self.model = model
        self.device = device
        self.name = name
        self.systemVersion = systemVersion
    }

    public func toDictionary() -> [String: Any?] {
        var dict: [String: Any?] = [
            "deviceUniqueId": deviceUniqueId,
            "version": version,
            "buildNumber": buildNumber,
            "timeZoneOffsetInHours": timeZoneOffsetInHours,
            "platform": platform,
            "isPhysicalDevice": isPhysicalDevice,
            "brand": brand,
            "model": model,
            "device": device,
            "name": name,
            "systemVersion": systemVersion
        ]
        if let token = fcmToken {
            dict["fcmToken"] = token
        }
        return dict
    }
}
