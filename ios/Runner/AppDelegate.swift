import Flutter
import AMapFoundationKit
import AMapLocationKit
import MAMapKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAMap()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureAMap() {
    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)
    AMapLocationManager.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    AMapLocationManager.updatePrivacyAgree(.didAgree)

    guard
      let infoDictionary = Bundle.main.infoDictionary,
      let apiKey = infoDictionary["AMapApiKey"] as? String,
      apiKey.isEmpty == false,
      apiKey.hasPrefix("$(") == false
    else {
      return
    }

    AMapServices.shared().apiKey = apiKey
  }
}
