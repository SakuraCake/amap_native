package dev.skono.amap_native

import android.content.Context
import android.os.Bundle
import android.view.View
import androidx.lifecycle.Lifecycle
import com.amap.api.navi.AMapNavi
import com.amap.api.navi.AMapNaviView
import com.amap.api.navi.AMapNaviViewOptions
import com.amap.api.navi.enums.BroadcastMode
import com.amap.api.navi.enums.NaviType
import com.amap.api.navi.model.NaviLatLng
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.lang.reflect.Method
import java.lang.reflect.Proxy

class AmapNaviViewFactory(
    private val messenger: BinaryMessenger,
    private val lifecycleProvider: () -> Lifecycle?
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        AmapNaviPlatformView(
            context,
            messenger,
            viewId,
            Bridge.map(args),
            lifecycleProvider()
        )
}

class AmapNaviPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    private val viewId: Int,
    private val params: Map<*, *>,
    private val lifecycle: Lifecycle?
) : PlatformView, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val naviView = AMapNaviView(context)
    private val navi: AMapNavi = AMapNavi.getInstance(context)
    private val channel = MethodChannel(messenger, "amap_native/navi/$viewId")
    private val eventChannel = EventChannel(messenger, "amap_native/navi/$viewId/events")
    private var sink: EventChannel.EventSink? = null
    private var disposed = false
    private var initialized = false
    private val listener: Any

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        naviView.onCreate(Bundle())
        naviView.onResume()
        applyOptions()
        listener = createListener()
        runCatching {
            val method = navi.javaClass.getMethod(
                "addAMapNaviListener",
                Class.forName("com.amap.api.navi.AMapNaviListener")
            )
            method.invoke(navi, listener)
        }
    }

    private fun applyOptions() {
        val options = Bridge.map(params["options"])
        val viewOptions = AMapNaviViewOptions()
        viewOptions.isAutoChangeZoom = Bridge.bool(options, "autoChangeZoom", true)
        viewOptions.isTrafficLine = Bridge.bool(options, "showTraffic", true)
        viewOptions.isCompassEnabled = Bridge.bool(options, "showCompass", false)
        viewOptions.isNaviNight = Bridge.bool(options, "naviNightMode", false)
        naviView.setViewOptions(viewOptions)
    }

    private fun createListener(): Any {
        val listenerClass = Class.forName("com.amap.api.navi.AMapNaviListener")
        return Proxy.newProxyInstance(
            listenerClass.classLoader,
            arrayOf(listenerClass)
        ) { _, method, args ->
            handleNaviEvent(method, args)
            null
        }
    }

    private fun handleNaviEvent(method: Method, args: Array<Any?>?) {
        when (method.name) {
            "onInitNaviSuccess" -> {
                initialized = true
                emit(mapOf("type" to "ready"))
            }
            "onInitNaviFailure" -> emit(
                mapOf("type" to "error", "code" to "init_failed", "message" to "Navigation initialization failed")
            )
            "onCalculateRouteSuccess" -> emit(
                mapOf("type" to "calculateSuccess", "routeIds" to (args?.firstOrNull() ?: emptyList<Any>()))
            )
            "onCalculateRouteFailure" -> emit(
                mapOf("type" to "calculateError", "code" to "calculate_failed", "message" to (args?.firstOrNull()?.toString() ?: ""))
            )
            "onArriveDestination" -> emit(mapOf("type" to "arriveDestination"))
            "onNaviInfoUpdate" -> emit(
                mapOf("type" to "naviInfo", "info" to (args?.firstOrNull()?.let { naviInfo(it) } ?: emptyMap<String, Any?>()))
            )
            "onEndEmulatorNavi" -> emit(mapOf("type" to "simulateEnd"))
        }
    }

    private fun naviInfo(info: Any): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>()
        fun read(name: String, key: String) {
            runCatching {
                val value = info.javaClass.getMethod(name).invoke(info)
                result[key] = value
            }
        }
        read("getPathRetainDistance", "retainDistance")
        read("getPathRetainTime", "retainTime")
        read("getCurRoadName", "roadName")
        read("getNextRoadName", "nextRoadName")
        read("getCurStepRetainDistance", "stepRetainDistance")
        read("getIconType", "iconType")
        return result
    }

    override fun getView(): View = naviView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (disposed) {
            result.error("disposed", "Navigation view was disposed.", null)
            return
        }
        try {
            when (call.method) {
                "calculateDriveRoute" -> {
                    val args = Bridge.map(call.arguments)
                    val from = naviLatLng(Bridge.map(args["from"]))
                    val to = naviLatLng(Bridge.map(args["to"]))
                    val waypoints = Bridge.list(args["waypoints"]).map {
                        naviLatLng(Bridge.map(it))
                    }
                    navi.calculateDriveRoute(
                        listOf(from),
                        listOf(to),
                        waypoints,
                        Bridge.int(args, "strategy", 0)
                    )
                    result.success(null)
                }
                "startNavi" -> {
                    navi.startNavi(NaviType.GPS)
                    result.success(null)
                }
                "stopNavi" -> {
                    navi.stopNavi()
                    result.success(null)
                }
                "pauseNavi" -> {
                    navi.pauseNavi()
                    result.success(null)
                }
                "resumeNavi" -> {
                    navi.resumeNavi()
                    result.success(null)
                }
                "startSimulateNavigation" -> {
                    navi.startNavi(NaviType.EMULATOR)
                    result.success(null)
                }
                "stopSimulateNavigation" -> {
                    navi.stopNavi()
                    result.success(null)
                }
                "setVoiceBroadcast" -> {
                    val enabled = Bridge.bool(Bridge.map(call.arguments), "enabled", true)
                    navi.setBroadcastMode(
                        if (enabled) BroadcastMode.DETAIL else BroadcastMode.MUTE
                    )
                    result.success(null)
                }
                "setVolume" -> {
                    result.error(
                        "unsupported",
                        "AMap Android SDK does not expose a navigation TTS volume API.",
                        null
                    )
                }
                "zoomIn" -> {
                    naviView.zoomIn()
                    result.success(null)
                }
                "zoomOut" -> {
                    naviView.zoomOut()
                    result.success(null)
                }
                "reCenter" -> {
                    naviView.recoverLockMode()
                    result.success(null)
                }
                "dispose" -> {
                    dispose()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            Bridge.error(result, error)
        }
    }

    private fun naviLatLng(map: Map<*, *>): NaviLatLng =
        NaviLatLng(Bridge.double(map, "latitude"), Bridge.double(map, "longitude"))

    private fun emit(event: Map<String, Any?>) {
        sink?.success(event)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        if (initialized) events?.success(mapOf("type" to "ready"))
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        runCatching {
            val method = navi.javaClass.getMethod(
                "removeAMapNaviListener",
                Class.forName("com.amap.api.navi.AMapNaviListener")
            )
            method.invoke(navi, listener)
        }
        naviView.onPause()
        naviView.onDestroy()
        sink = null
    }
}
