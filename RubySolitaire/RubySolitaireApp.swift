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
        if let lang = Helper.language {
            CRuby.evaluate("$language = '\(lang)'")
        }

        if Helper.isDebug {
            CRuby.evaluate("$debug = true")
        }

        if Helper.isRelease {
            FirebaseApp.configure()
        }

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

    @EnvironmentObject private var sceneDelegate: SceneDelegate

    @StateObject private var interstitialAd = InterstitialAd(
        adUnitID: "ca-app-pub-3940256099942544/4411468910")

    @State private var command: String = ""

    @State private var url: URL? = nil

    @State private var isInterstitialAdVisible = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            GeometryReader { gr in
                VStack(spacing: 2) {
                    GameView(command: $command)
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
        .onChange(of: command) { _ in
            if command.isEmpty {
                return
            }
            let split = command.split(separator: ":").map {$0.removingPercentEncoding}
            let commandAndArgs = split.compactMap {$0}
            if commandAndArgs.count != split.count || commandAndArgs.count == 0 {
                return clearCommand()
            }
            runCommand(command: commandAndArgs.first!, args: Array<String>(commandAndArgs.dropFirst(1)))
        }
        .onChange(of: url) { _ in
            if url == nil {
                clearCommand()
            }
        }
        .onChange(of: isInterstitialAdVisible) { visible in
            if visible, interstitialAd.ready {
                interstitialAd.show(
                    rootViewController: sceneDelegate.window!.rootViewController!
                ) { error in
                    isInterstitialAdVisible = false
                    clearCommand()
                }
            } else {
                isInterstitialAdVisible = false
                clearCommand()
            }
        }
        .fullScreenCover(item: $url) { _ in
            if let url = url {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    func runCommand(command: String, args: [String]) {
        switch command {
        case "openURL":
            guard let str = args.first, let url = URL(string: str) else {
                return clearCommand()
            }
            self.url = url
        case "showInterstitialAd":
            isInterstitialAdVisible = true
        default:
            clearCommand()
        }
    }

    func clearCommand() {
        command = ""
    }
}
