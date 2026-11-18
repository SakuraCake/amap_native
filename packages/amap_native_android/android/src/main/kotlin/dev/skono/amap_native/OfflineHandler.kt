package dev.skono.amap_native

import android.content.Context
import com.amap.api.maps.offlinemap.OfflineMapCity
import com.amap.api.maps.offlinemap.OfflineMapManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AmapOfflineHandler(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val channel = MethodChannel(messenger, "amap_native/offline")
    private val eventChannel = EventChannel(messenger, "amap_native/offline/events")
    private var sink: EventChannel.EventSink? = null
    private var manager: OfflineMapManager? = null

    private val downloadListener =
        object : OfflineMapManager.OfflineMapDownloadListener {
            override fun onDownload(cityCode: Int, progress: Int, message: String?) {
                sink?.success(
                    mapOf(
                        "cityCode" to cityCode.toString(),
                        "complete" to (progress >= 100),
                        "progress" to progress,
                        "errorCode" to 0,
                        "message" to (message ?: "")
                    )
                )
            }

            override fun onCheckUpdate(complete: Boolean, message: String?) {
                sink?.success(
                    mapOf(
                        "cityCode" to "",
                        "complete" to complete,
                        "progress" to 100,
                        "errorCode" to 0,
                        "message" to (message ?: "")
                    )
                )
            }

            override fun onRemove(complete: Boolean, cityCode: String?, message: String?) {
                sink?.success(
                    mapOf(
                        "cityCode" to (cityCode ?: ""),
                        "complete" to complete,
                        "progress" to 100,
                        "errorCode" to 0,
                        "message" to (message ?: "")
                    )
                )
            }
        }

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    private fun requireManager(): OfflineMapManager =
        manager ?: OfflineMapManager(context, downloadListener).also { manager = it }

    fun dispose() {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        manager?.destroy()
        manager = null
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (!AmapRuntime.initialized) {
            Bridge.notInitialized(result)
            return
        }
        try {
            when (call.method) {
                "getCities" -> result.success(
                    requireManager().offlineMapCityList.map { city(it) }
                )
                "download" -> {
                    requireManager().downloadByCityCode(cityCode(call))
                    result.success(null)
                }
                "pause" -> {
                    requireManager().pause()
                    result.success(null)
                }
                "resume" -> {
                    requireManager().downloadByCityCode(cityCode(call))
                    result.success(null)
                }
                "remove" -> {
                    requireManager().remove(cityCode(call))
                    result.success(null)
                }
                "update" -> {
                    requireManager().updateOfflineCityByCode(cityCode(call))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            Bridge.error(result, error)
        }
    }

    private fun cityCode(call: MethodCall): String =
        Bridge.str(Bridge.map(call.arguments), "cityCode")

    private fun city(city: OfflineMapCity): Map<String, Any?> = mapOf(
        "name" to city.city,
        "code" to city.code,
        "version" to city.version,
        "size" to city.size,
        "status" to city.state
    )

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
