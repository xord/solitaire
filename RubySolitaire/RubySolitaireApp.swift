import SwiftUI


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
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        appContext.ready = true
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
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            GameView()
        }
        .statusBarHidden()
    }
}
