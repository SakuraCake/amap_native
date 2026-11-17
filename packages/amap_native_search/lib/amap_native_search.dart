import 'package:amap_native_core/amap_native_core.dart';
import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';

export 'package:amap_native_core/amap_native_core.dart'
    show
        AmapAroundQuery,
        AmapDistrict,
        AmapDistrictQuery,
        AmapGeocodeAddress,
        AmapGeocodeQuery,
        AmapGeocodeResult,
        AmapInputTip,
        AmapInputTipsQuery,
        AmapPoi,
        AmapPoiPage,
        AmapPoiQuery,
        AmapRegeocodeQuery,
        AmapRegeocodeResult,
        AmapRoad,
        AmapTrafficQuery,
        AmapTrafficRoad,
        AmapTrafficStatus,
        AmapWeather,
        AmapWeatherQuery,
        AmapWeatherType;

class AmapSearchClient {
  const AmapSearchClient();

  Future<AmapPoiPage> searchPoi(AmapPoiQuery query) =>
      AmapSearchPlatform.instance.searchPoi(query);

  Future<AmapPoiPage> searchPoiAround(AmapAroundQuery query) =>
      AmapSearchPlatform.instance.searchPoiAround(query);

  Future<AmapPoi?> searchPoiById(String id) =>
      AmapSearchPlatform.instance.searchPoiById(id);

  Future<List<AmapInputTip>> inputTips(AmapInputTipsQuery query) =>
      AmapSearchPlatform.instance.inputTips(query);

  Future<AmapGeocodeResult> geocode(AmapGeocodeQuery query) =>
      AmapSearchPlatform.instance.geocode(query);

  Future<AmapRegeocodeResult> reverseGeocode(AmapRegeocodeQuery query) =>
      AmapSearchPlatform.instance.reverseGeocode(query);

  Future<List<AmapDistrict>> searchDistrict(AmapDistrictQuery query) =>
      AmapSearchPlatform.instance.searchDistrict(query);

  Future<AmapWeather> weather(AmapWeatherQuery query) =>
      AmapSearchPlatform.instance.weather(query);

  Future<AmapTrafficStatus> trafficStatus(AmapTrafficQuery query) =>
      AmapSearchPlatform.instance.trafficStatus(query);
}
