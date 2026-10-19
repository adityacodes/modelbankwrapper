import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    for urlContext in connectionOptions.urlContexts {
      ModelBankGatewayManager.shared.handleDeepLink(urlContext.url.absoluteString)
    }

    for userActivity in connectionOptions.userActivities {
      if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
         let url = userActivity.webpageURL {
        ModelBankGatewayManager.shared.handleDeepLink(url.absoluteString)
      }
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for urlContext in URLContexts {
      ModelBankGatewayManager.shared.handleDeepLink(urlContext.url.absoluteString)
    }
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      ModelBankGatewayManager.shared.handleDeepLink(url.absoluteString)
    }
  }
}
