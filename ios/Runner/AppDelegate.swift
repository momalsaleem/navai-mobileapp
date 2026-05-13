import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let factory = NativeObjectDetectionViewFactory(messenger: registrar(forPlugin: "NativeObjectDetectionViewPlugin")!.messenger())
    registrar(forPlugin: "NativeObjectDetectionViewPlugin")!.register(
        factory,
        withId: "native_object_detection_view")
        
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
