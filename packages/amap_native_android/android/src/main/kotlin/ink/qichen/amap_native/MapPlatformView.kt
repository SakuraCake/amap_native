package ink.qichen.amap_native

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Bundle
import android.view.View
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.amap.api.maps.AMap
import com.amap.api.maps.AMapOptions
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.TextureMapView
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.Circle
import com.amap.api.maps.model.CircleOptions
import com.amap.api.maps.model.CustomMapStyleOptions
import com.amap.api.maps.model.GroundOverlay
import com.amap.api.maps.model.Gradient
import com.amap.api.maps.model.GroundOverlayOptions
import com.amap.api.maps.model.HeatmapTileProvider
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.MarkerOptions
import com.amap.api.maps.model.Poi
import com.amap.api.maps.model.Polygon
import com.amap.api.maps.model.PolygonOptions
import com.amap.api.maps.model.Polyline
import com.amap.api.maps.model.PolylineOptions
import com.amap.api.maps.model.TileOverlay
import com.amap.api.maps.model.TileOverlayOptions
import com.amap.api.maps.model.UrlTileProvider
import com.amap.api.maps.model.VisibleRegion
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.ByteArrayOutputStream
import java.net.URL
import java.util.concurrent.ConcurrentHashMap

class AmapMapViewFactory(
    private val messenger: BinaryMessenger,
    private val lifecycleProvider: () -> Lifecycle?
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        AmapMapPlatformView(
            context,
            messenger,
            viewId,
            Bridge.map(args),
            lifecycleProvider()
        )
}

class AmapMapPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    private val viewId: Int,
    private val params: Map<*, *>,
    lifecycle: Lifecycle?
) : PlatformView,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    DefaultLifecycleObserver,
    AMap.OnMapLoadedListener,
    AMap.OnMapClickListener,
    AMap.OnMapLongClickListener,
    AMap.OnPOIClickListener,
    AMap.OnMarkerClickListener,
    AMap.OnCameraChangeListener {

    private val mapView = TextureMapView(context)
    private val map: AMap = mapView.map
    private val methodChannel = MethodChannel(messenger, "amap_native/map/$viewId")
    private val eventChannel = EventChannel(messenger, "amap_native/map/$viewId/events")
    private var eventSink: EventChannel.EventSink? = null
    private var ready = false
    private var disposed = false
    private var observer: Lifecycle? = null

    private val markers = ConcurrentHashMap<String, Marker>()
    private val markerJson = ConcurrentHashMap<String, String>()
    private val polylines = ConcurrentHashMap<String, Polyline>()
    private val polylineJson = ConcurrentHashMap<String, String>()
    private val polygons = ConcurrentHashMap<String, Polygon>()
    private val polygonJson = ConcurrentHashMap<String, String>()
    private val circles = ConcurrentHashMap<String, Circle>()
    private val circleJson = ConcurrentHashMap<String, String>()
    private val tileOverlays = ConcurrentHashMap<String, TileOverlay>()
    private val groundOverlays = ConcurrentHashMap<String, GroundOverlay>()

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        mapView.onCreate(Bundle())
        mapView.onResume()
        map.addOnMapLoadedListener(this)
        map.addOnMapClickListener(this)
        map.addOnMapLongClickListener(this)
        map.addOnPOIClickListener(this)
        map.setOnMarkerClickListener(this)
        map.addOnCameraChangeListener(this)
        configureOptions(Bridge.map(params["options"]))
        applyOverlays(params)
        val camera = Bridge.map(params["initialCamera"])
        if (camera.isNotEmpty()) {
            map.moveCamera(CameraUpdateFactory.newCameraPosition(Bridge.camera(camera)))
        }
        if (lifecycle != null) {
            observer = lifecycle
            lifecycle.addObserver(this)
        }
    }

    override fun getView(): View = mapView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (disposed) {
            result.error("disposed", "Map view was disposed.", null)
            return
        }
        try {
            when (call.method) {
                "updateOverlays" -> {
                    applyOverlays(Bridge.map(call.arguments))
                    result.success(null)
                }
                "moveCamera" -> {
                    val args = Bridge.map(call.arguments)
                    moveCamera(
                        Bridge.map(args["update"]),
                        Bridge.bool(args, "animated", true),
                        Bridge.int(args, "duration", 250).toLong()
                    )
                    result.success(null)
                }
                "fitBounds" -> {
                    val args = Bridge.map(call.arguments)
                    val bounds = Bridge.bounds(args["bounds"])
                    val padding = Bridge.padding(args)
                    map.moveCamera(CameraUpdateFactory.newLatLngBounds(bounds, padding[0]))
                    result.success(null)
                }
                "setPadding" -> {
                    val padding = Bridge.padding(Bridge.map(call.arguments))
                    mapView.setPadding(padding[0], padding[1], padding[2], padding[3])
                    result.success(null)
                }
                "clear" -> {
                    clearOverlays()
                    result.success(null)
                }
                "snapshot" -> takeSnapshot(result)
                "project" -> {
                    val points = Bridge.latLngList(Bridge.map(call.arguments)["points"])
                    val projection = map.projection
                    result.success(
                        points.map {
                            val point = projection.toScreenLocation(it)
                            mapOf("x" to point.x.toDouble(), "y" to point.y.toDouble())
                        }
                    )
                }
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            Bridge.error(result, error)
        }
    }

    private fun configureOptions(options: Map<*, *>) {
        if (options.isEmpty()) return
        val type = Bridge.str(options, "mapType", "normal")
        map.mapType = when (type) {
            "satellite" -> AMap.MAP_TYPE_SATELLITE
            "night" -> AMap.MAP_TYPE_NIGHT
            "navi" -> AMap.MAP_TYPE_NAVI
            else -> AMap.MAP_TYPE_NORMAL
        }
        val style = Bridge.map(options["style"])
        when (Bridge.str(style, "type", "normal")) {
            "satellite" -> map.mapType = AMap.MAP_TYPE_SATELLITE
            "night" -> map.mapType = AMap.MAP_TYPE_NIGHT
            "navi" -> map.mapType = AMap.MAP_TYPE_NAVI
            "custom" -> {
                val custom = CustomMapStyleOptions()
                Bridge.nullableStr(style, "styleId")?.let { custom.styleId = it }
                (style["styleData"] as? ByteArray)?.let { custom.styleData = it }
                (style["styleExtraData"] as? ByteArray)?.let { custom.styleExtraData = it }
                (style["styleTextureData"] as? ByteArray)?.let { custom.styleTextureData = it }
                map.setCustomMapStyle(custom)
            }
        }
        map.isTrafficEnabled = Bridge.bool(options, "trafficEnabled", false)
        map.showBuildings(Bridge.bool(options, "buildingsEnabled", false))
        map.showMapText(Bridge.bool(options, "labelsEnabled", true))
        map.setTouchPoiEnable(true)
        map.setMinZoomLevel(Bridge.double(options, "minZoom", 3.0).toFloat())
        map.setMaxZoomLevel(Bridge.double(options, "maxZoom", 20.0).toFloat())
        val ui = map.uiSettings
        ui.isCompassEnabled = Bridge.bool(options, "compassEnabled", false)
        ui.isScaleControlsEnabled = Bridge.bool(options, "scaleEnabled", false)
        ui.isZoomControlsEnabled = Bridge.bool(options, "zoomControlsEnabled", false)
        ui.isRotateGesturesEnabled = Bridge.bool(options, "rotateGesturesEnabled", false)
        ui.isTiltGesturesEnabled = Bridge.bool(options, "tiltGesturesEnabled", false)
        ui.isScrollGesturesEnabled = Bridge.bool(options, "scrollGesturesEnabled", true)
        ui.isZoomGesturesEnabled = Bridge.bool(options, "zoomGesturesEnabled", true)
        ui.logoPosition = when (Bridge.str(options, "logoPosition", "bottomLeft")) {
            "bottomCenter" -> AMapOptions.LOGO_POSITION_BOTTOM_CENTER
            "bottomRight" -> AMapOptions.LOGO_POSITION_BOTTOM_RIGHT
            else -> AMapOptions.LOGO_POSITION_BOTTOM_LEFT
        }
        map.setMapLanguage(
            if (Bridge.str(options, "language", "chinese") == "english") AMap.ENGLISH else AMap.CHINESE
        )
    }

    private fun applyOverlays(args: Map<*, *>) {
        applyMarkers(Bridge.list(args["markers"]))
        applyPolylines(Bridge.list(args["polylines"]))
        applyPolygons(Bridge.list(args["polygons"]))
        applyCircles(Bridge.list(args["circles"]))
        applyTiles(Bridge.list(args["tileOverlays"]))
        applyGroundOverlays(Bridge.list(args["groundOverlays"]))
        applyHeatmaps(Bridge.list(args["heatmaps"]))
    }

    private fun applyMarkers(items: List<*>) {
        val seen = mutableSetOf<String>()
        for (item in items) {
            val mapItem = Bridge.map(item)
            val id = Bridge.str(mapItem, "id")
            if (id.isEmpty()) continue
            seen.add(id)
            val json = mapItem.toString()
            if (markerJson[id] == json) continue
            markers.remove(id)?.remove()
            val options = MarkerOptions()
                .position(Bridge.latLng(mapItem))
                .anchor(
                    Bridge.double(mapItem, "anchorX", 0.5).toFloat(),
                    Bridge.double(mapItem, "anchorY", 1.0).toFloat()
                )
                .alpha(Bridge.double(mapItem, "alpha", 1.0).toFloat())
                .visible(Bridge.bool(mapItem, "visible", true))
                .zIndex(Bridge.int(mapItem, "zIndex", 0).toFloat())
                .rotateAngle(Bridge.double(mapItem, "rotation", 0.0).toFloat())
                .draggable(Bridge.bool(mapItem, "draggable", false))
            Bridge.bitmapDescriptor(mapItem["icon"])?.let { options.icon(it) }
            val marker = map.addMarker(options)
            marker?.setObject(id)
            if (marker != null) {
                markers[id] = marker
                markerJson[id] = json
            }
        }
        markers.keys.filter { it !in seen }.forEach { id ->
            markers.remove(id)?.remove()
            markerJson.remove(id)
        }
    }

    private fun applyPolylines(items: List<*>) {
        val seen = mutableSetOf<String>()
        for (item in items) {
            val mapItem = Bridge.map(item)
            val id = Bridge.str(mapItem, "id")
            if (id.isEmpty()) continue
            seen.add(id)
            val json = mapItem.toString()
            if (polylineJson[id] == json) continue
            polylines.remove(id)?.remove()
            val options = PolylineOptions()
                .addAll(Bridge.latLngList(mapItem["points"]))
                .width(Bridge.double(mapItem, "width", 4.0).toFloat())
                .color(Bridge.color(mapItem["color"]))
                .visible(Bridge.bool(mapItem, "visible", true))
                .zIndex(Bridge.int(mapItem, "zIndex", 0).toFloat())
            if (Bridge.bool(mapItem, "dashed", false)) {
                options.setDottedLine(true)
            }
            val line = map.addPolyline(options)
            if (line != null) {
                polylines[id] = line
                polylineJson[id] = json
            }
        }
        polylines.keys.filter { it !in seen }.forEach { id ->
            polylines.remove(id)?.remove()
            polylineJson.remove(id)
        }
    }

    private fun applyPolygons(items: List<*>) {
        val seen = mutableSetOf<String>()
        for (item in items) {
            val mapItem = Bridge.map(item)
            val id = Bridge.str(mapItem, "id")
            if (id.isEmpty()) continue
            seen.add(id)
            val json = mapItem.toString()
            if (polygonJson[id] == json) continue
            polygons.remove(id)?.remove()
            val polygon = map.addPolygon(
                PolygonOptions()
                    .addAll(Bridge.latLngList(mapItem["points"]))
                    .strokeWidth(Bridge.double(mapItem, "strokeWidth", 2.0).toFloat())
                    .strokeColor(Bridge.color(mapItem["strokeColor"]))
                    .fillColor(Bridge.color(mapItem["fillColor"]))
                    .visible(Bridge.bool(mapItem, "visible", true))
                    .zIndex(Bridge.int(mapItem, "zIndex", 0).toFloat())
            )
            if (polygon != null) {
                polygons[id] = polygon
                polygonJson[id] = json
            }
        }
        polygons.keys.filter { it !in seen }.forEach { id ->
            polygons.remove(id)?.remove()
            polygonJson.remove(id)
        }
    }

    private fun applyCircles(items: List<*>) {
        val seen = mutableSetOf<String>()
        for (item in items) {
            val mapItem = Bridge.map(item)
            val id = Bridge.str(mapItem, "id")
            if (id.isEmpty()) continue
            seen.add(id)
            val json = mapItem.toString()
            if (circleJson[id] == json) continue
            circles.remove(id)?.remove()
            val circle = map.addCircle(
                CircleOptions()
                    .center(Bridge.latLng(mapItem))
                    .radius(Bridge.double(mapItem, "radius", 100.0))
                    .strokeWidth(Bridge.double(mapItem, "strokeWidth", 2.0).toFloat())
                    .strokeColor(Bridge.color(mapItem["strokeColor"]))
                    .fillColor(Bridge.color(mapItem["fillColor"]))
                    .visible(Bridge.bool(mapItem, "visible", true))
                    .zIndex(Bridge.int(mapItem, "zIndex", 0).toFloat())
            )
            if (circle != null) {
                circles[id] = circle
                circleJson[id] = json
            }
        }
        circles.keys.filter { it !in seen }.forEach { id ->
            circles.remove(id)?.remove()
            circleJson.remove(id)
        }
    }

    private fun applyTiles(items: List<*>) {
        tileOverlays.values.forEach { it.remove() }
        tileOverlays.clear()
        for (item in items) {
            val mapItem = Bridge.map(item)
            val id = Bridge.str(mapItem, "id")
            val template = Bridge.str(mapItem, "urlTemplate")
            if (id.isEmpty() || template.isEmpty()) continue
            val tileSize = Bridge.int(mapItem, "tileSize", 256)
            val minZoom = Bridge.int(mapItem, "minZoom", 0)
            val maxZoom = Bridge.int(mapItem, "maxZoom", 20)
            val provider = object : UrlTileProvider(tileSize, tileSize) {
                override fun getTileUrl(x: Int, y: Int, zoom: Int): URL? {
                    if (zoom < minZoom || zoom > maxZoom) return null
                    val url = template
                        .replace("{x}", x.toString())
                        .replace("{y}", y.toString())
                        .replace("{z}", zoom.toString())
                    return runCatching { URL(url) }.getOrNull()
                }
            }
            val overlay = map.addTileOverlay(
                TileOverlayOptions().tileProvider(provider).zIndex(Bridge.int(mapItem, "zIndex", 0).toFloat())
            )
            if (overlay != null) tileOverlays[id] = overlay
        }
    }

    private fun applyGroundOverlays(items: List<*>) {
        groundOverlays.values.forEach { it.remove() }
        groundOverlays.clear()
        for (item in items) {
            val mapItem = Bridge.map(item)
            val id = Bridge.str(mapItem, "id")
            val descriptor = Bridge.bitmapDescriptor(mapItem["imageBytes"]) ?: continue
            if (id.isEmpty()) continue
            val overlay = map.addGroundOverlay(
                GroundOverlayOptions()
                    .image(descriptor)
                    .positionFromBounds(Bridge.bounds(mapItem["bounds"]))
                    .transparency(Bridge.double(mapItem, "transparency", 0.0).toFloat())
                    .zIndex(Bridge.int(mapItem, "zIndex", 0).toFloat())
                    .visible(Bridge.bool(mapItem, "visible", true))
            )
            if (overlay != null) groundOverlays[id] = overlay
        }
    }

    private fun applyHeatmaps(items: List<*>) {
        items.forEach { item ->
            val mapItem = Bridge.map(item)
            val points = Bridge.latLngList(mapItem["points"])
            if (points.isEmpty()) return@forEach
            val entries = Bridge.list(mapItem["gradient"]).sortedBy {
                Bridge.double(Bridge.map(it), "index")
            }
            val colors = entries.map {
                Bridge.color(Bridge.map(it)["color"])
            }.toIntArray()
            val builder = HeatmapTileProvider.Builder()
                .data(points)
                .radius(Bridge.int(mapItem, "radius", 20))
                .transparency(1.0 - Bridge.double(mapItem, "opacity", 0.7))
            if (colors.isNotEmpty()) {
                val starts = FloatArray(colors.size) { index ->
                    if (colors.size == 1) 0f else index.toFloat() / (colors.size - 1)
                }
                builder.gradient(Gradient(colors, starts))
            }
            val provider = builder.build()
            map.addTileOverlay(TileOverlayOptions().tileProvider(provider))
        }
    }

    private fun clearOverlays() {
        map.clear()
        markers.clear()
        markerJson.clear()
        polylines.clear()
        polylineJson.clear()
        polygons.clear()
        polygonJson.clear()
        circles.clear()
        circleJson.clear()
        tileOverlays.clear()
        groundOverlays.clear()
    }

    private fun moveCamera(update: Map<*, *>, animated: Boolean, duration: Long) {
        val current = map.cameraPosition
        val target = if (update["latitude"] != null && update["longitude"] != null) {
            Bridge.latLng(update)
        } else {
            current.target
        }
        val position = CameraPosition(
            target,
            Bridge.double(update, "zoom", current.zoom.toDouble()).toFloat(),
            Bridge.double(update, "tilt", current.tilt.toDouble()).toFloat(),
            Bridge.double(update, "bearing", current.bearing.toDouble()).toFloat()
        )
        val cameraUpdate = CameraUpdateFactory.newCameraPosition(position)
        if (animated) {
            map.animateCamera(cameraUpdate, duration, null)
        } else {
            map.moveCamera(cameraUpdate)
        }
    }

    private fun takeSnapshot(result: MethodChannel.Result) {
        map.getMapScreenShot(object : AMap.OnMapScreenShotListener {
            override fun onMapScreenShot(bitmap: Bitmap?) {
                if (bitmap == null) {
                    result.success(null)
                    return
                }
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                bitmap.recycle()
                result.success(stream.toByteArray())
            }

            override fun onMapScreenShot(bitmap: Bitmap?, status: Int) {
                if (status != 0) result.success(null)
            }
        })
    }

    override fun onMapLoaded() {
        ready = true
        sendEvent(Bridge.eventMap("ready"), null)
    }

    override fun onMapClick(latLng: LatLng) {
        val event = Bridge.eventMap("tap")
        event.putAll(Bridge.latLngMap(latLng))
        sendEvent(event, null)
    }

    override fun onMapLongClick(latLng: LatLng) {
        val event = Bridge.eventMap("longPress")
        event.putAll(Bridge.latLngMap(latLng))
        sendEvent(event, null)
    }

    override fun onPOIClick(poi: Poi) {
        val event = Bridge.eventMap("poiTap")
        event.putAll(Bridge.latLngMap(poi.coordinate))
        event["id"] = poi.poiId
        event["name"] = poi.name
        sendEvent(event, null)
    }

    override fun onMarkerClick(marker: Marker): Boolean {
        val id = marker.`object`?.toString() ?: ""
        val event = Bridge.eventMap("markerTap")
        event["id"] = id
        sendEvent(event, null)
        return false
    }

    override fun onCameraChange(cameraPosition: CameraPosition?) = Unit

    override fun onCameraChangeFinish(cameraPosition: CameraPosition?) {
        if (cameraPosition == null) return
        val event = Bridge.eventMap("cameraIdle")
        event["camera"] = Bridge.cameraMap(cameraPosition)
        sendEvent(event, null)
    }

    private fun sendEvent(event: Map<String, Any?>, error: String?) {
        if (disposed) return
        if (error != null) {
            eventSink?.error("amap_error", error, null)
        } else {
            eventSink?.success(event)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (ready) {
            events?.success(Bridge.eventMap("ready"))
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onCreate(owner: LifecycleOwner) {
        if (!disposed) mapView.onCreate(Bundle())
    }

    override fun onResume(owner: LifecycleOwner) {
        if (!disposed) mapView.onResume()
    }

    override fun onPause(owner: LifecycleOwner) {
        if (!disposed) mapView.onPause()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        dispose()
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        observer?.removeObserver(this)
        clearOverlays()
        mapView.onPause()
        mapView.onDestroy()
    }
}
