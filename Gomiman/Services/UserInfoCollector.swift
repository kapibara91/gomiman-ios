import Foundation
import UIKit

public enum UserInfoCollector {
    @MainActor public static func collect(fcmToken: String? = nil) -> UserInfoModel {
        let deviceId = PreferencesManager.shared.getOrCreateDeviceUniqueId()
        let timeZoneOffsetHours = TimeZone.current.secondsFromGMT() / 3600

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "8"

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let modelIdentifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        let isPhysical: Bool
        #if targetEnvironment(simulator)
        isPhysical = false
        #else
        isPhysical = true
        #endif

        return UserInfoModel(
            deviceUniqueId: deviceId,
            fcmToken: fcmToken,
            version: appVersion,
            buildNumber: buildNumber,
            timeZoneOffsetInHours: timeZoneOffsetHours,
            platform: "iOS",
            isPhysicalDevice: isPhysical,
            brand: "Apple",
            model: modelIdentifier.isEmpty ? UIDevice.current.model : modelIdentifier,
            device: UIDevice.current.model,
            name: UIDevice.current.name,
            systemVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        )
    }
}
