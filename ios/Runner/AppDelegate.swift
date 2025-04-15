import Flutter
import UIKit
import MapboxMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Инициализация Mapbox
    let key = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String
    if let accessToken = key {
        MapboxOptions.accessToken = accessToken
        print("Mapbox access token set from native code")
    } else {
        print("No Mapbox access token found in Info.plist")
    }
    
    // Создаем канал для связи с Flutter
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
        name: "com.tap_map/native_communication",
        binaryMessenger: controller.binaryMessenger)
    
    // Обработка сообщений от Flutter
    channel.setMethodCallHandler({ [weak self] (call, result) in
        if call.method == "initializeMapbox" {
            if let mapboxToken = call.arguments as? String {
                MapboxOptions.accessToken = mapboxToken
                print("Mapbox access token set from Flutter")
                result(true)
            } else {
                result(FlutterError(code: "INVALID_TOKEN", message: "Token is invalid", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
} 