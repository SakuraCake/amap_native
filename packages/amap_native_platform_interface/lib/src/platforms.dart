import 'dart:async';
import 'dart:typed_data';

import 'package:amap_native_core/amap_native_core.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class AmapMapViewConfiguration {
  const AmapMapViewConfiguration({
    required this.initialCamera,
    this.options = const AmapMapOptions(),
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.circles = const {},
    this.tileOverlays = const {},
    this.groundOverlays = const {},
    this.heatmaps = const {},
    this.onPlatformViewCreated,
    this.onError,
  });

  final AmapCameraPosition initialCamera;
  final AmapMapOptions options;
  final Set<AmapMarker> markers;
  final Set<AmapPolyline> polylines;
  final Set<AmapPolygon> polygons;
  final Set<AmapCircle> circles;
  final Set<AmapTileOverlay> tileOverlays;
  final Set<AmapGroundOverlay> groundOverlays;
  final Set<AmapHeatmap> heatmaps;
  final void Function(int viewId)? onPlatformViewCreated;
  final void Function(String code, String message)? onError;

  Map<String, Object?> toCreationParams() => {
    'initialCamera': initialCamera.toJson(),
    'options': options.toJson(),
    'markers': markers.map((e) => e.toJson()).toList(),
    'polylines': polylines.map((e) => e.toJson()).toList(),
    'polygons': polygons.map((e) => e.toJson()).toList(),
    'circles': circles.map((e) => e.toJson()).toList(),
    'tileOverlays': tileOverlays.map((e) => e.toJson()).toList(),
    'groundOverlays': groundOverlays.map((e) => e.toJson()).toList(),
    'heatmaps': heatmaps.map((e) => e.toJson()).toList(),
  };

  Map<String, Object?> toOverlayParams() => {
    'markers': markers.map((e) => e.toJson()).toList(),
    'polylines': polylines.map((e) => e.toJson()).toList(),
    'polygons': polygons.map((e) => e.toJson()).toList(),
    'circles': circles.map((e) => e.toJson()).toList(),
    'tileOverlays': tileOverlays.map((e) => e.toJson()).toList(),
    'groundOverlays': groundOverlays.map((e) => e.toJson()).toList(),
    'heatmaps': heatmaps.map((e) => e.toJson()).toList(),
  };
}

abstract class AmapMapPlatform extends PlatformInterface {
  AmapMapPlatform() : super(token: _token);

  static final Object _token = Object();

  static AmapMapPlatform _instance = UnsupportedAmapMapPlatform();

  static AmapMapPlatform get instance => _instance;

  static set instance(AmapMapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Widget buildView(AmapMapViewConfiguration configuration);

  Stream<AmapMapEvent> eventsFor(int viewId);

  AmapMapController createController(int viewId) =>
      AmapMapController(viewId: viewId);

  Future<void> updateOverlays(
    int viewId,
    AmapMapViewConfiguration configuration,
  );

  Future<void> moveCamera(
    int viewId,
    AmapCameraUpdate update, {
    bool animated = true,
    Duration duration = const Duration(milliseconds: 250),
  });

  Future<void> fitBounds(
    int viewId,
    AmapLatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(48),
    double? maxZoom,
  });

  Future<void> setPadding(int viewId, EdgeInsets padding);

  Future<void> clear(int viewId);

  Future<Uint8List?> snapshot(int viewId);

  Future<List<AmapScreenCoordinate>> project(
    int viewId,
    List<AmapLatLng> points,
  );
}

class AmapMapController {
  AmapMapController({required this.viewId});

  final int viewId;

  Future<void> moveCamera(
    AmapCameraUpdate update, {
    bool animated = true,
    Duration duration = const Duration(milliseconds: 250),
  }) => AmapMapPlatform.instance.moveCamera(
    viewId,
    update,
    animated: animated,
    duration: duration,
  );

  Future<void> fitBounds(
    AmapLatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(48),
    double? maxZoom,
  }) => AmapMapPlatform.instance.fitBounds(
    viewId,
    bounds,
    padding: padding,
    maxZoom: maxZoom,
  );

  Future<void> setPadding(EdgeInsets padding) =>
      AmapMapPlatform.instance.setPadding(viewId, padding);

  Future<Uint8List?> snapshot() => AmapMapPlatform.instance.snapshot(viewId);

  Future<List<AmapScreenCoordinate>> project(List<AmapLatLng> points) =>
      AmapMapPlatform.instance.project(viewId, points);

  Future<void> clear() => AmapMapPlatform.instance.clear(viewId);
}

abstract class AmapSearchPlatform extends PlatformInterface {
  AmapSearchPlatform() : super(token: _token);

  static final Object _token = Object();
  static AmapSearchPlatform _instance = UnsupportedAmapSearchPlatform();

  static AmapSearchPlatform get instance => _instance;

  static set instance(AmapSearchPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<AmapPoiPage> searchPoi(AmapPoiQuery query);
  Future<AmapPoiPage> searchPoiAround(AmapAroundQuery query);
  Future<AmapPoi?> searchPoiById(String id);
  Future<List<AmapInputTip>> inputTips(AmapInputTipsQuery query);
  Future<AmapGeocodeResult> geocode(AmapGeocodeQuery query);
  Future<AmapRegeocodeResult> reverseGeocode(AmapRegeocodeQuery query);
  Future<List<AmapDistrict>> searchDistrict(AmapDistrictQuery query);
  Future<AmapWeather> weather(AmapWeatherQuery query);
  Future<AmapTrafficStatus> trafficStatus(AmapTrafficQuery query);
}

abstract class AmapLocationPlatform extends PlatformInterface {
  AmapLocationPlatform() : super(token: _token);

  static final Object _token = Object();
  static AmapLocationPlatform _instance = UnsupportedAmapLocationPlatform();

  static AmapLocationPlatform get instance => _instance;

  static set instance(AmapLocationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<AmapLocation> get locationEvents;
  Stream<AmapGeofenceEvent> get geofenceEvents;
  Future<void> setOption(AmapLocationOption option);
  Future<void> start();
  Future<void> stop();
  Future<void> destroy();
  Future<AmapLocation?> getLastKnownLocation();
  Future<void> startGeofence(List<AmapGeofence> fences);
  Future<void> stopGeofence();
}

abstract class AmapRoutePlatform extends PlatformInterface {
  AmapRoutePlatform() : super(token: _token);

  static final Object _token = Object();
  static AmapRoutePlatform _instance = UnsupportedAmapRoutePlatform();

  static AmapRoutePlatform get instance => _instance;

  static set instance(AmapRoutePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<AmapRouteResult> drive(AmapDriveQuery query);
  Future<AmapRouteResult> walk(AmapWalkQuery query);
  Future<AmapRouteResult> ride(AmapRideQuery query);
  Future<AmapRouteResult> transit(AmapTransitQuery query);
}

abstract class AmapNaviPlatform extends PlatformInterface {
  AmapNaviPlatform() : super(token: _token);

  static final Object _token = Object();
  static AmapNaviPlatform _instance = UnsupportedAmapNaviPlatform();

  static AmapNaviPlatform get instance => _instance;

  static set instance(AmapNaviPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Widget buildNaviView(AmapNaviViewConfiguration configuration);
  Stream<AmapNaviEvent> eventsFor(int viewId);
  AmapNaviController createController(int viewId) =>
      AmapNaviController(viewId: viewId);
  Future<void> calculateDriveRoute(int viewId, AmapNaviRouteQuery query);
  Future<void> startNavi(int viewId);
  Future<void> stopNavi(int viewId);
  Future<void> pauseNavi(int viewId);
  Future<void> resumeNavi(int viewId);
  Future<void> startSimulateNavigation(int viewId);
  Future<void> stopSimulateNavigation(int viewId);
  Future<void> setVoiceBroadcast(int viewId, bool enabled);
  Future<void> setVolume(int viewId, double volume);
  Future<void> zoomIn(int viewId);
  Future<void> zoomOut(int viewId);
  Future<void> reCenter(int viewId);
  Future<void> disposeNavi(int viewId);
}

class AmapNaviController {
  AmapNaviController({required this.viewId});
  final int viewId;

  Future<void> calculateDriveRoute(AmapNaviRouteQuery query) =>
      AmapNaviPlatform.instance.calculateDriveRoute(viewId, query);
  Future<void> startNavi() => AmapNaviPlatform.instance.startNavi(viewId);
  Future<void> stopNavi() => AmapNaviPlatform.instance.stopNavi(viewId);
  Future<void> pauseNavi() => AmapNaviPlatform.instance.pauseNavi(viewId);
  Future<void> resumeNavi() => AmapNaviPlatform.instance.resumeNavi(viewId);
  Future<void> startSimulateNavigation() =>
      AmapNaviPlatform.instance.startSimulateNavigation(viewId);
  Future<void> stopSimulateNavigation() =>
      AmapNaviPlatform.instance.stopSimulateNavigation(viewId);
  Future<void> setVoiceBroadcast(bool enabled) =>
      AmapNaviPlatform.instance.setVoiceBroadcast(viewId, enabled);
  Future<void> setVolume(double volume) =>
      AmapNaviPlatform.instance.setVolume(viewId, volume);
  Future<void> zoomIn() => AmapNaviPlatform.instance.zoomIn(viewId);
  Future<void> zoomOut() => AmapNaviPlatform.instance.zoomOut(viewId);
  Future<void> reCenter() => AmapNaviPlatform.instance.reCenter(viewId);
  Future<void> dispose() => AmapNaviPlatform.instance.disposeNavi(viewId);
}

class AmapNaviViewConfiguration {
  const AmapNaviViewConfiguration({
    required this.initialCamera,
    this.options = const AmapNaviViewOptions(),
    this.onPlatformViewCreated,
    this.onError,
  });

  final AmapCameraPosition initialCamera;
  final AmapNaviViewOptions options;
  final void Function(int viewId)? onPlatformViewCreated;
  final void Function(String code, String message)? onError;

  Map<String, Object?> toCreationParams() => {
    'initialCamera': initialCamera.toJson(),
    'options': options.toJson(),
  };
}

abstract class AmapOfflinePlatform extends PlatformInterface {
  AmapOfflinePlatform() : super(token: _token);

  static final Object _token = Object();
  static AmapOfflinePlatform _instance = UnsupportedAmapOfflinePlatform();

  static AmapOfflinePlatform get instance => _instance;

  static set instance(AmapOfflinePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<AmapOfflineMapCity>> getCities();
  Stream<AmapOfflineEvent> get events;
  Future<void> download(String cityCode);
  Future<void> pause(String cityCode);
  Future<void> resume(String cityCode);
  Future<void> remove(String cityCode);
  Future<void> update(String cityCode);
}

/// Default implementations used when no platform implementation is installed.
class UnsupportedAmapMapPlatform extends AmapMapPlatform {
  @override
  Widget buildView(AmapMapViewConfiguration configuration) {
    throw const AmapUnsupportedError(_unsupported);
  }

  @override
  Stream<AmapMapEvent> eventsFor(int viewId) =>
      Stream<AmapMapEvent>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<void> updateOverlays(
    int viewId,
    AmapMapViewConfiguration configuration,
  ) => Future<void>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<void> moveCamera(
    int viewId,
    AmapCameraUpdate update, {
    bool animated = true,
    Duration duration = const Duration(milliseconds: 250),
  }) => Future<void>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<void> fitBounds(
    int viewId,
    AmapLatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(48),
    double? maxZoom,
  }) => Future<void>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<void> setPadding(int viewId, EdgeInsets padding) =>
      Future<void>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<void> clear(int viewId) =>
      Future<void>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<Uint8List?> snapshot(int viewId) =>
      Future<Uint8List?>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<List<AmapScreenCoordinate>> project(
    int viewId,
    List<AmapLatLng> points,
  ) => Future<List<AmapScreenCoordinate>>.error(
    const AmapUnsupportedError(_unsupported),
  );
}

class UnsupportedAmapSearchPlatform extends AmapSearchPlatform {
  @override
  Future<AmapPoiPage> searchPoi(AmapPoiQuery query) => _fail();
  @override
  Future<AmapPoiPage> searchPoiAround(AmapAroundQuery query) => _fail();
  @override
  Future<AmapPoi?> searchPoiById(String id) => _fail();
  @override
  Future<List<AmapInputTip>> inputTips(AmapInputTipsQuery query) => _fail();
  @override
  Future<AmapGeocodeResult> geocode(AmapGeocodeQuery query) => _fail();
  @override
  Future<AmapRegeocodeResult> reverseGeocode(AmapRegeocodeQuery query) =>
      _fail();
  @override
  Future<List<AmapDistrict>> searchDistrict(AmapDistrictQuery query) => _fail();
  @override
  Future<AmapWeather> weather(AmapWeatherQuery query) => _fail();
  @override
  Future<AmapTrafficStatus> trafficStatus(AmapTrafficQuery query) => _fail();

  Future<T> _fail<T>() =>
      Future<T>.error(const AmapUnsupportedError(_unsupported));
}

class UnsupportedAmapLocationPlatform extends AmapLocationPlatform {
  @override
  Stream<AmapLocation> get locationEvents =>
      Stream<AmapLocation>.error(const AmapUnsupportedError(_unsupported));

  @override
  Stream<AmapGeofenceEvent> get geofenceEvents =>
      Stream<AmapGeofenceEvent>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<void> setOption(AmapLocationOption option) => _fail<void>();
  @override
  Future<void> start() => _fail<void>();
  @override
  Future<void> stop() => _fail<void>();
  @override
  Future<void> destroy() => _fail<void>();
  @override
  Future<AmapLocation?> getLastKnownLocation() => _fail<AmapLocation?>();
  @override
  Future<void> startGeofence(List<AmapGeofence> fences) => _fail<void>();
  @override
  Future<void> stopGeofence() => _fail<void>();

  Future<T> _fail<T>() =>
      Future<T>.error(const AmapUnsupportedError(_unsupported));
}

class UnsupportedAmapRoutePlatform extends AmapRoutePlatform {
  @override
  Future<AmapRouteResult> drive(AmapDriveQuery query) => _fail();
  @override
  Future<AmapRouteResult> walk(AmapWalkQuery query) => _fail();
  @override
  Future<AmapRouteResult> ride(AmapRideQuery query) => _fail();
  @override
  Future<AmapRouteResult> transit(AmapTransitQuery query) => _fail();

  Future<T> _fail<T>() =>
      Future<T>.error(const AmapUnsupportedError(_unsupported));
}

class UnsupportedAmapNaviPlatform extends AmapNaviPlatform {
  @override
  Widget buildNaviView(AmapNaviViewConfiguration configuration) {
    throw const AmapUnsupportedError(_unsupported);
  }

  @override
  Stream<AmapNaviEvent> eventsFor(int viewId) =>
      Stream<AmapNaviEvent>.error(const AmapUnsupportedError(_unsupported));

  @override
  Future<void> calculateDriveRoute(int viewId, AmapNaviRouteQuery query) =>
      _fail<void>();
  @override
  Future<void> startNavi(int viewId) => _fail<void>();
  @override
  Future<void> stopNavi(int viewId) => _fail<void>();
  @override
  Future<void> pauseNavi(int viewId) => _fail<void>();
  @override
  Future<void> resumeNavi(int viewId) => _fail<void>();
  @override
  Future<void> startSimulateNavigation(int viewId) => _fail<void>();
  @override
  Future<void> stopSimulateNavigation(int viewId) => _fail<void>();
  @override
  Future<void> setVoiceBroadcast(int viewId, bool enabled) => _fail<void>();
  @override
  Future<void> setVolume(int viewId, double volume) => _fail<void>();
  @override
  Future<void> zoomIn(int viewId) => _fail<void>();
  @override
  Future<void> zoomOut(int viewId) => _fail<void>();
  @override
  Future<void> reCenter(int viewId) => _fail<void>();
  @override
  Future<void> disposeNavi(int viewId) => _fail<void>();

  Future<T> _fail<T>() =>
      Future<T>.error(const AmapUnsupportedError(_unsupported));
}

class UnsupportedAmapOfflinePlatform extends AmapOfflinePlatform {
  @override
  Future<List<AmapOfflineMapCity>> getCities() => _fail();
  @override
  Stream<AmapOfflineEvent> get events =>
      Stream<AmapOfflineEvent>.error(const AmapUnsupportedError(_unsupported));
  @override
  Future<void> download(String cityCode) => _fail<void>();
  @override
  Future<void> pause(String cityCode) => _fail<void>();
  @override
  Future<void> resume(String cityCode) => _fail<void>();
  @override
  Future<void> remove(String cityCode) => _fail<void>();
  @override
  Future<void> update(String cityCode) => _fail<void>();

  Future<T> _fail<T>() =>
      Future<T>.error(const AmapUnsupportedError(_unsupported));
}

const String _unsupported =
    'No AMap platform implementation is installed. Add amap_native_android on Android or amap_native_ios on iOS.';
