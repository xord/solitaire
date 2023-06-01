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


class InterstitialAd: NSObject, GADFullScreenContentDelegate, ObservableObject {

    let adUnitID: String

    @Published var ready = false

    private var ad: GADInterstitialAd? {
        didSet {
            ready = ad != nil
        }
    }

    private var closed: ((Error?) -> Void)?

    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        load()
    }

    func load() {
        if ad != nil {
            return
        }
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            guard error == nil, let self = self else {
                print("Failed to load interstitial ad: \(error?.localizedDescription ?? "Unknown")")
                return
            }

            self.ad = ad
            self.ad?.fullScreenContentDelegate = self
        }
    }

    func show(rootViewController: UIViewController, closed: @escaping (Error?) -> Void) {
        guard let ad = ad else {
            closed(InterstitialAdCancelError())
            return load()
        }

        self.closed = closed
        ad.present(fromRootViewController: rootViewController)
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        self.ad = nil
        if let closed = self.closed {
            closed(nil)
            self.closed = nil
        }
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        self.ad = nil
        if let closed = self.closed {
            closed(error)
            self.closed = nil
        }
    }
}


class InterstitialAdCancelError: Error {}
