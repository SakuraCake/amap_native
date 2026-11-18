package dev.skono.amap_native

import android.content.Context
import com.amap.api.services.core.AMapException
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItem
import com.amap.api.services.district.DistrictItem
import com.amap.api.services.district.DistrictResult
import com.amap.api.services.district.DistrictSearch
import com.amap.api.services.district.DistrictSearchQuery
import com.amap.api.services.geocoder.GeocodeAddress
import com.amap.api.services.geocoder.GeocodeQuery
import com.amap.api.services.geocoder.GeocodeResult
import com.amap.api.services.geocoder.GeocodeSearch
import com.amap.api.services.geocoder.RegeocodeAddress
import com.amap.api.services.geocoder.RegeocodeQuery
import com.amap.api.services.geocoder.RegeocodeResult
import com.amap.api.services.help.Inputtips
import com.amap.api.services.help.InputtipsQuery
import com.amap.api.services.help.Tip
import com.amap.api.services.poisearch.PoiResult
import com.amap.api.services.poisearch.PoiSearch
import com.amap.api.services.weather.LocalDayWeatherForecast
import com.amap.api.services.weather.LocalWeatherForecastResult
import com.amap.api.services.weather.LocalWeatherLiveResult
import com.amap.api.services.weather.WeatherSearch
import com.amap.api.services.weather.WeatherSearchQuery
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AmapSearchHandler(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "amap_native/search")

    init {
        channel.setMethodCallHandler(this)
    }

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
                "searchPoi" -> searchPoi(Bridge.map(call.arguments), result)
                "searchPoiAround" -> searchPoiAround(Bridge.map(call.arguments), result)
                "searchPoiById" -> searchPoiById(Bridge.map(call.arguments), result)
                "inputTips" -> inputTips(Bridge.map(call.arguments), result)
                "geocode" -> geocode(Bridge.map(call.arguments), result)
                "reverseGeocode" -> reverseGeocode(Bridge.map(call.arguments), result)
                "searchDistrict" -> searchDistrict(Bridge.map(call.arguments), result)
                "weather" -> weather(Bridge.map(call.arguments), result)
                "trafficStatus" -> trafficStatus(Bridge.map(call.arguments), result)
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            Bridge.error(result, error)
        }
    }

    private fun searchPoi(args: Map<*, *>, result: MethodChannel.Result) {
        val query = PoiSearch.Query(
            Bridge.str(args, "keyword"),
            Bridge.str(args, "types"),
            Bridge.str(args, "city")
        )
        query.pageSize = Bridge.int(args, "pageSize", 20)
        query.pageNum = Bridge.int(args, "page", 1)
        val search = PoiSearch(context, query)
        search.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
            override fun onPoiSearched(poiResult: PoiResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || poiResult == null) {
                    result.error(code.toString(), "POI search failed", null)
                    return
                }
                result.success(poiPage(poiResult))
            }

            override fun onPoiItemSearched(item: PoiItem?, code: Int) = Unit
        })
        search.searchPOIAsyn()
    }

    private fun searchPoiAround(args: Map<*, *>, result: MethodChannel.Result) {
        val query = PoiSearch.Query(
            Bridge.str(args, "keyword"),
            Bridge.str(args, "types"),
            ""
        )
        query.pageSize = Bridge.int(args, "pageSize", 20)
        query.pageNum = Bridge.int(args, "page", 1)
        val search = PoiSearch(context, query)
        search.bound = PoiSearch.SearchBound(
            LatLonPoint(
                Bridge.double(args, "latitude"),
                Bridge.double(args, "longitude")
            ),
            Bridge.int(args, "radius", 3000)
        )
        search.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
            override fun onPoiSearched(poiResult: PoiResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || poiResult == null) {
                    result.error(code.toString(), "POI around search failed", null)
                    return
                }
                result.success(poiPage(poiResult))
            }

            override fun onPoiItemSearched(item: PoiItem?, code: Int) = Unit
        })
        search.searchPOIAsyn()
    }

    private fun searchPoiById(args: Map<*, *>, result: MethodChannel.Result) {
        val id = Bridge.str(args, "id")
        val search = PoiSearch(context, null)
        search.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
            override fun onPoiSearched(poiResult: PoiResult?, code: Int) = Unit

            override fun onPoiItemSearched(item: PoiItem?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || item == null) {
                    result.error(code.toString(), "POI id search failed", null)
                    return
                }
                result.success(mapOf("pois" to listOf(poi(item)), "pageCount" to 1))
            }
        })
        search.searchPOIIdAsyn(id)
    }

    private fun inputTips(args: Map<*, *>, result: MethodChannel.Result) {
        val query = InputtipsQuery(
            Bridge.str(args, "keyword"),
            Bridge.str(args, "city")
        )
        query.cityLimit = Bridge.bool(args, "cityLimit", false)
        if (args["latitude"] != null && args["longitude"] != null) {
            query.location = LatLonPoint(
                Bridge.double(args, "latitude"),
                Bridge.double(args, "longitude")
            )
        }
        val tips = Inputtips(context, query)
        tips.setInputtipsListener(object : Inputtips.InputtipsListener {
            override fun onGetInputtips(list: List<Tip>?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || list == null) {
                    result.error(code.toString(), "Input tips failed", null)
                    return
                }
                result.success(mapOf("tips" to list.map { tip(it) }))
            }
        })
        tips.requestInputtipsAsyn()
    }

    private fun geocode(args: Map<*, *>, result: MethodChannel.Result) {
        val search = GeocodeSearch(context)
        search.setOnGeocodeSearchListener(object : GeocodeSearch.OnGeocodeSearchListener {
            override fun onRegeocodeSearched(regeocodeResult: RegeocodeResult?, code: Int) = Unit
            override fun onGeocodeSearched(geocodeResult: GeocodeResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || geocodeResult == null) {
                    result.error(code.toString(), "Geocode failed", null)
                    return
                }
                result.success(
                    mapOf(
                        "geocodes" to (geocodeResult.geocodeAddressList ?: emptyList())
                            .map { address(it) }
                    )
                )
            }
        })
        search.getFromLocationNameAsyn(
            GeocodeQuery(Bridge.str(args, "address"), Bridge.str(args, "city"))
        )
    }

    private fun reverseGeocode(args: Map<*, *>, result: MethodChannel.Result) {
        val search = GeocodeSearch(context)
        search.setOnGeocodeSearchListener(object : GeocodeSearch.OnGeocodeSearchListener {
            override fun onGeocodeSearched(geocodeResult: GeocodeResult?, code: Int) = Unit
            override fun onRegeocodeSearched(regeocodeResult: RegeocodeResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || regeocodeResult == null) {
                    result.error(code.toString(), "Reverse geocode failed", null)
                    return
                }
                result.success(regeocode(regeocodeResult.regeocodeAddress))
            }
        })
        search.getFromLocationAsyn(
            RegeocodeQuery(
                LatLonPoint(
                    Bridge.double(args, "latitude"),
                    Bridge.double(args, "longitude")
                ),
                Bridge.double(args, "radius", 1000.0).toFloat(),
                GeocodeSearch.AMAP
            )
        )
    }

    private fun searchDistrict(args: Map<*, *>, result: MethodChannel.Result) {
        val search = DistrictSearch(context)
        val query = DistrictSearchQuery()
        query.keywords = Bridge.str(args, "keyword")
        query.isShowBoundary = true
        query.subDistrict = Bridge.int(args, "subdistrict", 1)
        search.query = query
        search.setOnDistrictSearchListener(object : DistrictSearch.OnDistrictSearchListener {
            override fun onDistrictSearched(districtResult: DistrictResult?) {
                if (districtResult == null ||
                    districtResult.getAMapException() == null ||
                    districtResult.getAMapException().errorCode != AMapException.CODE_AMAP_SUCCESS
                ) {
                    val code = districtResult?.getAMapException()?.errorCode ?: -1
                    result.error(code.toString(), "District search failed", null)
                    return
                }
                result.success(
                    mapOf("districts" to (districtResult.district ?: emptyList()).map { district(it) })
                )
            }
        })
        search.searchDistrictAsyn()
    }

    private fun weather(args: Map<*, *>, result: MethodChannel.Result) {
        val type = if (Bridge.str(args, "type", "live") == "forecast") {
            WeatherSearchQuery.WEATHER_TYPE_FORECAST
        } else {
            WeatherSearchQuery.WEATHER_TYPE_LIVE
        }
        val search = WeatherSearch(context)
        search.setOnWeatherSearchListener(object : WeatherSearch.OnWeatherSearchListener {
            override fun onWeatherLiveSearched(
                weatherResult: LocalWeatherLiveResult?,
                code: Int
            ) {
                if (code != AMapException.CODE_AMAP_SUCCESS || weatherResult?.liveResult == null) {
                    result.error(code.toString(), "Weather search failed", null)
                    return
                }
                result.success(mapOf("live" to liveWeather(weatherResult.liveResult)))
            }

            override fun onWeatherForecastSearched(
                weatherResult: LocalWeatherForecastResult?,
                code: Int
            ) {
                if (code != AMapException.CODE_AMAP_SUCCESS || weatherResult?.forecastResult == null) {
                    result.error(code.toString(), "Weather forecast failed", null)
                    return
                }
                result.success(mapOf("forecast" to forecastWeather(weatherResult.forecastResult)))
            }
        })
        search.query = WeatherSearchQuery(Bridge.str(args, "city"), type)
        search.searchWeatherAsyn()
    }

    private fun trafficStatus(args: Map<*, *>, result: MethodChannel.Result) {
        result.error(
            "unsupported",
            "Traffic status is not exposed by AMap Android SDK 11.3.100.",
            null
        )
    }

    private fun poiPage(result: PoiResult): Map<String, Any?> = mapOf(
        "pageCount" to result.pageCount,
        "pois" to (result.pois ?: emptyList()).map { poi(it) }
    )

    private fun poi(item: PoiItem): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "id" to item.poiId,
            "name" to item.title,
            "address" to item.snippet,
            "type" to item.typeDes,
            "typeCode" to item.typeCode,
            "tel" to item.tel,
            "province" to item.provinceName,
            "city" to item.cityName,
            "district" to item.adName,
            "adCode" to item.adCode,
            "cityCode" to item.cityCode,
            "distance" to item.distance
        )
        item.latLonPoint?.let {
            map["latitude"] = it.latitude
            map["longitude"] = it.longitude
        }
        return map
    }

    private fun tip(item: Tip): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "name" to item.name,
            "address" to item.address,
            "district" to item.district,
            "adcode" to item.adcode,
            "poiId" to item.poiID
        )
        item.point?.let {
            map["latitude"] = it.latitude
            map["longitude"] = it.longitude
        }
        return map
    }

    private fun address(item: GeocodeAddress): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "formattedAddress" to item.formatAddress,
            "province" to item.province,
            "city" to item.city,
            "district" to item.district,
            "adcode" to item.adcode,
            "level" to item.level
        )
        item.latLonPoint?.let {
            map["latitude"] = it.latitude
            map["longitude"] = it.longitude
        }
        return map
    }

    private fun regeocode(address: RegeocodeAddress?): Map<String, Any?> {
        if (address == null) return emptyMap()
        val map = mutableMapOf<String, Any?>(
            "formattedAddress" to address.formatAddress,
            "province" to address.province,
            "city" to address.city,
            "district" to address.district,
            "township" to address.township,
            "neighborhood" to address.neighborhood,
            "building" to address.building,
            "adCode" to address.adCode,
            "cityCode" to address.cityCode
        )
        address.streetNumber?.let {
            map["street"] = it.street
            map["streetNumber"] = it.number
        }
        map["pois"] = (address.pois ?: emptyList()).map { poi(it) }
        map["roads"] = (address.roads ?: emptyList()).map {
            mapOf("name" to it.name, "distance" to it.distance, "direction" to it.direction)
        }
        return map
    }

    private fun district(item: DistrictItem): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "name" to item.name,
            "adCode" to item.adcode,
            "cityCode" to item.citycode,
            "level" to item.level
        )
        item.center?.let {
            map["latitude"] = it.latitude
            map["longitude"] = it.longitude
        }
        map["districts"] = (item.subDistrict ?: emptyList()).map { district(it) }
        map["polylines"] = boundaries(item)
        return map
    }

    private fun boundaries(item: DistrictItem): List<List<List<Double>>> {
        val rings = mutableListOf<List<List<Double>>>()
        val source = item.districtBoundary() ?: return rings
        for (boundary in source) {
            if (boundary.isBlank()) continue
            for (island in boundary.split("|")) {
                val ring = mutableListOf<List<Double>>()
                for (point in island.split(";")) {
                    val coords = point.split(",")
                    if (coords.size >= 2) {
                        val lng = coords[0].trim().toDoubleOrNull() ?: continue
                        val lat = coords[1].trim().toDoubleOrNull() ?: continue
                        ring.add(listOf(lat, lng))
                    }
                }
                if (ring.isNotEmpty()) rings.add(ring)
            }
        }
        return rings
    }

    private fun liveWeather(live: com.amap.api.services.weather.LocalWeatherLive): Map<String, Any?> {
        return mapOf(
            "city" to live.city,
            "weather" to live.weather,
            "temperature" to live.temperature,
            "windDirection" to live.windDirection,
            "windPower" to live.windPower,
            "humidity" to live.humidity,
            "reportTime" to live.reportTime
        )
    }

    private fun forecastWeather(
        forecast: com.amap.api.services.weather.LocalWeatherForecast
    ): List<Map<String, Any?>> {
        return (forecast.weatherForecast ?: emptyList<LocalDayWeatherForecast>()).map {
            mapOf(
                "date" to it.date,
                "dayWeather" to it.dayWeather,
                "nightWeather" to it.nightWeather,
                "dayTemperature" to it.dayTemp,
                "nightTemperature" to it.nightTemp,
                "dayWind" to it.dayWindDirection,
                "nightWind" to it.nightWindDirection
            )
        }
    }
}
