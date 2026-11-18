import 'dart:async';

import 'package:amap_native_core/amap_native_core.dart';
import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const String _mapViewType = 'amap_native_map_view';
const String _naviViewType = 'amap_native_navi_view';

class AmapNativeAndroid {
  AmapNativeAndroid._();

  static void registerWith() {
    AmapMapPlatform.instance = AmapAndroidMapPlatform();
    AmapSearchPlatform.instance = AmapAndroidSearchPlatform();
    AmapLocationPlatform.instance = AmapAndroidLocationPlatform();
    AmapRoutePlatform.instance = AmapAndroidRoutePlatform();
    AmapNaviPlatform.instance = AmapAndroidNaviPlatform();
    AmapOfflinePlatform.instance = AmapAndroidOfflinePlatform();
  }
}

class AmapAndroidMapPlatform extends AmapMapPlatform {
  MethodChannel _channel(int viewId) =>
      MethodChannel('amap_native/map/$viewId');

  @override
  Widget buildView(AmapMapViewConfiguration configuration) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const AmapUnsupportedError('AMap native map is Android-only.');
    }
    return AndroidView(
      viewType: _mapViewType,
      creationParams: configuration.toCreationParams(),
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: configuration.onPlatformViewCreated,
    );
  }

  @override
  Stream<AmapMapEvent> eventsFor(int viewId) => EventChannel(
    'amap_native/map/$viewId/events',
  ).receiveBroadcastStream().map(AmapMapEvent.fromJson);

  @override
  Future<void> updateOverlays(
    int viewId,
    AmapMapViewConfiguration configuration,
  ) => _call(
    _channel(viewId),
    'updateOverlays',
    configuration.toOverlayParams(),
  );

  @override
  Future<void> moveCamera(
    int viewId,
    AmapCameraUpdate update, {
    bool animated = true,
    Duration duration = const Duration(milliseconds: 250),
  }) => _call(_channel(viewId), 'moveCamera', {
    'update': update.toJson(),
    'animated': animated,
    'duration': duration.inMilliseconds,
  });

  @override
  Future<void> fitBounds(
    int viewId,
    AmapLatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(48),
    double? maxZoom,
  }) => _call(_channel(viewId), 'fitBounds', {
    'bounds': bounds.toJson(),
    'padding': [padding.left, padding.top, padding.right, padding.bottom],
    'maxZoom': ?maxZoom,
  });

  @override
  Future<void> setPadding(int viewId, EdgeInsets padding) =>
      _call(_channel(viewId), 'setPadding', {
        'padding': [padding.left, padding.top, padding.right, padding.bottom],
      });

  @override
  Future<void> clear(int viewId) => _call(_channel(viewId), 'clear', null);

  @override
  Future<Uint8List?> snapshot(int viewId) =>
      _call<Uint8List?>(_channel(viewId), 'snapshot', null);

  @override
  Future<List<AmapScreenCoordinate>> project(
    int viewId,
    List<AmapLatLng> points,
  ) async {
    final result = await _call<List<Object?>>(_channel(viewId), 'project', {
      'points': points.map((p) => p.toJson()).toList(),
    });
    return (result ?? const []).map(AmapScreenCoordinate.fromJson).toList();
  }
}

class AmapAndroidSearchPlatform extends AmapSearchPlatform {
  static const MethodChannel _channel = MethodChannel('amap_native/search');

  @override
  Future<AmapPoiPage> searchPoi(AmapPoiQuery query) async =>
      AmapPoiPage.fromJson(
        await _call<Map<String, Object?>>(
          _channel,
          'searchPoi',
          query.toJson(),
        ),
      );

  @override
  Future<AmapPoiPage> searchPoiAround(AmapAroundQuery query) async =>
      AmapPoiPage.fromJson(
        await _call<Map<String, Object?>>(
          _channel,
          'searchPoiAround',
          query.toJson(),
        ),
      );

  @override
  Future<AmapPoi?> searchPoiById(String id) async {
    final result = await _call<Map<String, Object?>>(
      _channel,
      'searchPoiById',
      {'id': id},
    );
    final page = AmapPoiPage.fromJson(result);
    return page.items.isEmpty ? null : page.items.first;
  }

  @override
  Future<List<AmapInputTip>> inputTips(AmapInputTipsQuery query) async {
    final result = await _call<Map<String, Object?>>(
      _channel,
      'inputTips',
      query.toJson(),
    );
    final list = (result?['tips'] as List<Object?>?) ?? const <Object?>[];
    return list.map(AmapInputTip.fromJson).toList();
  }

  @override
  Future<AmapGeocodeResult> geocode(AmapGeocodeQuery query) async =>
      AmapGeocodeResult.fromJson(
        await _call<Map<String, Object?>>(_channel, 'geocode', query.toJson()),
      );

  @override
  Future<AmapRegeocodeResult> reverseGeocode(AmapRegeocodeQuery query) async =>
      AmapRegeocodeResult.fromJson(
        await _call<Map<String, Object?>>(
          _channel,
          'reverseGeocode',
          query.toJson(),
        ),
      );

  @override
  Future<List<AmapDistrict>> searchDistrict(AmapDistrictQuery query) async {
    final result = await _call<Map<String, Object?>>(
      _channel,
      'searchDistrict',
      query.toJson(),
    );
    final list = (result?['districts'] as List<Object?>?) ?? const <Object?>[];
    return list.map(AmapDistrict.fromJson).toList();
  }

  @override
  Future<AmapWeather> weather(AmapWeatherQuery query) async =>
      AmapWeather.fromJson(
        await _call<Map<String, Object?>>(_channel, 'weather', query.toJson()),
      );

  @override
  Future<AmapTrafficStatus> trafficStatus(AmapTrafficQuery query) async =>
      AmapTrafficStatus.fromJson(
        await _call<Map<String, Object?>>(
          _channel,
          'trafficStatus',
          query.toJson(),
        ),
      );
}

class AmapAndroidLocationPlatform extends AmapLocationPlatform {
  AmapAndroidLocationPlatform() {
    _locations = EventChannel('amap_native/location/events')
        .receiveBroadcastStream()
        .where((event) => _map(event)['eventType'] != 'geofence')
        .map(AmapLocation.fromJson)
        .asBroadcastStream();
    _geofences = EventChannel('amap_native/location/events')
        .receiveBroadcastStream()
        .where((event) => _map(event)['eventType'] == 'geofence')
        .map(AmapGeofenceEvent.fromJson)
        .asBroadcastStream();
  }

  static const MethodChannel _channel = MethodChannel('amap_native/location');
  late final Stream<AmapLocation> _locations;
  late final Stream<AmapGeofenceEvent> _geofences;

  @override
  Stream<AmapLocation> get locationEvents => _locations;

  @override
  Stream<AmapGeofenceEvent> get geofenceEvents => _geofences;

  @override
  Future<void> setOption(AmapLocationOption option) =>
      _call(_channel, 'setOption', option.toJson());

  @override
  Future<void> start() => _call(_channel, 'start', null);

  @override
  Future<void> stop() => _call(_channel, 'stop', null);

  @override
  Future<void> destroy() => _call(_channel, 'destroy', null);

  @override
  Future<AmapLocation?> getLastKnownLocation() async {
    final result = await _call<Map<String, Object?>>(
      _channel,
      'getLastKnownLocation',
      null,
    );
    if (result == null || result['latitude'] == null) return null;
    return AmapLocation.fromJson(result);
  }

  @override
  Future<void> startGeofence(List<AmapGeofence> fences) => _call(
    _channel,
    'startGeofence',
    {'fences': fences.map((fence) => fence.toJson()).toList()},
  );

  @override
  Future<void> stopGeofence() => _call(_channel, 'stopGeofence', null);
}

class AmapAndroidRoutePlatform extends AmapRoutePlatform {
  static const MethodChannel _channel = MethodChannel('amap_native/route');

  @override
  Future<AmapRouteResult> drive(AmapDriveQuery query) async =>
      AmapRouteResult.fromJson(
        await _call<Map<String, Object?>>(_channel, 'drive', query.toJson()),
      );

  @override
  Future<AmapRouteResult> walk(AmapWalkQuery query) async =>
      AmapRouteResult.fromJson(
        await _call<Map<String, Object?>>(_channel, 'walk', query.toJson()),
      );

  @override
  Future<AmapRouteResult> ride(AmapRideQuery query) async =>
      AmapRouteResult.fromJson(
        await _call<Map<String, Object?>>(_channel, 'ride', query.toJson()),
      );

  @override
  Future<AmapRouteResult> transit(AmapTransitQuery query) async =>
      AmapRouteResult.fromJson(
        await _call<Map<String, Object?>>(_channel, 'transit', query.toJson()),
      );
}

class AmapAndroidNaviPlatform extends AmapNaviPlatform {
  MethodChannel _channel(int viewId) =>
      MethodChannel('amap_native/navi/$viewId');

  @override
  Widget buildNaviView(AmapNaviViewConfiguration configuration) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const AmapUnsupportedError(
        'AMap native navigation is Android-only.',
      );
    }
    return AndroidView(
      viewType: _naviViewType,
      creationParams: configuration.toCreationParams(),
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: configuration.onPlatformViewCreated,
    );
  }

  @override
  Stream<AmapNaviEvent> eventsFor(int viewId) => EventChannel(
    'amap_native/navi/$viewId/events',
  ).receiveBroadcastStream().map(AmapNaviEvent.fromJson);

  @override
  Future<void> calculateDriveRoute(int viewId, AmapNaviRouteQuery query) =>
      _call(_channel(viewId), 'calculateDriveRoute', query.toJson());

  @override
  Future<void> startNavi(int viewId) =>
      _call(_channel(viewId), 'startNavi', null);

  @override
  Future<void> stopNavi(int viewId) =>
      _call(_channel(viewId), 'stopNavi', null);

  @override
  Future<void> pauseNavi(int viewId) =>
      _call(_channel(viewId), 'pauseNavi', null);

  @override
  Future<void> resumeNavi(int viewId) =>
      _call(_channel(viewId), 'resumeNavi', null);

  @override
  Future<void> startSimulateNavigation(int viewId) =>
      _call(_channel(viewId), 'startSimulateNavigation', null);

  @override
  Future<void> stopSimulateNavigation(int viewId) =>
      _call(_channel(viewId), 'stopSimulateNavigation', null);

  @override
  Future<void> setVoiceBroadcast(int viewId, bool enabled) =>
      _call(_channel(viewId), 'setVoiceBroadcast', {'enabled': enabled});

  @override
  Future<void> setVolume(int viewId, double volume) =>
      _call(_channel(viewId), 'setVolume', {'volume': volume});

  @override
  Future<void> zoomIn(int viewId) => _call(_channel(viewId), 'zoomIn', null);

  @override
  Future<void> zoomOut(int viewId) => _call(_channel(viewId), 'zoomOut', null);

  @override
  Future<void> reCenter(int viewId) =>
      _call(_channel(viewId), 'reCenter', null);

  @override
  Future<void> disposeNavi(int viewId) =>
      _call(_channel(viewId), 'dispose', null);
}

class AmapAndroidOfflinePlatform extends AmapOfflinePlatform {
  static const MethodChannel _channel = MethodChannel('amap_native/offline');
  static final Stream<AmapOfflineEvent> _events = EventChannel(
    'amap_native/offline/events',
  ).receiveBroadcastStream().map(AmapOfflineEvent.fromJson).asBroadcastStream();

  @override
  Future<List<AmapOfflineMapCity>> getCities() async {
    final result = await _call<List<Object?>>(_channel, 'getCities', null);
    return (result ?? const []).map(AmapOfflineMapCity.fromJson).toList();
  }

  @override
  Stream<AmapOfflineEvent> get events => _events;

  @override
  Future<void> download(String cityCode) =>
      _call(_channel, 'download', {'cityCode': cityCode});

  @override
  Future<void> pause(String cityCode) =>
      _call(_channel, 'pause', {'cityCode': cityCode});

  @override
  Future<void> resume(String cityCode) =>
      _call(_channel, 'resume', {'cityCode': cityCode});

  @override
  Future<void> remove(String cityCode) =>
      _call(_channel, 'remove', {'cityCode': cityCode});

  @override
  Future<void> update(String cityCode) =>
      _call(_channel, 'update', {'cityCode': cityCode});
}

Future<T?> _call<T>(
  MethodChannel channel,
  String method, [
  Object? arguments,
]) async {
  try {
    final result = await channel.invokeMethod<Object?>(method, arguments);
    return _normalize(result) as T?;
  } on MissingPluginException {
    throw const AmapUnsupportedError(
      'No AMap Android implementation is registered.',
    );
  } on PlatformException catch (error) {
    throw AmapException(
      error.code,
      error.message ?? 'AMap call failed: $method',
      error.details,
    );
  }
}

Object? _normalize(Object? value) {
  if (value is Uint8List) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), _normalize(item)));
  }
  if (value is List) return value.map(_normalize).toList();
  return value;
}

Map<String, Object?> _map(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
