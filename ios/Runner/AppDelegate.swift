import Flutter
import UIKit
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import AudioToolbox
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GMSServices.provideAPIKey("AIzaSyD12ahp2ZkpBsrUWX1fQbtxudgTx1tg49I")
    
    // Set UNUserNotificationCenter delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // We do NOT set Messaging.messaging().delegate = self here 
    // unless we intend to handle registration tokens manually.
    // However, since we disabled swizzling, we must handle it.
    Messaging.messaging().delegate = self
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup Method Channel for premium system sounds
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let soundChannel = FlutterMethodChannel(name: "com.laween.app/system_sound",
                                              binaryMessenger: controller.binaryMessenger)
    soundChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if (call.method == "playSystemSound") {
        if let args = call.arguments as? [String: Any],
           let soundId = args["soundId"] as? Int {
          AudioServicesPlaySystemSound(SystemSoundID(soundId))
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Sound ID missing", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    // Setup Method Channel for Apple Vision OCR
    let ocrChannel = FlutterMethodChannel(name: "com.laween.app/ocr",
                                           binaryMessenger: controller.binaryMessenger)
    ocrChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "recognizeText" {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "imagePath required", details: nil))
          return
        }
        self.recognizeText(imagePath: imagePath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - APNs Token Handling
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Let Firebase Messaging auto-detect the token type (Sandbox vs. Production)
    // This is the absolute correct standard method.
    Messaging.messaging().apnsToken = deviceToken
    
    // Log for debugging
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ MANUAL APNS Device Token Registered: \(tokenString)")
    
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // MARK: - UNUserNotificationCenterDelegate
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📩 Notification willPresent: \(userInfo)")
    
    // Pass notification to Firebase
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // Change this to .alert, .badge, .sound to show notification even when app is in foreground
    completionHandler([[.alert, .badge, .sound]])
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("📩 Notification didReceive: \(userInfo)")
    
    // Pass response to Firebase
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    completionHandler()
  }

  override func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("📩 Notification didReceiveRemoteNotification (Background/Fetch): \(userInfo)")
    
    // Pass notification info to Firebase Messaging
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  // MARK: - MessagingDelegate
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🚀 Firebase registration token: \(String(describing: fcmToken))")
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }

  // MARK: - Apple Vision OCR
  private func recognizeText(imagePath: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: imagePath),
          let cgImage = image.cgImage else {
      result(FlutterError(code: "IMAGE_ERROR", message: "Could not load image", details: nil))
      return
    }

    let request = VNRecognizeTextRequest { (request, error) in
      if let error = error {
        result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
        return
      }

      guard let observations = request.results as? [VNRecognizedTextObservation] else {
        result([String]())
        return
      }

      var lines = [String]()
      for observation in observations {
        if let topCandidate = observation.topCandidates(1).first {
          lines.append(topCandidate.string)
        }
      }
      result(lines)
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    // Support both English and Arabic
    request.recognitionLanguages = ["en-US", "ar"]

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
      } catch {
        result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
      }
    }
  }
}
