import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

public enum AdConstants {
    // 暂时关闭广告（用于商店截图等场景），截图完成后改回 true 即可恢复
    public static let showAds: Bool = false

    /// Official Google AdMob Test Banner Unit ID for iOS
    public static let testBannerAdUnitId = "ca-app-pub-3940256099942544/2934735716"

    /// Tab 1 (Timeline / カレンダー) Bottom Banner ID
    public static let prodTimelineBottomBannerId = "ca-app-pub-6247787890080027/8902717211"

    /// Tab 2 (GarbageList / ゴミの日) Bottom Banner ID
    public static let prodCollectionBottomBannerId = "ca-app-pub-6247787890080027/1024227192"

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

public struct BannerAdView: View {
    public let adUnitId: String

    public init(adUnitId: String) {
        self.adUnitId = adUnitId
    }

    @ViewBuilder
    public var body: some View {
        if AdConstants.showAds {
            HStack {
                Spacer()
                #if canImport(GoogleMobileAds)
                BannerAdRepresentable(adUnitId: adUnitId)
                    .frame(width: 320, height: 50)
                #else
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 320, height: 50)
                #endif
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
    }
}

#if canImport(GoogleMobileAds)
private struct BannerAdRepresentable: UIViewRepresentable {
    let adUnitId: String

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitId
        bannerView.delegate = context.coordinator

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = root
        }

        let request = GADRequest()
        bannerView.load(request)
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            #if DEBUG
            print("[AdMob] Banner loaded successfully: \(bannerView.adUnitID ?? "")")
            #endif
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("[AdMob] Banner failed to load: \(error.localizedDescription) for unit \(bannerView.adUnitID ?? "")")
            #endif
        }
    }
}
#endif
