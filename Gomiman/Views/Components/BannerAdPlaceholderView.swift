import SwiftUI

public enum AdConstants {
    public static let testBannerAdUnitId = "ca-app-pub-3940256099942544/2934735716" // Official iOS AdMob test ID
    public static let prodTimelineBottomBannerId = "ca-app-pub-6247787890080027/4304120209"
    public static let prodCollectionBottomBannerId = "ca-app-pub-6247787890080027/3858168159"

    public static func getTimelineBannerUnitId() -> String {
        #if DEBUG
        return testBannerAdUnitId
        #else
        return prodTimelineBottomBannerId
        #endif
    }

    public static func getCollectionBannerUnitId() -> String {
        #if DEBUG
        return testBannerAdUnitId
        #else
        return prodCollectionBottomBannerId
        #endif
    }
}

public struct BannerAdPlaceholderView: View {
    public let adUnitId: String

    public init(adUnitId: String) {
        self.adUnitId = adUnitId
    }

    public var body: some View {
        // Subtle, elegant banner ad placeholder area
        Rectangle()
            .fill(Color.clear)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
    }
}
