import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var overlay: UIWindow?
    var timer: Timer?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let main = UIWindow(windowScene: scene)
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground
        let label = UILabel(frame: CGRect(x: 30, y: 140, width: 320, height: 100))
        label.text = "Persistent main window"
        label.accessibilityIdentifier = "main-label"
        controller.view.addSubview(label)
        main.rootViewController = controller
        main.makeKeyAndVisible()
        window = main
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.showOverlay(scene: scene)
        }
    }

    private func showOverlay(scene: UIWindowScene) {
        let extra = UIWindow(windowScene: scene)
        extra.windowLevel = .alert
        let controller = UIViewController()
        controller.view.backgroundColor = .systemYellow
        let label = UILabel(frame: CGRect(x: 30, y: 300, width: 320, height: 100))
        label.text = "Temporary overlay"
        controller.view.addSubview(label)
        extra.rootViewController = controller
        extra.isHidden = false
        overlay = extra
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self, weak extra] in
            extra?.isHidden = true
            if self?.overlay === extra { self?.overlay = nil }
        }
    }
}
