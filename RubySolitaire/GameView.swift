import SwiftUI

class GameViewController : ReflexViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let mainBundleDir = Bundle.main.bundlePath

        CRuby.evaluate("""
            Encoding.default_internal = Encoding::UTF_8
            Encoding.default_external = Encoding::UTF_8
            Warning[:experimental]    = false

            %w[
                ruby/lib
            ].each do |lib|
                $LOAD_PATH.unshift File.join '\(mainBundleDir)', lib
            end
        """)

        RubySketch.setup()
        RubySketch.setActiveReflexViewController(self)

        RubySketch.start("\(mainBundleDir)/lib/solitaire.rb");
    }
}

struct GameView: View {
    var body: some View {
        GameViewControllerWrapper()
    }
}

struct GameViewControllerWrapper : UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return GameViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
