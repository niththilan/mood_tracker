import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Note: Using Supabase OAuth for Google authentication
    // No need for GoogleSignIn native configuration
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
