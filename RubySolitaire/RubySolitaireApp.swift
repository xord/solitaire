import SwiftUI
import FirebaseCore
import GoogleMobileAds


class AppContext: NSObject, ObservableObject {
    @Published var ready = false
}


class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        if #available(iOS 15.0, *) {
            window = windowScene.keyWindow
        } else {
            window = windowScene.windows.first
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {

    @Published var appContext = AppContext()

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: nil, sessionRole: connectingSceneSession.role)
        if (connectingSceneSession.role == .windowApplication) {
            configuration.delegateClass = SceneDelegate.self
        }
        return configuration
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if !DEBUG
            FirebaseApp.configure()
        #endif

        GADMobileAds.sharedInstance().start(completionHandler: { [weak self] _ in
            self!.appContext.ready = true
        })

        return true
    }
}


@main
struct RubySolitaireApp: App {

    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            GameScreen()
        }
    }
}


struct GameScreen: View {

    @EnvironmentObject var sceneDelegate: SceneDelegate

    @StateObject var interstitialAd = InterstitialAd(
        adUnitID: "ca-app-pub-3940256099942544/4411468910")

    @State var isInterstitialAdVisible = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            GeometryReader { gr in
                VStack(spacing: 2) {
                    GameView(isInterstitialAdVisible: $isInterstitialAdVisible)
                    AdBannerView(
                        width: gr.size.width,
                        adUnitID: "ca-app-pub-3940256099942544/2934735716",
                        rootViewController: sceneDelegate.window!.rootViewController!
                    )
                    .frame(width: gr.size.width, height: 50)
                }
            }
        }
        .statusBarHidden()
        .onChange(of: isInterstitialAdVisible) { visible in
            if visible, interstitialAd.ready {
                interstitialAd.show(
                    rootViewController: sceneDelegate.window!.rootViewController!
                ) { error in
                    isInterstitialAdVisible = false
                }
            } else {
                isInterstitialAdVisible = false
            }
        }
    }
}
