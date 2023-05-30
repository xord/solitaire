import SwiftUI
import GoogleMobileAds


struct AdBannerView: UIViewRepresentable {
    let width: Double
    let adUnitID: String
    let rootViewController: UIViewController

    func makeUIView(context: Context) -> some UIView {
        let view = GADBannerView(adSize: GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth(width))
        view.adUnitID           = adUnitID
        view.rootViewController = rootViewController
        view.load(GADRequest())
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}
