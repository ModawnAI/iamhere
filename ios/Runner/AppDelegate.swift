import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // This is required for model_viewer_plus on iOS to use the camera in AR.
    let webView = WKWebView(frame: .zero)
    if #available(iOS 15.4, *) {
        webView.configuration.preferences.isElementFullscreenEnabled = true
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
