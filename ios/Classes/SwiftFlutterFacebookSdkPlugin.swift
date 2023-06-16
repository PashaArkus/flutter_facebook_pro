import Flutter
import UIKit
import FBSDKCoreKit
import FBSDKCoreKit_Basics

let PLATFORM_CHANNEL = "flutter_facebook_sdk/methodChannel"
let EVENTS_CHANNEL = "flutter_facebook_sdk/eventChannel"

public class SwiftFlutterFacebookSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    var _eventSink: FlutterEventSink?
    var deepLinkUrl:String = ""
    var _queuedLinks = [String]()

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        _queuedLinks.forEach({ events($0) })
        _queuedLinks.removeAll()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil
    }


    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterFacebookSdkPlugin()

        let channel = FlutterMethodChannel(name: PLATFORM_CHANNEL, binaryMessenger: registrar.messenger())

        let eventChannel = FlutterEventChannel(name: EVENTS_CHANNEL, binaryMessenger: registrar.messenger())

        eventChannel.setStreamHandler(instance)

        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        Settings.shared.isAdvertiserTrackingEnabled = true
        let launchOptionsForFacebook = launchOptions as? [UIApplication.LaunchOptionsKey: Any]
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions:
                launchOptionsForFacebook
        )
        AppLinkUtility.fetchDeferredAppLink{ (url, error) in
            if let error = error{
                print("Error %a", error)
            }
            if let url = url {
                self.deepLinkUrl = url.absoluteString
                self.sendMessageToStream(link: self.deepLinkUrl)
            }
        }
       return true
    }

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        deepLinkUrl = url.absoluteString
        self.sendMessageToStream(link: deepLinkUrl)
        return ApplicationDelegate.shared.application(application, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        //        AppEvents.activateApp()
    }

    func logSearchEvent(
        contentType: String,
        contentData: String,
        contentId: String,
        searchString: String,
        success: Bool
    ) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .contentType: contentType,
            .content: contentData,
            .contentID: contentId,
            .searchString: searchString,
            .success: NSNumber(value: success ? 1 : 0)
        ]

        AppEvents.shared.logEvent(.searched, parameters: parameters)
    }


    func sendMessageToStream(link:String){
        guard let eventSink = _eventSink else {
            _queuedLinks.append(link)
            return
        }
        eventSink(link)

    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "getDeepLinkUrl":
            result(deepLinkUrl)
        case "clearUserData":
            handleClearUserData(call, result: result)
            break
        case "setUserData":
            handleSetUserData(call, result: result)
            break
        case "clearUserID":
            handleClearUserID(call, result: result)
            break
        case "flush":
            handleFlush(call, result: result)
            break
        case "logSearch":
            guard let args = call.arguments else {
                result(false)
                return
            }
            if let myArgs = args as? [String: Any],
               let contentType = myArgs["contentType"] as? String,
               let contentData = myArgs["contentData"] as? String,
               let contentId = myArgs["contentId"] as? String,
               let searchString = myArgs["searchString"] as? String,
               let success = myArgs["success"] as? Bool{
                self.logSearchEvent(contentType: contentType, contentData: contentData, contentId: contentId, searchString: searchString, success: success)
                result(true)
                return
            }
        case "getApplicationId":
            handleGetApplicationId(call, result: result)
            break
        case "logEvent":
            handleLogEvent(call, result: result)
            break
        case "logPushNotificationOpen":
            handlePushNotificationOpen(call, result: result)
            break
        case "setUserID":
            handleSetUserId(call, result: result)
            break
        case "setAutoLogAppEventsEnabled":
            handleSetAutoLogAppEventsEnabled(call, result: result)
            break
        case "setDataProcessingOptions":
            handleSetDataProcessingOptions(call, result: result)
            break
        case "logPurchase":
            handlePurchased(call, result: result)
            break
        case "getAnonymousId":
            handleHandleGetAnonymousId(call, result: result)
            break
        case "setAdvertiserTracking":
            handleSetAdvertiserTracking(call, result: result)
            break
        case "logInitiateCheckout":
            guard let args = call.arguments else {
                result(false)
                return
            }
            if let myArgs = args as? [String: Any],
               let contentType = myArgs["contentType"] as? String,
               let contentData = myArgs["contentData"] as? String,
               let contentId = myArgs["contentId"] as? String,
               let numItems = myArgs["numItems"] as? Int,
               let paymentInfoAvailable = myArgs["paymentInfoAvailable"] as? Bool,
               let currency = myArgs["currency"] as? String,
               let totalPrice = myArgs["totalPrice"] as? Double{
                self.logInitiateCheckoutEvent(contentData: contentData, contentId: contentId, contentType: contentType, numItems: numItems, paymentInfoAvailable: paymentInfoAvailable, currency: currency, totalPrice: totalPrice)
                result(true)
                return
            }
        case "logCompleteRegistration":
            guard let args = call.arguments else {
                result(false)
                return
            }
            if let myArgs = args as? [String: Any],
               let registrationMethod = myArgs["registrationMethod"] as? String{
                self.logCompleteRegistrationEvent(registrationMethod: registrationMethod)
                result(true)
                return
            }
        case "activateApp":
            AppEvents.shared.activateApp()
            result(true)
            return
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleClearUserData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            AppEvents.shared.clearUserData()
            result(nil)
        }

    private func handleSetUserData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            let arguments = call.arguments as? [String: Any] ?? [String: Any]()

            AppEvents.shared.setUserData(arguments["email"] as? String, forType: FBSDKAppEventUserDataType.email)
            AppEvents.shared.setUserData(arguments["firstName"] as? String, forType: FBSDKAppEventUserDataType.firstName)
            AppEvents.shared.setUserData(arguments["lastName"] as? String, forType: FBSDKAppEventUserDataType.lastName)
            AppEvents.shared.setUserData(arguments["phone"] as? String, forType: FBSDKAppEventUserDataType.phone)
            AppEvents.shared.setUserData(arguments["dateOfBirth"] as? String, forType: FBSDKAppEventUserDataType.dateOfBirth)
            AppEvents.shared.setUserData(arguments["gender"] as? String, forType: FBSDKAppEventUserDataType.gender)
            AppEvents.shared.setUserData(arguments["city"] as? String, forType: FBSDKAppEventUserDataType.city)
            AppEvents.shared.setUserData(arguments["state"] as? String, forType: FBSDKAppEventUserDataType.state)
            AppEvents.shared.setUserData(arguments["zip"] as? String, forType: FBSDKAppEventUserDataType.zip)
            AppEvents.shared.setUserData(arguments["country"] as? String, forType: FBSDKAppEventUserDataType.country)

            result(nil)
        }

    private func handleClearUserID(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        AppEvents.shared.userID = nil
        result(nil)
    }

    private func handleHandleGetAnonymousId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(AppEvents.shared.anonymousID)
    }

    private func handleLogEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let eventName = arguments["eventName"] as! String
        let parameters = arguments["parameters"] as? [AppEvents.ParameterName: Any] ?? [AppEvents.ParameterName: Any]()
        if arguments["valueToSum"] != nil && !(arguments["valueToSum"] is NSNull) {
            let valueToDouble = arguments["valueToSum"] as! Double
            AppEvents.shared.logEvent(AppEvents.Name(eventName), valueToSum: valueToDouble, parameters: parameters)
        } else {
            AppEvents.shared.logEvent(AppEvents.Name(eventName), parameters: parameters)
        }

        result(nil)
    }

    private func handleFlush(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        AppEvents.shared.flush()
        result(nil)
    }

    private func handlePushNotificationOpen(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let payload = arguments["payload"] as? [String: Any]
        if let action = arguments["action"] {
            let actionString = action as! String
            AppEvents.shared.logPushNotificationOpen(payload: payload!, action: actionString)
        } else {
            AppEvents.shared.logPushNotificationOpen(payload: payload!)
        }

        result(nil)
    }

    private func handleSetUserId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let id = call.arguments as! String
        AppEvents.shared.userID = id
        result(nil)
    }

    private func handleSetAutoLogAppEventsEnabled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let enabled = call.arguments as! Bool
        Settings.shared.isAutoLogAppEventsEnabled = enabled
        result(nil)
    }

    private func handleSetDataProcessingOptions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let modes = arguments["options"] as? [String] ?? []
        let state = arguments["state"] as? Int32 ?? 0
        let country = arguments["country"] as? Int32 ?? 0

        Settings.shared.setDataProcessingOptions(modes, country: country, state: state)

        result(nil)
    }

    private func handlePurchased(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let amount = arguments["amount"] as! Double
        let currency = arguments["currency"] as! String
        let parameters = arguments["parameters"] as? [AppEvents.ParameterName: Any] ?? [AppEvents.ParameterName: Any]()
        AppEvents.shared.logPurchase(amount: amount, currency: currency, parameters: parameters)

        result(nil)
    }

    private func handleGetApplicationId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(Settings.shared.appID)
    }

    private func handleSetAdvertiserTracking(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let enabled = arguments["enabled"] as! Bool
        let collectId = arguments["collectId"] as! Bool
//         FBAdSettings.setAdvertiserTrackingEnabled(enabled)
        Settings.shared.isAdvertiserTrackingEnabled = enabled
        Settings.shared.isAdvertiserIDCollectionEnabled = collectId
        result(nil)
    }

    func logInitiateCheckoutEvent(
        contentData: String,
        contentId: String,
        contentType: String,
        numItems: Int,
        paymentInfoAvailable: Bool,
        currency: String,
        totalPrice: Double
    ) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .content: contentData,
            .contentID: contentId,
            .contentType: contentType,
            .numItems: NSNumber(value: numItems),
            .paymentInfoAvailable: NSNumber(value: paymentInfoAvailable ? 1 : 0),
            .currency: currency
        ]

        AppEvents.shared.logEvent(.initiatedCheckout, valueToSum: totalPrice, parameters: parameters)
    }

    func logCompleteRegistrationEvent(registrationMethod: String) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .registrationMethod: registrationMethod
        ]
        AppEvents.shared.logEvent(.completedRegistration, parameters: parameters)
    }

}