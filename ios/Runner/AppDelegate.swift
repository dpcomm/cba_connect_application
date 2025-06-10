import Flutter
import UIKit
import KakaoMapsSDK

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let kakaoKey = Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String {
        SDKInitializer.InitSDK(appKey: kakaoKey)
    } else {
        fatalError("⚠️ Info.plist 에 KAKAO_APP_KEY 가 설정되지 않았습니다.")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
