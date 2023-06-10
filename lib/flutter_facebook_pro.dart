import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
/// A singleton class for plugin
/// so that multiple streams dont open up

class FlutterFacebookPro {
  static final FlutterFacebookPro? _singleton = FlutterFacebookPro._internal();

  factory FlutterFacebookPro() {
    return _singleton!;
  }

  FlutterFacebookPro._internal();

  /// Method Channel Initilization to register method calls
  static const MethodChannel _channel =
  const MethodChannel('flutter_facebook_sdk/methodChannel');
  static const eventNameCompletedRegistration =
      'fb_mobile_complete_registration';
  static const eventNameViewedContent = 'fb_mobile_content_view';
  static const eventNameRated = 'fb_mobile_rate';
  static const eventNameInitiatedCheckout = 'fb_mobile_initiated_checkout';
  static const eventNameAddedToCart = 'fb_mobile_add_to_cart';
  static const eventNameAddedToWishlist = 'fb_mobile_add_to_wishlist';
  static const eventNameSubscribe = "Subscribe";
  static const eventNameStartTrial = "StartTrial";
  static const eventNameAdImpression = "AdImpression";
  static const eventNameAdClick = "AdClick";
  static const paramNameAdType = "fb_ad_type";
  static const paramNameCurrency = "fb_currency";
  static const paramNameOrderId = "fb_order_id";
  static const paramNameRegistrationMethod = "fb_registration_method";
  static const paramNamePaymentInfoAvailable = "fb_payment_info_available";
  static const paramNameNumItems = "fb_num_items";
  static const paramValueYes = "1";
  static const paramValueNo = "0";

  /// Parameter key used to specify a generic content type/family for the logged event, e.g.
  /// "music", "photo", "video".  Options to use will vary depending on the nature of the app.
  static const paramNameContentType = "fb_content_type";

  /// Parameter key used to specify data for the one or more pieces of content being logged about.
  /// Data should be a JSON encoded string.
  /// Example:
  ///   "[{\"id\": \"1234\", \"quantity\": 2, \"item_price\": 5.99}, {\"id\": \"5678\", \"quantity\": 1, \"item_price\": 9.99}]"
  static const paramNameContent = "fb_content";

  /// Parameter key used to specify an ID for the specific piece of content being logged about.
  /// This could be an EAN, article identifier, etc., depending on the nature of the app.
  static const paramNameContentId = "fb_content_id";
  /// Event Channel to listen to event changes
  static const EventChannel _eventChannel =
  const EventChannel("flutter_facebook_sdk/eventChannel");

  Stream<String>? _onDeepLinkReceived;

  /// Returns a stream listener to handle deep link url changes
  /// Add a listener to this event to get updated deep link url
  /// ``` dart
  /// facebookDeepLinks = FlutterFacebookSdk();
  /// facebookDeepLinks.onDeepLinkReceived.listen((event) {
  /// setState(() {
  /// _deepLinkUrl = event;
  /// });
  /// });
  /// ```
  Stream<String>? get onDeepLinkReceived {
    if (_onDeepLinkReceived == null) {
      _onDeepLinkReceived =
          _eventChannel.receiveBroadcastStream().cast<String>();
    }
    return _onDeepLinkReceived;
  }

  /// Returns the platform version of the running device
  Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Returns deep link url
  Future<String?> get getDeepLinkUrl async {
    final String? url = await _channel.invokeMethod('getDeepLinkUrl');
    return url;
  }

  /// Logs App Activate Event of FBSDK
  Future<bool> logActivateApp() async {
    await _channel.invokeMethod("activateApp");
    return true;
  }

  /// Init Facebook SDK
  Future<bool?> initSdk() async {
    return await _channel.invokeMethod("initFbSdk");
  }

  /// Returns the app ID this logger was configured to log to.
  Future<String?> getApplicationId() {
    return _channel.invokeMethod<String>('getApplicationId');
  }

  Future<String?> getAnonymousId() {
    return _channel.invokeMethod<String>('getAnonymousId');
  }

  /// Explicitly flush any stored events to the server.
  Future<void> flush() {
    return _channel.invokeMethod<void>('flush');
  }

  /// Clears the currently set user id.
  Future<void> clearUserID() {
    return _channel.invokeMethod<void>('clearUserID');
  }
  /// Clears the current user data
  Future<void> clearUserData() {
    return _channel.invokeMethod<void>('clearUserData');
  }
  /// Sets user data to associate with all app events.
  /// All user data are hashed and used to match Facebook user from this
  /// instance of an application. The user data will be persisted between
  /// application instances.
  Future<void> setUserData({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? state,
    String? zip,
    String? country,
  }) {
    final args = <String, dynamic>{
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
    };

    return _channel.invokeMethod<void>('setUserData', args);
  }

  /// Log this event when the user has viewed a form of content in the app.
  ///
  /// See: https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/#eventnameviewedcontent
  Future<void> logViewContent({
    Map<String, dynamic>? content,
    String? id,
    String? type,
    String? currency,
    double? price,
  }) {
    return logEvent(
      eventName: eventNameViewedContent,
      parameters: {
        paramNameContent: content != null ? json.encode(content) : null,
        paramNameContentId: id,
        paramNameContentType: type,
        paramNameCurrency: currency,
      },
      valueToSum: price,
    );
  }

  /// Logs Add to Cart Event of FBSDK with [currency] and [price]
  Future<bool> logAddToCart(
      {required String contentType,
        required String contentData,
        required String contentId,
        required String currency,
        required double price}) async {
    final bool result = await _channel.invokeMethod("logAddToCart", {
      "contentType": contentType,
      "contentData": contentData,
      "contentId": contentId,
      "currency": currency,
      "price": price
    });
    return result;
  }

  /// Log this event when the user has added item to cart
  ///
  /// See: https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/#eventnameaddedtowishlist
  Future<void> logAddToWishlist({
    Map<String, dynamic>? content,
    required String id,
    required String type,
    required String currency,
    required double price,
  }) {
    return logEvent(
      eventName: eventNameAddedToWishlist,
      parameters: {
        paramNameContent: content != null ? json.encode(content) : null,
        paramNameContentId: id,
        paramNameContentType: type,
        paramNameCurrency: currency,
      },
      valueToSum: price,
    );
  }

  /// Logs Complete Registration Event of FBSDK with [registrationMethod]
  Future<bool> logCompleteRegistration(
      {required String registrationMethod}) async {
    final bool result = await _channel.invokeMethod("logCompleteRegistration", {
      "registrationMethod": registrationMethod,
    });
    return result;
  }

  /// Logs Purchase Event of FBSDK with [currency] and [amount]
  Future<bool?> logPurchase({
    required double amount,
    required String currency,
    Map<String, dynamic>? parameters,
  }) {
    final args = <String, dynamic>{
      'amount': amount,
      'currency': currency,
      'parameters': parameters,
    };
    return _channel.invokeMethod<bool?>('logPurchase', _filterOutNulls(args));
  }

// ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  //
  // PRIVATE METHODS BELOW HERE

  /// Creates a new map containing all of the key/value pairs from [parameters]
  /// except those whose value is `null`.
  Map<String, dynamic> _filterOutNulls(Map<String, dynamic> parameters) {
    final Map<String, dynamic> filtered = <String, dynamic>{};
    parameters.forEach((String key, dynamic value) {
      if (value != null) {
        filtered[key] = value;
      }
    });
    return filtered;
  }
  /// Logs Search Event of FBSDK with [searchString] and [success]
  Future<bool> logSearch(
      {required String contentType,
        required String contentData,
        required String contentId,
        required String searchString,
        required bool success}) async {
    final bool result = await _channel.invokeMethod("logSearch", {
      "contentType": contentType,
      "contentData": contentData,
      "contentId": contentId,
      "searchString": searchString,
      "success": success
    });
    return result;
  }

  Future<void> logInitiatedCheckout({
    double? totalPrice,
    String? currency,
    String? contentType,
    String? contentId,
    int? numItems,
    bool paymentInfoAvailable = false,
  }) {
    return logEvent(
      eventName: eventNameInitiatedCheckout,
      valueToSum: totalPrice,
      parameters: {
        paramNameContentType: contentType,
        paramNameContentId: contentId,
        paramNameNumItems: numItems,
        paramNameCurrency: currency,
        paramNamePaymentInfoAvailable:
        paymentInfoAvailable ? paramValueYes : paramValueNo,
      },
    );
  }
  /// Logs Initiate Checkout Event of FBSDK with [numItems] and [paymentInfoAvailable]
  Future<bool> logInitiateCheckout(
      {required String contentType,
        required String contentData,
        required String contentId,
        required int numItems,
        required bool paymentInfoAvailable,
        required String currency,
        required double totalPrice}) async {
    final bool result = await _channel.invokeMethod("logInitiateCheckout", {
      "contentType": contentType,
      "contentData": contentData,
      "contentId": contentId,
      "numItems": numItems,
      "paymentInfoAvailable": paymentInfoAvailable,
      "currency": currency,
      "totalPrice": totalPrice
    });
    return result;
  }

  /// A generic function to log facebook app events
  /// This can be used in place of other log event functions present in the plugin
  /// But for logging purchase you will have to explicityly use the [logPurhcase] method
  /// ``` dart
  /// await logEvent(
  ///   eventName: "fb_mobile_add_payment_info",
  ///   parameters: {
  ///     'SUCCESS': "true",
  ///   },
  ///   valueToSum: 55
  /// ),
  /// ```
  Future<bool> logEvent(
      {required String eventName,
        double? valueToSum,
        dynamic parameters}) async {
    final bool result = await _channel.invokeMethod("logEvent", {
      'eventName': eventName,
      'valueToSum': valueToSum,
      'parameters': parameters
    });
    return result;
  }

  /// Only Available in iOS
  /// Set the advertiser tracking to truue or false
  /// App events won't work if this is disabled
  /// Sets the Advert Tracking propeety for iOS advert tracking
  /// an iOS 14+ feature, android should just return a success.
  Future<void> setAdvertiserTracking({
    required bool enabled,
    bool collectId = true,
  }) {
    final args = <String, dynamic>{
      'enabled': enabled,
      'collectId': collectId,
    };

    return _channel.invokeMethod<void>('setAdvertiserTracking', args);
  }

  /// The start of a paid subscription for a product or service you offer.
  /// See:
  ///   - https://developers.facebook.com/docs/marketing-api/app-event-api/
  ///   - https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/
  Future<void> logSubscribe({
    double? price,
    String? currency,
    required String orderId,
  }) {
    return logEvent(
      eventName: eventNameSubscribe,
      valueToSum: price,
      parameters: {
        paramNameCurrency: currency,
        paramNameOrderId: orderId,
      },
    );
  }

  /// The start of a free trial of a product or service you offer (example: trial subscription).
  /// See:
  ///   - https://developers.facebook.com/docs/marketing-api/app-event-api/
  ///   - https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/
  Future<void> logStartTrial({
    double? price,
    String? currency,
    required String orderId,
  }) {
    return logEvent(
      eventName: eventNameStartTrial,
      valueToSum: price,
      parameters: {
        paramNameCurrency: currency,
        paramNameOrderId: orderId,
      },
    );
  }

  /// Log this event when the user views an ad.
  Future<void> logAdImpression({
    required String adType,
  }) {
    return logEvent(
      eventName: eventNameAdImpression,
      parameters: {
        paramNameAdType: adType,
      },
    );
  }

  /// Log this event when the user clicks an ad.
  Future<void> logAdClick({
    required String adType,
  }) {
    return logEvent(
      eventName: eventNameAdClick,
      parameters: {
        paramNameAdType: adType,
      },
    );
  }
}
