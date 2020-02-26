import Flutter
import UIKit

public class SwiftNotificationPermissionsPlugin: NSObject, FlutterPlugin {
  var permissionGranted:String = "granted"
  var permissionUnknown:String = "unknown"
  var permissionDenied:String = "denied"

  public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: "notification_permissions", binaryMessenger: registrar.messenger())
      let instance = SwiftNotificationPermissionsPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if (call.method == "requestNotificationPermissions") {
          // check if we can ask for permissions
          getNotificationStatus(completion: { status in
              if (status == self.permissionUnknown) {
                  // If the permission status is unknown, the user hasn't denied it
                  if let arguments = call.arguments as? Dictionary<String, Bool> {
                      if #available(iOS 10.0, *) {
                          var options = UNAuthorizationOptions()
                          if arguments["sound"] != nil {
                              options.insert(.sound)
                          }
                          if arguments["alert"] != nil  {
                              options.insert(.alert)
                          }
                          if arguments["badge"] != nil  {
                              options.insert(.badge)
                          }

                          let center = UNUserNotificationCenter.current()
                          center.requestAuthorization(options: options) { (_/*granted*/, _/*error*/) in
                              // ignoring granted and error parameter
                              result(nil)
                          }
                      } else {
                          var notificationTypes = UIUserNotificationType(rawValue: 0)
                          if arguments["sound"] != nil {
                              notificationTypes.insert(UIUserNotificationType.sound)
                          }
                          if arguments["alert"] != nil  {
                              notificationTypes.insert(UIUserNotificationType.alert)
                          }
                          if arguments["badge"] != nil  {
                              notificationTypes.insert(UIUserNotificationType.badge)
                          }

                          let settings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
                          UIApplication.shared.registerUserNotificationSettings(settings)

                          result(nil)
                      }
                  } else {
                      result(nil)
                  }
              } else if (status == self.permissionDenied) {
                  // The user has denied the permission he must go to the settings screen
                  if let url = URL(string:UIApplication.openSettingsURLString) {
                      if UIApplication.shared.canOpenURL(url) {
                          if #available(iOS 10.0, *) {
                              UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                          } else {
                              UIApplication.shared.openURL(url)
                          }
                      }
                  }
                  result(nil)
              } else {
                  result(nil)
              }
          })
      } else if (call.method == "getNotificationPermissionStatus") {
          getNotificationStatus(completion: { status in
              result(status)
          })
      } else {
          result(FlutterMethodNotImplemented)
      }
  }

  func getNotificationStatus(completion: @escaping ((String) -> Void)) {
      if #available(iOS 10.0, *) {
          let current = UNUserNotificationCenter.current()
          current.getNotificationSettings(completionHandler: { settings in
              if settings.authorizationStatus == .notDetermined || (#available(iOS 12.0, *) && settings.authorizationStatus == .provisional) {
                  completion(self.permissionUnknown)
              } else if settings.authorizationStatus == .denied {
                  completion(self.permissionDenied)
              } else if settings.authorizationStatus == .authorized {
                  completion(self.permissionGranted)
              }
          })
      } else {
          // Fallback on earlier versions
          if UIApplication.shared.isRegisteredForRemoteNotifications {
              completion(self.permissionGranted)
          } else {
              completion(self.permissionDenied)
          }
      }
  }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
