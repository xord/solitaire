import SwiftUI


class GameViewController : ReflexViewController {

    private var started = false

    override func viewDidLoad() {
        super.viewDidLoad()

        CRuby.evaluate("""
            Encoding.default_internal = Encoding::UTF_8
            Encoding.default_external = Encoding::UTF_8
            Warning[:experimental]    = false

            %w[
                lib
            ].each do |lib|
                $LOAD_PATH.unshift File.join '\(Bundle.main.bundlePath)', lib
            end

            Dir.chdir '\(getDocumentDir().path)'
        """)

        RubySketch.setup()
        RubySketch.setActiveReflexViewController(self)
    }

    private func getDocumentDir() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    override func viewWillDisappear(_ animated: Bool) {
        RubySketch.resetActiveReflexViewController()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if started {return}
        started = true

        let frame = self.reflexView.frame
        CRuby.evaluate("""
            ENV['WIDTH']  = \(frame.width).to_s
            ENV['HEIGHT'] = \(frame.height).to_s
        """)

        RubySketch.start("\(Bundle.main.bundlePath)/main.rb");
    }
}


struct GameView : UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return GameViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
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
