import Flutter
import AMapFoundationKit
import MAMapKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var deviceChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAMap()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SpeechPlugin") {
      SpeechPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AidrunDeviceRuntimePlugin") {
      deviceChannel = FlutterMethodChannel(
        name: Self.deviceChannelName,
        binaryMessenger: registrar.messenger()
      )
      deviceChannel?.setMethodCallHandler { [weak self] call, result in
        self?.handleDeviceMethodCall(call, result: result)
      }
    }
  }

  private func configureAMap() {
    guard
      let apiKey = amapApiKey,
      !apiKey.isEmpty
    else {
      return
    }

    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)
    AMapServices.shared().apiKey = apiKey
  }

  private var amapApiKey: String? {
    Bundle.main.object(forInfoDictionaryKey: "AMapApiKey") as? String
  }

  private func handleDeviceMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getIosRuntimeConfig":
      result([
        "amapIosKey": amapApiKey ?? "",
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static let deviceChannelName = "aidrun/device"
}
