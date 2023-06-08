import SwiftUI


protocol GameViewControllerDelegate {
    func run(command: String)
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
        if let delegate = delegate, let command = CRuby.evaluate("$command")?.toString() {
            delegate.run(command: command)
        } else {
            super.update()
        }
    }
}


struct GameView: UIViewControllerRepresentable {

    @Binding var command: String

    func makeCoordinator() -> Coordinator {
        Coordinator(command: $command)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = GameViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        let c = context.coordinator
        if c.prevCommand != nil && command.isEmpty {
            CRuby.evaluate("$command = nil")
            c.prevCommand = nil
        }
    }

    class Coordinator: NSObject, GameViewControllerDelegate {

        @Binding var command: String

        var prevCommand: String?

        init(command: Binding<String>) {
            _command = command
        }

        func run(command: String) {
            if command != prevCommand {
                self.command = command
                prevCommand = command
            }
        }
    }
}
