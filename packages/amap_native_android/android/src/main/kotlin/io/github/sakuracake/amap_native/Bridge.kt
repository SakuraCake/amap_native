package io.github.sakuracake.amap_native

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Color
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.CameraPosition
import io.flutter.plugin.common.MethodChannel

internal object AmapRuntime {
    @Volatile
    var initialized: Boolean = false
}

internal object Bridge {
    fun map(value: Any?): Map<*, *> = value as? Map<*, *> ?: emptyMap<Any?, Any?>()

    fun list(value: Any?): List<*> = value as? List<*> ?: emptyList<Any?>()

    fun str(map: Map<*, *>, key: String, fallback: String = ""): String =
        map[key]?.toString() ?: fallback

    fun nullableStr(map: Map<*, *>, key: String): String? =
        map[key]?.toString()

    fun double(map: Map<*, *>, key: String, fallback: Double = 0.0): Double {
        val value = map[key]
        return when (value) {
            is Number -> value.toDouble()
            is String -> value.toDoubleOrNull() ?: fallback
            else -> fallback
        }
    }

    fun int(map: Map<*, *>, key: String, fallback: Int = 0): Int {
        val value = map[key]
        return when (value) {
            is Number -> value.toInt()
            is String -> value.toIntOrNull() ?: fallback
            else -> fallback
        }
    }

    fun bool(map: Map<*, *>, key: String, fallback: Boolean = false): Boolean =
        when (val value = map[key]) {
            is Boolean -> value
            is Number -> value.toInt() != 0
            is String -> value.equals("true", ignoreCase = true)
            else -> fallback
        }

    fun latLng(value: Any?): LatLng {
        val map = map(value)
        return LatLng(double(map, "latitude"), double(map, "longitude"))
    }

    fun bounds(value: Any?): LatLngBounds {
        val map = map(value)
        return LatLngBounds(latLng(map["southwest"]), latLng(map["northeast"]))
    }

    fun latLngList(value: Any?): List<LatLng> =
        list(value).map { latLng(it) }

    fun camera(value: Any?): CameraPosition {
        val map = map(value)
        return CameraPosition(
            latLng(map),
            double(map, "zoom", 13.0).toFloat(),
            double(map, "tilt").toFloat(),
            double(map, "bearing").toFloat()
        )
    }

    fun latLngMap(value: LatLng): Map<String, Any?> = mapOf(
        "latitude" to value.latitude,
        "longitude" to value.longitude
    )

    fun cameraMap(value: CameraPosition): Map<String, Any?> = mapOf(
        "latitude" to value.target.latitude,
        "longitude" to value.target.longitude,
        "zoom" to value.zoom.toDouble(),
        "bearing" to value.bearing.toDouble(),
        "tilt" to value.tilt.toDouble()
    )

    fun color(value: Any?): Int {
        val argb = when (value) {
            is Number -> value.toInt()
            is String -> value.toLongOrNull(16)?.toInt() ?: value.toIntOrNull() ?: 0
            else -> 0
        }
        return Color.argb(
            (argb ushr 24) and 0xff,
            (argb ushr 16) and 0xff,
            (argb ushr 8) and 0xff,
            argb and 0xff
        )
    }

    fun bitmapDescriptor(value: Any?): BitmapDescriptor? {
        val bytes = value as? ByteArray ?: return null
        if (bytes.isEmpty()) return null
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }

    fun padding(map: Map<*, *>): IntArray {
        val values = list(map["padding"])
        if (values.size < 4) return intArrayOf(48, 48, 48, 48)
        return intArrayOf(
            (values[0] as? Number)?.toInt() ?: 48,
            (values[1] as? Number)?.toInt() ?: 48,
            (values[2] as? Number)?.toInt() ?: 48,
            (values[3] as? Number)?.toInt() ?: 48
        )
    }

    fun hasApiKey(context: Context): Boolean {
        val info = context.packageManager.getApplicationInfo(
            context.packageName,
            android.content.pm.PackageManager.GET_META_DATA
        )
        val key = info.metaData?.getString("com.amap.api.v2.apikey")
        return !key.isNullOrBlank()
    }

    fun error(result: MethodChannel.Result, error: Throwable) {
        result.error("amap_error", error.message ?: error.javaClass.simpleName, null)
    }

    fun notInitialized(result: MethodChannel.Result) {
        result.error("not_initialized", "AmapNative.initialize must be called after privacy consent.", null)
    }

    fun eventMap(type: String): MutableMap<String, Any?> =
        mutableMapOf("type" to type)
}
