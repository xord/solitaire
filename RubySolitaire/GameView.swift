import SwiftUI


protocol GameViewControllerDelegate {
    func showInterstitialAd()
}


class GameViewController: ReflexViewController {

    var delegate: GameViewControllerDelegate?

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

    override func update() {
        if CRuby.evaluate("$showInterstitialAd")?.toBOOL() == true, let delegate = delegate {
            delegate.showInterstitialAd()
        } else {
            super.update()
        }
    }
}


struct GameView: UIViewControllerRepresentable {

    @Binding var isInterstitialAdVisible: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isInterstitialAdVisible: $isInterstitialAdVisible)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = GameViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        let c = context.coordinator
        if c.prevVisible && !isInterstitialAdVisible {
            CRuby.evaluate("$showInterstitialAd = false")
        }
        c.prevVisible = isInterstitialAdVisible
    }

    class Coordinator: NSObject, GameViewControllerDelegate {

        @Binding var isIntersittialAdVisible: Bool

        var prevVisible = false

        init(isInterstitialAdVisible: Binding<Bool>) {
            _isIntersittialAdVisible = isInterstitialAdVisible
        }

        func showInterstitialAd() {
            if !prevVisible {
                isIntersittialAdVisible = true
                prevVisible = true
            }
        }
    }
}
