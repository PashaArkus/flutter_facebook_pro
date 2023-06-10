package app.dev.flutter_facebook_pro

import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsConstants
import com.facebook.appevents.AppEventsLogger
import com.facebook.applinks.AppLinkData
import com.facebook.bolts.AppLinks
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.lang.NullPointerException
import java.util.*
import kotlin.collections.HashMap
import kotlin.math.log


/** FlutterFacebookSdkPlugin */
class FlutterFacebookSdkPlugin : FlutterPlugin, MethodCallHandler, StreamHandler, ActivityAware, PluginRegistry.NewIntentListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity

    private lateinit var registrar: Registrar
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var appEventsLogger: AppEventsLogger
    private lateinit var anonymousId: String

    private var deepLinkUrl: String = "Saad Farhan"
    private var PLATFORM_CHANNEL: String = "flutter_facebook_sdk/methodChannel"
    private var EVENTS_CHANNEL: String = "flutter_facebook_sdk/eventChannel"
    private var queuedLinks: List<String> = emptyList()
    private var eventSink: EventSink? = null
    private lateinit var context: Context
    private var activityPluginBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, PLATFORM_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENTS_CHANNEL)
        eventChannel.setStreamHandler(this)
        context = flutterPluginBinding.applicationContext
        appEventsLogger = AppEventsLogger.newLogger(context)
        anonymousId = AppEventsLogger.getAnonymousAppDeviceGUID(flutterPluginBinding.applicationContext)
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "getDeepLinkUrl" -> {
                result.success(deepLinkUrl)
            }
            "activateApp" -> {
                appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_ACTIVATED_APP)
            }
            "logCompleteRegistration" -> {
                val args = call.arguments as HashMap<String, Any>
                val params = Bundle()
                params.putString(AppEventsConstants.EVENT_PARAM_REGISTRATION_METHOD, args["registrationMethod"].toString())
                appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_COMPLETED_REGISTRATION, params)
            }
            "logSearch" -> {
                val args = call.arguments as HashMap<String, Any>
                logSearchEvent(args["contentType"].toString(), args["contentData"].toString(), args["contentId"].toString(), args["searchString"].toString(), args["success"].toString().toBoolean())
            }
            "logInitiateCheckout" -> {
                val args = call.arguments as HashMap<String, Any>
                logInitiateCheckoutEvent(args["contentData"].toString(), args["contentId"].toString(), args["contentType"].toString(), args["numItems"].toString().toInt(), args["paymentInfoAvailable"].toString().toBoolean(), args["currency"].toString(), args["totalPrice"].toString().toDouble())
            }
            "clearUserData" -> handleClearUserData(call, result)
            "setUserData" -> handleSetUserData(call, result)
            "clearUserID" -> handleClearUserId(call, result)
            "flush" -> handleFlush(call, result)
            "getApplicationId" -> handleGetApplicationId(call, result)
            "logEvent" -> handleLogEvent(call, result)
            "logPushNotificationOpen" -> handlePushNotificationOpen(call, result)
            "setUserID" -> handleSetUserId(call, result)
            "setAutoLogAppEventsEnabled" -> handleSetAutoLogAppEventsEnabled(call, result)
            "setDataProcessingOptions" -> handleSetDataProcessingOptions(call, result)
            "getAnonymousId" -> handleGetAnonymousId(call, result)
            "logPurchase" -> handlePurchased(call, result)
            "setAdvertiserTracking" -> handleSetAdvertiserTracking(call, result)
            else -> result.notImplemented()
        }
    }
    private fun logGenericEvent(args : HashMap<String, Any>){
        val eventName = args["eventName"] as? String
        val valueToSum = args["valueToSum"] as? Double
        val parameters = args["parameters"] as? HashMap<String, Any>
        if (valueToSum != null && parameters != null) {
            val parameterBundle = createBundleFromMap(args["parameters"] as HashMap<String, Any>)
            appEventsLogger.logEvent(eventName, valueToSum, parameterBundle)
        }else if(parameters != null){
            val parameterBundle = createBundleFromMap(args["parameters"] as HashMap<String, Any>)
            appEventsLogger.logEvent(eventName, parameterBundle)
        }else if(valueToSum != null){
            appEventsLogger.logEvent(eventName, valueToSum)
        }else{
            appEventsLogger.logEvent(eventName)
        }
    }

    private fun logInitiateCheckoutEvent(contentData: String?, contentId: String?, contentType: String?, numItems: Int, paymentInfoAvailable: Boolean, currency: String?, totalPrice: Double) {
        val params = Bundle()
        params.putString(AppEventsConstants.EVENT_PARAM_CONTENT, contentData)
        params.putString(AppEventsConstants.EVENT_PARAM_CONTENT_ID, contentId)
        params.putString(AppEventsConstants.EVENT_PARAM_CONTENT_TYPE, contentType)
        params.putInt(AppEventsConstants.EVENT_PARAM_NUM_ITEMS, numItems)
        params.putInt(AppEventsConstants.EVENT_PARAM_PAYMENT_INFO_AVAILABLE, if (paymentInfoAvailable) 1 else 0)
        params.putString(AppEventsConstants.EVENT_PARAM_CURRENCY, currency)
        appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_INITIATED_CHECKOUT, totalPrice, params)
    }

    private fun logSearchEvent(contentType: String, contentData: String, contentId: String, searchString: String, success: Boolean) {
        val params = Bundle()
        params.putString(AppEventsConstants.EVENT_PARAM_CONTENT_TYPE, contentType)
        params.putString(AppEventsConstants.EVENT_PARAM_CONTENT, contentData)
        params.putString(AppEventsConstants.EVENT_PARAM_CONTENT_ID, contentId)
        params.putString(AppEventsConstants.EVENT_PARAM_SEARCH_STRING, searchString)
        params.putInt(AppEventsConstants.EVENT_PARAM_SUCCESS, if (success) 1 else 0)
        appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_SEARCHED, params)
    }
    private fun handleClearUserData(call: MethodCall, result: Result) {
        AppEventsLogger.clearUserData()
        result.success(null)
    }

    private fun handleSetUserData(call: MethodCall, result: Result) {
        val parameters = call.argument("parameters") as? Map<String, Object>
        val parameterBundle = createBundleFromMap(parameters)

        AppEventsLogger.setUserData(
                parameterBundle?.getString("email"),
                parameterBundle?.getString("firstName"),
                parameterBundle?.getString("lastName"),
                parameterBundle?.getString("phone"),
                parameterBundle?.getString("dateOfBirth"),
                parameterBundle?.getString("gender"),
                parameterBundle?.getString("city"),
                parameterBundle?.getString("state"),
                parameterBundle?.getString("zip"),
                parameterBundle?.getString("country")
        )

        result.success(null)
    }

    private fun handleClearUserId(call: MethodCall, result: Result) {
        AppEventsLogger.clearUserID()
        result.success(null)
    }

    private fun handleFlush(call: MethodCall, result: Result) {
        appEventsLogger.flush()
        result.success(null)
    }

    private fun handleGetApplicationId(call: MethodCall, result: Result) {
        result.success(appEventsLogger.applicationId)
    }

    private fun handleGetAnonymousId(call: MethodCall, result: Result) {
        result.success(anonymousId)
    }

    //not an android implementation as of yet
    private fun handleSetAdvertiserTracking(call: MethodCall, result: Result) {
        result.success(null);
    }

    private fun handleLogEvent(call: MethodCall, result: Result) {
        val eventName = call.argument("eventName") as? String
        val parameters = call.argument("parameters") as? Map<String, Object>
        val valueToSum = call.argument("valueToSum") as? Double

        if (valueToSum != null && parameters != null) {
            val parameterBundle = createBundleFromMap(parameters)
            appEventsLogger.logEvent(eventName, valueToSum, parameterBundle)
        } else if (valueToSum != null) {
            appEventsLogger.logEvent(eventName, valueToSum)
        } else if (parameters != null) {
            val parameterBundle = createBundleFromMap(parameters)
            appEventsLogger.logEvent(eventName, parameterBundle)
        } else {
            appEventsLogger.logEvent(eventName)
        }

        result.success(null)
    }

    private fun handlePushNotificationOpen(call: MethodCall, result: Result) {
        val action = call.argument("action") as? String
        val payload = call.argument("payload") as? Map<String, Object>
        val payloadBundle = createBundleFromMap(payload)!!

        if (action != null) {
            appEventsLogger.logPushNotificationOpen(payloadBundle, action)
        } else {
            appEventsLogger.logPushNotificationOpen(payloadBundle)
        }

        result.success(null)
    }

    private fun handleSetUserId(call: MethodCall, result: Result) {
        val id = call.arguments as String
        AppEventsLogger.setUserID(id)
        result.success(null)
    }

    private fun createBundleFromMap(parameterMap: Map<String, Any>?): Bundle? {
        if (parameterMap == null) {
            return null
        }

        val bundle = Bundle()
        for (jsonParam in parameterMap.entries) {
            val value = jsonParam.value
            val key = jsonParam.key
            if (value is String) {
                bundle.putString(key, value as String)
            } else if (value is Int) {
                bundle.putInt(key, value as Int)
            } else if (value is Long) {
                bundle.putLong(key, value as Long)
            } else if (value is Double) {
                bundle.putDouble(key, value as Double)
            } else if (value is Boolean) {
                bundle.putBoolean(key, value as Boolean)
            } else if (value is Map<*, *>) {
                val nestedBundle = createBundleFromMap(value as Map<String, Any>)
                bundle.putBundle(key, nestedBundle as Bundle)
            } else {
                throw IllegalArgumentException(
                        "Unsupported value type: " + value.javaClass.kotlin)
            }
        }
        return bundle
    }

    private fun handleSetAutoLogAppEventsEnabled(call: MethodCall, result: Result) {
        val enabled = call.arguments as Boolean
        FacebookSdk.setAutoLogAppEventsEnabled(enabled)
        result.success(null)
    }

    private fun handleSetDataProcessingOptions(call: MethodCall, result: Result) {
        val options = call.argument("options") as? ArrayList<String> ?: arrayListOf()
        val country = call.argument("country") as? Int ?: 0
        val state = call.argument("state") as? Int ?: 0

        FacebookSdk.setDataProcessingOptions(options.toTypedArray(), country, state)
        result.success(null)
    }

    private fun handlePurchased(call: MethodCall, result: Result) {
        var amount = (call.argument("amount") as? Double)?.toBigDecimal()
        var currency = Currency.getInstance(call.argument("currency") as? String)
        val parameters = call.argument("parameters") as? Map<String, Object>
        val parameterBundle = createBundleFromMap(parameters) ?: Bundle()

        appEventsLogger.logPurchase(amount, currency, parameterBundle)
        result.success(true)
    }

    private fun initFbSdk() {
        FacebookSdk.setAutoInitEnabled(true)
        FacebookSdk.fullyInitialize()
        AppLinkData.fetchDeferredAppLinkData(context, object : AppLinkData.CompletionHandler {
            override fun onDeferredAppLinkDataFetched(appLinkData: AppLinkData?) {

                if (appLinkData == null) {
                    return;
                }

                deepLinkUrl = appLinkData.targetUri.toString();
                if (eventSink != null) {
                    eventSink!!.success(deepLinkUrl)
                }
            }
        })
    }

    override fun onDetachedFromActivity() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityPluginBinding!!.removeOnNewIntentListener(this);
        activityPluginBinding = binding;
        binding.addOnNewIntentListener(this);
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
        binding.addOnNewIntentListener(this)
        initFbSdk()
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onNewIntent(intent: Intent): Boolean {
        /*  try {
              // some code
              deepLinkUrl = AppLinks.getTargetUrl(intent).toString()
              eventSink!!.success(deepLinkUrl)
          } catch (e: NullPointerException) {
              // handler
              return false
          }*/



        return false
    }
}