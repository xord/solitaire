import SwiftUI

@main
struct RubySolitaireApp: App {
    init() {
        let mainBundleDir = Bundle.main.bundlePath
        CRuby.load("\(mainBundleDir)/lib/solitaire.rb")
    }

    var body: some Scene {
        WindowGroup {
            GameView()
        }
    }
}
