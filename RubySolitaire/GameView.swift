import SwiftUI

struct GameView: View {
    var body: some View {
        ReflexViewControllerWrapper()
    }
}

struct ReflexViewControllerWrapper : UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return ReflexViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
