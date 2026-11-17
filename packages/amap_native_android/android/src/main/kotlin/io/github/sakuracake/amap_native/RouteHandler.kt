package io.github.sakuracake.amap_native

import android.content.Context
import com.amap.api.services.core.AMapException
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.route.BusPath
import com.amap.api.services.route.BusRouteResult
import com.amap.api.services.route.RouteSearch.BusRouteQuery
import com.amap.api.services.route.RouteSearch.DriveRouteQuery
import com.amap.api.services.route.RouteSearch.FromAndTo
import com.amap.api.services.route.RouteSearch.RideRouteQuery
import com.amap.api.services.route.RouteSearch.WalkRouteQuery
import com.amap.api.services.route.DrivePath
import com.amap.api.services.route.DriveRouteResult
import com.amap.api.services.route.DriveStep
import com.amap.api.services.route.RidePath
import com.amap.api.services.route.RideRouteResult
import com.amap.api.services.route.RideStep
import com.amap.api.services.route.RouteSearch
import com.amap.api.services.route.WalkPath
import com.amap.api.services.route.WalkRouteResult
import com.amap.api.services.route.WalkStep
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AmapRouteHandler(
    context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "amap_native/route")
    private val search = RouteSearch(context)

    init {
        channel.setMethodCallHandler(this)
        search.setRouteSearchListener(object : RouteSearch.OnRouteSearchListener {
            override fun onDriveRouteSearched(result: DriveRouteResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || result == null) {
                    pendingDrive?.error(code.toString(), "Drive route failed", null)
                    pendingDrive = null
                    return
                }
                pendingDrive?.success(
                    mapOf("paths" to (result.paths ?: emptyList()).map { drivePath(it) })
                )
                pendingDrive = null
            }

            override fun onWalkRouteSearched(result: WalkRouteResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || result == null) {
                    pendingWalk?.error(code.toString(), "Walk route failed", null)
                    pendingWalk = null
                    return
                }
                pendingWalk?.success(
                    mapOf("paths" to (result.paths ?: emptyList()).map { walkPath(it) })
                )
                pendingWalk = null
            }

            override fun onRideRouteSearched(result: RideRouteResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || result == null) {
                    pendingRide?.error(code.toString(), "Ride route failed", null)
                    pendingRide = null
                    return
                }
                pendingRide?.success(
                    mapOf("paths" to (result.paths ?: emptyList()).map { ridePath(it) })
                )
                pendingRide = null
            }

            override fun onBusRouteSearched(result: BusRouteResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || result == null) {
                    pendingTransit?.error(code.toString(), "Transit route failed", null)
                    pendingTransit = null
                    return
                }
                pendingTransit?.success(
                    mapOf("paths" to (result.paths ?: emptyList()).map { busPath(it) })
                )
                pendingTransit = null
            }
        })
    }

    private var pendingDrive: MethodChannel.Result? = null
    private var pendingWalk: MethodChannel.Result? = null
    private var pendingRide: MethodChannel.Result? = null
    private var pendingTransit: MethodChannel.Result? = null

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (!AmapRuntime.initialized) {
            Bridge.notInitialized(result)
            return
        }
        try {
            when (call.method) {
                "drive" -> drive(Bridge.map(call.arguments), result)
                "walk" -> walk(Bridge.map(call.arguments), result)
                "ride" -> ride(Bridge.map(call.arguments), result)
                "transit" -> transit(Bridge.map(call.arguments), result)
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            Bridge.error(result, error)
        }
    }

    private fun drive(args: Map<*, *>, result: MethodChannel.Result) {
        val query = DriveRouteQuery(
            FromAndTo(
                point(Bridge.map(args["from"])),
                point(Bridge.map(args["to"]))
            ),
            Bridge.int(args, "strategy", 0),
            Bridge.list(args["waypoints"]).map { point(Bridge.map(it)) },
            Bridge.list(args["avoidPolygons"]).map { ring ->
                Bridge.list(ring).map { point(Bridge.map(it)) }
            },
            Bridge.str(args, "avoidRoad")
        )
        query.isUseFerry = false
        pendingDrive = result
        search.calculateDriveRouteAsyn(query)
    }

    private fun walk(args: Map<*, *>, result: MethodChannel.Result) {
        val query = WalkRouteQuery(
            FromAndTo(
                point(Bridge.map(args["from"])),
                point(Bridge.map(args["to"]))
            )
        )
        pendingWalk = result
        search.calculateWalkRouteAsyn(query)
    }

    private fun ride(args: Map<*, *>, result: MethodChannel.Result) {
        val query = RideRouteQuery(
            FromAndTo(
                point(Bridge.map(args["from"])),
                point(Bridge.map(args["to"]))
            )
        )
        pendingRide = result
        search.calculateRideRouteAsyn(query)
    }

    private fun transit(args: Map<*, *>, result: MethodChannel.Result) {
        val query = BusRouteQuery(
            FromAndTo(
                point(Bridge.map(args["from"])),
                point(Bridge.map(args["to"]))
            ),
            Bridge.int(args, "strategy", 0),
            Bridge.str(args, "city"),
            if (Bridge.bool(args, "nightFlag", false)) 1 else 0
        )
        query.cityd = Bridge.str(args, "cityd")
        pendingTransit = result
        search.calculateBusRouteAsyn(query)
    }

    private fun point(map: Map<*, *>): LatLonPoint =
        LatLonPoint(Bridge.double(map, "latitude"), Bridge.double(map, "longitude"))

    private fun pointMap(point: LatLonPoint?): Map<String, Any?>? = point?.let {
        mapOf("latitude" to it.latitude, "longitude" to it.longitude)
    }

    private fun points(list: List<LatLonPoint>?): List<Map<String, Any?>> =
        (list ?: emptyList()).mapNotNull { pointMap(it) }

    private fun drivePath(path: DrivePath): Map<String, Any?> = mapOf(
        "distance" to path.distance.toDouble(),
        "duration" to path.duration,
        "tolls" to path.tolls.toDouble(),
        "trafficLights" to path.totalTrafficlights,
        "steps" to (path.steps ?: emptyList()).map { driveStep(it) },
        "polyline" to (path.steps ?: emptyList()).flatMap { points(it.polyline) }
    )

    private fun driveStep(step: DriveStep): Map<String, Any?> = mapOf(
        "instruction" to step.instruction,
        "roadName" to step.road,
        "distance" to step.distance.toDouble(),
        "duration" to step.duration.toDouble(),
        "action" to step.action,
        "polyline" to points(step.polyline)
    )

    private fun walkPath(path: WalkPath): Map<String, Any?> = mapOf(
        "distance" to path.distance.toDouble(),
        "duration" to path.duration,
        "steps" to (path.steps ?: emptyList()).map { walkStep(it) },
        "polyline" to (path.steps ?: emptyList()).flatMap { points(it.polyline) }
    )

    private fun walkStep(step: WalkStep): Map<String, Any?> = mapOf(
        "instruction" to step.instruction,
        "roadName" to step.road,
        "distance" to step.distance.toDouble(),
        "duration" to step.duration.toDouble(),
        "action" to step.action,
        "polyline" to points(step.polyline)
    )

    private fun ridePath(path: RidePath): Map<String, Any?> = mapOf(
        "distance" to path.distance.toDouble(),
        "duration" to path.duration,
        "steps" to (path.steps ?: emptyList()).map { rideStep(it) },
        "polyline" to (path.steps ?: emptyList()).flatMap { points(it.polyline) }
    )

    private fun rideStep(step: RideStep): Map<String, Any?> = mapOf(
        "instruction" to step.instruction,
        "roadName" to step.road,
        "distance" to step.distance.toDouble(),
        "duration" to step.duration.toDouble(),
        "action" to step.action,
        "polyline" to points(step.polyline)
    )

    private fun busPath(path: BusPath): Map<String, Any?> = mapOf(
        "distance" to path.distance.toDouble(),
        "duration" to path.duration,
        "steps" to emptyList<Map<String, Any?>>(),
        "polyline" to emptyList<Map<String, Any?>>()
    )
}
