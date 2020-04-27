import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        Backend.shared.authenticator.reauthenticate() { _,_ in
            DispatchQueue.main.async {
                self.show(scene)
            }
        }
    }

    private func show(_ scene: UIScene) {
        let contentView = MotherView()
            .environmentObject(ViewRouter())

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
