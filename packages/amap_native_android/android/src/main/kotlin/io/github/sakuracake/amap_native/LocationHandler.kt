package io.github.sakuracake.amap_native

import android.content.Context
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

class AmapLocationHandler(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val methodChannel = MethodChannel(messenger, "amap_native/location")
    private val eventChannel = EventChannel(messenger, "amap_native/location/events")
    private var sink: EventChannel.EventSink? = null
    private var client: AMapLocationClient? = null
    private var option = AMapLocationClientOption()
    private val fences = mutableListOf<Map<*, *>>()
    private val inside = mutableMapOf<String, Boolean>()

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        client?.stopLocation()
        client?.onDestroy()
        client = null
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (!AmapRuntime.initialized) {
            Bridge.notInitialized(result)
            return
        }
        try {
            when (call.method) {
                "setOption" -> {
                    applyOption(Bridge.map(call.arguments))
                    result.success(null)
                }
                "start" -> {
                    ensureClient().startLocation()
                    result.success(null)
                }
                "stop" -> {
                    client?.stopLocation()
                    result.success(null)
                }
                "destroy" -> {
                    client?.stopLocation()
                    client?.onDestroy()
                    client = null
                    result.success(null)
                }
                "getLastKnownLocation" -> {
                    val location = client?.lastKnownLocation
                    result.success(location?.let { location(it) })
                }
                "startGeofence" -> {
                    fences.clear()
                    Bridge.list(Bridge.map(call.arguments)["fences"])
                        .map { Bridge.map(it) }
                        .forEach { fences.add(it) }
                    inside.clear()
                    result.success(null)
                }
                "stopGeofence" -> {
                    fences.clear()
                    inside.clear()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            Bridge.error(result, error)
        }
    }

    private fun ensureClient(): AMapLocationClient {
        client?.let { return it }
        val created = AMapLocationClient(context)
        created.setLocationOption(option)
        created.setLocationListener(AMapLocationListener { location ->
            if (location != null) {
                emitLocation(location)
                emitFences(location)
            }
        })
        client = created
        return created
    }

    private fun applyOption(args: Map<*, *>) {
        val next = AMapLocationClientOption()
        next.locationMode = when (Bridge.int(args, "locationMode", 0)) {
            1 -> AMapLocationClientOption.AMapLocationMode.Battery_Saving
            2 -> AMapLocationClientOption.AMapLocationMode.Device_Sensors
            else -> AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
        }
        next.isOnceLocation = Bridge.bool(args, "onceLocation", true)
        next.interval = Bridge.int(args, "intervalMs", 2000).toLong()
        next.isNeedAddress = Bridge.bool(args, "needAddress", true)
        next.httpTimeOut = Bridge.int(args, "httpTimeoutMs", 30000).toLong()
        next.isMockEnable = Bridge.bool(args, "mockEnable", false)
        option = next
        client?.setLocationOption(next)
    }

    private fun emitLocation(location: AMapLocation) {
        sink?.success(
            mapOf(
                "eventType" to "location",
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "coordinateType" to "gcj02",
                "accuracy" to location.accuracy.toDouble(),
                "speed" to location.speed.toDouble(),
                "bearing" to location.bearing.toDouble(),
                "altitude" to location.altitude,
                "address" to location.address,
                "country" to location.country,
                "province" to location.province,
                "city" to location.city,
                "district" to location.district,
                "street" to location.street,
                "timestamp" to location.time,
                "errorCode" to location.errorCode,
                "errorInfo" to location.errorInfo
            )
        )
    }

    private fun emitFences(location: AMapLocation) {
        if (fences.isEmpty()) return
        for (fenceValue in fences) {
            val fence = Bridge.map(fenceValue)
            val id = Bridge.str(fence, "id")
            if (id.isEmpty()) continue
            val radius = Bridge.double(fence, "radius")
            val distance = distanceMeters(
                location.latitude,
                location.longitude,
                Bridge.double(fence, "latitude"),
                Bridge.double(fence, "longitude")
            )
            val wasInside = inside[id] ?: false
            val isInside = distance <= radius
            inside[id] = isInside
            if (isInside != wasInside) {
                sink?.success(
                    mapOf(
                        "eventType" to "geofence",
                        "id" to id,
                        "status" to if (isInside) "entered" else "exited",
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                        "timestamp" to location.time
                    )
                )
            }
        }
    }

    private fun location(location: AMapLocation): Map<String, Any?> = mapOf(
        "eventType" to "location",
        "latitude" to location.latitude,
        "longitude" to location.longitude,
        "coordinateType" to "gcj02",
        "accuracy" to location.accuracy.toDouble(),
        "speed" to location.speed.toDouble(),
        "bearing" to location.bearing.toDouble(),
        "altitude" to location.altitude,
        "address" to location.address,
        "country" to location.country,
        "province" to location.province,
        "city" to location.city,
        "district" to location.district,
        "street" to location.street,
        "timestamp" to location.time,
        "errorCode" to location.errorCode,
        "errorInfo" to location.errorInfo
    )

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun distanceMeters(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val earthRadius = 6371008.8
        val dLat = Math.toRadians(lat2 - lat1)
        val dLng = Math.toRadians(lng2 - lng1)
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
            sin(dLng / 2) * sin(dLng / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
