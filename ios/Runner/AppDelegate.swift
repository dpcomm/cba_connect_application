import UIKit
import Flutter
import KakaoMapsSDK

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    /** Flavor Setup */
    let controller = window.rootViewController as! FlutterViewController
    
    let flavorChannel = FlutterMethodChannel(
        name: "flavor",
        binaryMessenger: controller.binaryMessenger
    )

    flavorChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        // Note: this method is invoked on the UI thread
        let flavor = Bundle.main.infoDictionary?["App-Flavor"]
        result(flavor)
    })

    /** Kakao Map Plugin Setup */
    if let kakaoKey = Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String {
        SDKInitializer.InitSDK(appKey: kakaoKey)
    } else {
        fatalError("⚠️ Info.plist 에 KAKAO_APP_KEY 가 설정되지 않았습니다.")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
