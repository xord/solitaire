import SwiftUI

class GameViewController : ReflexViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        Reflexion.setup()
        RubySketch.setup()
        RubySketch.setActiveReflexViewController(self)

        CRuby.evaluate("""
            Encoding.default_internal = Encoding::UTF_8
            Encoding.default_external = Encoding::UTF_8
            Warning[:experimental]    = false
        """)
        RubySketch.start("\(Bundle.main.bundlePath)/lib/solitaire.rb");
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

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
