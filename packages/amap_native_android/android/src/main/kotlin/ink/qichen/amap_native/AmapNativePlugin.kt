package ink.qichen.amap_native

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AmapNativePlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var search: AmapSearchHandler? = null
    private var location: AmapLocationHandler? = null
    private var route: AmapRouteHandler? = null
    private var offline: AmapOfflineHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "amap_native/core")
        channel.setMethodCallHandler(this)
        search = AmapSearchHandler(context, binding.binaryMessenger)
        location = AmapLocationHandler(context, binding.binaryMessenger)
        route = AmapRouteHandler(context, binding.binaryMessenger)
        offline = AmapOfflineHandler(context, binding.binaryMessenger)
        binding.platformViewRegistry.registerViewFactory(
            "amap_native_map_view",
            AmapMapViewFactory(binding.binaryMessenger) { null }
        )
        binding.platformViewRegistry.registerViewFactory(
            "amap_native_navi_view",
            AmapNaviViewFactory(binding.binaryMessenger) { null }
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        search?.dispose()
        location?.dispose()
        route?.dispose()
        offline?.dispose()
        search = null
        location = null
        route = null
        offline = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(call.arguments, result)
            "platformVersion" -> result.success(platformVersion())
            else -> result.notImplemented()
        }
    }

    private fun initialize(arguments: Any?, result: MethodChannel.Result) {
        val privacy = Bridge.map(arguments)
        if (!Bridge.bool(privacy, "containsPolicy") ||
            !Bridge.bool(privacy, "shown") ||
            !Bridge.bool(privacy, "agreed")
        ) {
            result.error(
                "privacy_not_agreed",
                "AMap privacy policy must be shown and agreed before initialization.",
                null
            )
            return
        }
        if (!Bridge.hasApiKey(context)) {
            result.error(
                "missing_amap_key",
                "Add com.amap.api.v2.apikey meta-data to the host AndroidManifest.xml.",
                null
            )
            return
        }
        try {
            updatePrivacy("com.amap.api.maps.MapsInitializer", context)
            updatePrivacy("com.amap.api.services.core.ServiceSettings", context)
            updatePrivacy("com.amap.api.location.AMapLocationClient", context)
            runCatching {
                updatePrivacy("com.amap.api.navi.NaviSetting", context)
            }
            AmapRuntime.initialized = true
            result.success(null)
        } catch (error: Throwable) {
            Bridge.error(result, error)
        }
    }

    private fun updatePrivacy(className: String, context: Context) {
        val clazz = Class.forName(className)
        val show = clazz.getMethod(
            "updatePrivacyShow",
            Context::class.java,
            Boolean::class.javaPrimitiveType,
            Boolean::class.javaPrimitiveType
        )
        show.invoke(null, context, true, true)
        val agree = clazz.getMethod(
            "updatePrivacyAgree",
            Context::class.java,
            Boolean::class.javaPrimitiveType
        )
        agree.invoke(null, context, true)
    }

    private fun platformVersion(): String {
        return runCatching {
            val clazz = Class.forName("com.amap.api.maps.MapsInitializer")
            val method = clazz.getMethod("getVersion")
            method.invoke(null)?.toString() ?: ""
        }.getOrDefault("")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
