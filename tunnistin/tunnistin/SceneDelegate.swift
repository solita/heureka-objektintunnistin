import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    _ = AppConfig.shared // initialize configuration from JSON

    if let windowScene = scene as? UIWindowScene {
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = LaunchViewController()

      self.window = window
      window.backgroundColor = UIColor.Heureka
      window.makeKeyAndVisible()
    }
  }
}
