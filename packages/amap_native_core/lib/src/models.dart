import 'dart:typed_data';
import 'dart:ui' show Color, Offset;

/// GCJ-02 latitude/longitude pair used by AMap.
class AmapLatLng {
  const AmapLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory AmapLatLng.fromJson(Object? value) {
    final map = _map(value);
    return AmapLatLng(_double(map['latitude']), _double(map['longitude']));
  }

  @override
  bool operator ==(Object other) =>
      other is AmapLatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'AmapLatLng($latitude, $longitude)';
}

class AmapLatLngBounds {
  const AmapLatLngBounds(this.southwest, this.northeast);

  final AmapLatLng southwest;
  final AmapLatLng northeast;

  Map<String, Object?> toJson() => {
    'southwest': southwest.toJson(),
    'northeast': northeast.toJson(),
  };

  factory AmapLatLngBounds.fromJson(Object? value) {
    final map = _map(value);
    return AmapLatLngBounds(
      AmapLatLng.fromJson(map['southwest']),
      AmapLatLng.fromJson(map['northeast']),
    );
  }

  AmapLatLng get center => AmapLatLng(
    (southwest.latitude + northeast.latitude) / 2,
    (southwest.longitude + northeast.longitude) / 2,
  );

  bool contains(AmapLatLng point) =>
      point.latitude >= southwest.latitude &&
      point.latitude <= northeast.latitude &&
      point.longitude >= southwest.longitude &&
      point.longitude <= northeast.longitude;

  @override
  bool operator ==(Object other) =>
      other is AmapLatLngBounds &&
      other.southwest == southwest &&
      other.northeast == northeast;

  @override
  int get hashCode => Object.hash(southwest, northeast);
}

class AmapCameraPosition {
  const AmapCameraPosition({
    required this.target,
    required this.zoom,
    this.bearing = 0,
    this.tilt = 0,
  });

  final AmapLatLng target;
  final double zoom;
  final double bearing;
  final double tilt;

  Map<String, Object?> toJson() => {
    'latitude': target.latitude,
    'longitude': target.longitude,
    'zoom': zoom,
    'bearing': bearing,
    'tilt': tilt,
  };

  factory AmapCameraPosition.fromJson(Object? value) {
    final map = _map(value);
    return AmapCameraPosition(
      target: AmapLatLng.fromJson(map),
      zoom: _double(map['zoom']),
      bearing: _double(map['bearing']),
      tilt: _double(map['tilt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AmapCameraPosition &&
      other.target == target &&
      other.zoom == zoom &&
      other.bearing == bearing &&
      other.tilt == tilt;

  @override
  int get hashCode => Object.hash(target, zoom, bearing, tilt);
}

class AmapScreenCoordinate {
  const AmapScreenCoordinate(this.x, this.y);

  final double x;
  final double y;

  Map<String, Object?> toJson() => {'x': x, 'y': y};

  factory AmapScreenCoordinate.fromJson(Object? value) {
    final map = _map(value);
    return AmapScreenCoordinate(_double(map['x']), _double(map['y']));
  }

  @override
  bool operator ==(Object other) =>
      other is AmapScreenCoordinate && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class AmapCameraUpdate {
  const AmapCameraUpdate({this.target, this.zoom, this.bearing, this.tilt});

  final AmapLatLng? target;
  final double? zoom;
  final double? bearing;
  final double? tilt;

  Map<String, Object?> toJson() => {
    if (target != null) ...target!.toJson(),
    if (zoom != null) 'zoom': zoom,
    if (bearing != null) 'bearing': bearing,
    if (tilt != null) 'tilt': tilt,
  };

  @override
  String toString() => 'AmapCameraUpdate(${toJson()})';
}

enum AmapCoordinateType { gcj02, wgs84, bd09 }

class AmapException implements Exception {
  const AmapException(this.code, this.message, [this.details]);

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'AmapException($code): $message';
}

class AmapUnsupportedError extends AmapException {
  const AmapUnsupportedError(String message) : super('unsupported', message);
}

class AmapPrivacy {
  const AmapPrivacy({
    required this.containsPolicy,
    required this.shown,
    required this.agreed,
  });

  final bool containsPolicy;
  final bool shown;
  final bool agreed;

  bool get isAgreed => containsPolicy && shown && agreed;

  Map<String, Object?> toJson() => {
    'containsPolicy': containsPolicy,
    'shown': shown,
    'agreed': agreed,
  };

  @override
  bool operator ==(Object other) =>
      other is AmapPrivacy &&
      other.containsPolicy == containsPolicy &&
      other.shown == shown &&
      other.agreed == agreed;

  @override
  int get hashCode => Object.hash(containsPolicy, shown, agreed);
}

enum AmapMapType { normal, satellite, night, navi, terrain }

enum AmapLogoPosition { bottomLeft, bottomCenter, bottomRight }

enum AmapMapLanguage { chinese, english }

class AmapMapStyle {
  const AmapMapStyle._({
    required this.type,
    this.styleId,
    this.styleData,
    this.styleExtraData,
    this.styleTextureData,
  });

  static const AmapMapStyle normal = AmapMapStyle._(
    type: AmapMapStyleType.normal,
    styleId: null,
    styleData: null,
    styleExtraData: null,
    styleTextureData: null,
  );
  static const AmapMapStyle satellite = AmapMapStyle._(
    type: AmapMapStyleType.satellite,
    styleId: null,
    styleData: null,
    styleExtraData: null,
    styleTextureData: null,
  );
  static const AmapMapStyle night = AmapMapStyle._(
    type: AmapMapStyleType.night,
    styleId: null,
    styleData: null,
    styleExtraData: null,
    styleTextureData: null,
  );
  static const AmapMapStyle navi = AmapMapStyle._(
    type: AmapMapStyleType.navi,
    styleId: null,
    styleData: null,
    styleExtraData: null,
    styleTextureData: null,
  );

  const AmapMapStyle.custom({
    this.styleId,
    this.styleData,
    this.styleExtraData,
    this.styleTextureData,
  }) : type = AmapMapStyleType.custom;

  static AmapMapStyle withAssets({
    String? styleId,
    Uint8List? styleData,
    Uint8List? styleExtraData,
    Uint8List? styleTextureData,
  }) => AmapMapStyle.custom(
    styleId: styleId,
    styleData: styleData,
    styleExtraData: styleExtraData,
    styleTextureData: styleTextureData,
  );

  final AmapMapStyleType type;
  final String? styleId;
  final Uint8List? styleData;
  final Uint8List? styleExtraData;
  final Uint8List? styleTextureData;

  Map<String, Object?> toJson() => {
    'type': type.name,
    if (styleId != null) 'styleId': styleId,
    if (styleData != null) 'styleData': styleData,
    if (styleExtraData != null) 'styleExtraData': styleExtraData,
    if (styleTextureData != null) 'styleTextureData': styleTextureData,
  };
}

enum AmapMapStyleType { normal, satellite, night, navi, custom }

class AmapMapOptions {
  const AmapMapOptions({
    this.mapType = AmapMapType.normal,
    this.style = AmapMapStyle.normal,
    this.labelsEnabled = true,
    this.buildingsEnabled = false,
    this.trafficEnabled = false,
    this.compassEnabled = false,
    this.scaleEnabled = false,
    this.zoomControlsEnabled = false,
    this.rotateGesturesEnabled = false,
    this.tiltGesturesEnabled = false,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.minZoom = 3,
    this.maxZoom = 20,
    this.logoPosition = AmapLogoPosition.bottomLeft,
    this.language = AmapMapLanguage.chinese,
  });

  final AmapMapType mapType;
  final AmapMapStyle style;
  final bool labelsEnabled;
  final bool buildingsEnabled;
  final bool trafficEnabled;
  final bool compassEnabled;
  final bool scaleEnabled;
  final bool zoomControlsEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final double minZoom;
  final double maxZoom;
  final AmapLogoPosition logoPosition;
  final AmapMapLanguage language;

  Map<String, Object?> toJson() => {
    'mapType': mapType.name,
    'style': style.toJson(),
    'labelsEnabled': labelsEnabled,
    'buildingsEnabled': buildingsEnabled,
    'trafficEnabled': trafficEnabled,
    'compassEnabled': compassEnabled,
    'scaleEnabled': scaleEnabled,
    'zoomControlsEnabled': zoomControlsEnabled,
    'rotateGesturesEnabled': rotateGesturesEnabled,
    'tiltGesturesEnabled': tiltGesturesEnabled,
    'scrollGesturesEnabled': scrollGesturesEnabled,
    'zoomGesturesEnabled': zoomGesturesEnabled,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'logoPosition': logoPosition.name,
    'language': language.name,
  };
}

class AmapMarker {
  const AmapMarker({
    required this.id,
    required this.position,
    this.iconBytes,
    this.anchor = const Offset(0.5, 1),
    this.alpha = 1,
    this.visible = true,
    this.zIndex = 0,
    this.rotation = 0,
    this.draggable = false,
  });

  final String id;
  final AmapLatLng position;
  final Uint8List? iconBytes;
  final Offset anchor;
  final double alpha;
  final bool visible;
  final int zIndex;
  final double rotation;
  final bool draggable;

  Map<String, Object?> toJson() => {
    'id': id,
    ...position.toJson(),
    if (iconBytes != null) 'icon': iconBytes,
    'anchorX': anchor.dx,
    'anchorY': anchor.dy,
    'alpha': alpha,
    'visible': visible,
    'zIndex': zIndex,
    'rotation': rotation,
    'draggable': draggable,
  };
}

class AmapPolyline {
  const AmapPolyline({
    required this.id,
    required this.points,
    required this.width,
    required this.color,
    this.visible = true,
    this.zIndex = 0,
    this.dashed = false,
  });

  final String id;
  final List<AmapLatLng> points;
  final double width;
  final Color color;
  final bool visible;
  final int zIndex;
  final bool dashed;

  Map<String, Object?> toJson() => {
    'id': id,
    'points': points.map((p) => p.toJson()).toList(),
    'width': width,
    'color': color.toARGB32(),
    'visible': visible,
    'zIndex': zIndex,
    'dashed': dashed,
  };
}

class AmapPolygon {
  const AmapPolygon({
    required this.id,
    required this.points,
    required this.strokeWidth,
    required this.strokeColor,
    required this.fillColor,
    this.visible = true,
    this.zIndex = 0,
  });

  final String id;
  final List<AmapLatLng> points;
  final double strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final bool visible;
  final int zIndex;

  Map<String, Object?> toJson() => {
    'id': id,
    'points': points.map((p) => p.toJson()).toList(),
    'strokeWidth': strokeWidth,
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'visible': visible,
    'zIndex': zIndex,
  };
}

class AmapCircle {
  const AmapCircle({
    required this.id,
    required this.center,
    required this.radius,
    required this.strokeWidth,
    required this.strokeColor,
    required this.fillColor,
    this.visible = true,
    this.zIndex = 0,
  });

  final String id;
  final AmapLatLng center;
  final double radius;
  final double strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final bool visible;
  final int zIndex;

  Map<String, Object?> toJson() => {
    'id': id,
    ...center.toJson(),
    'radius': radius,
    'strokeWidth': strokeWidth,
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'visible': visible,
    'zIndex': zIndex,
  };
}

class AmapTileOverlay {
  const AmapTileOverlay({
    required this.id,
    required this.urlTemplate,
    this.tileSize = 256,
    this.opacity = 1,
    this.zIndex = 0,
    this.minZoom = 0,
    this.maxZoom = 20,
  });

  final String id;
  final String urlTemplate;
  final int tileSize;
  final double opacity;
  final int zIndex;
  final double minZoom;
  final double maxZoom;

  Map<String, Object?> toJson() => {
    'id': id,
    'urlTemplate': urlTemplate,
    'tileSize': tileSize,
    'opacity': opacity,
    'zIndex': zIndex,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
  };
}

class AmapGroundOverlay {
  const AmapGroundOverlay({
    required this.id,
    required this.imageBytes,
    required this.bounds,
    this.transparency = 0,
    this.zIndex = 0,
    this.visible = true,
  });

  final String id;
  final Uint8List imageBytes;
  final AmapLatLngBounds bounds;
  final double transparency;
  final int zIndex;
  final bool visible;

  Map<String, Object?> toJson() => {
    'id': id,
    'imageBytes': imageBytes,
    'bounds': bounds.toJson(),
    'transparency': transparency,
    'zIndex': zIndex,
    'visible': visible,
  };
}

class AmapHeatmap {
  AmapHeatmap({
    required this.id,
    required this.points,
    this.radius = 20,
    this.opacity = 0.7,
    Map<double, Color>? gradient,
  }) : gradient =
           gradient ??
           <double, Color>{
             0.0: const Color(0x000000ff),
             1.0: const Color(0xffff0000),
           };

  final String id;
  final List<AmapLatLng> points;
  final int radius;
  final double opacity;
  final Map<double, Color> gradient;

  Map<String, Object?> toJson() => {
    'id': id,
    'points': points.map((p) => p.toJson()).toList(),
    'radius': radius,
    'opacity': opacity,
    'gradient': gradient.entries
        .map((e) => {'index': e.key, 'color': e.value.toARGB32()})
        .toList(),
  };
}

sealed class AmapMapEvent {
  const AmapMapEvent();

  factory AmapMapEvent.fromJson(Object? value) {
    final map = _map(value);
    final type = _string(map['type']);
    return switch (type) {
      'ready' => const AmapMapReadyEvent(),
      'tap' => AmapMapTapEvent(AmapLatLng.fromJson(map)),
      'longPress' => AmapMapLongPressEvent(AmapLatLng.fromJson(map)),
      'poiTap' => AmapPoiTapEvent(
        point: AmapLatLng.fromJson(map),
        id: _nullableString(map['id']),
        name: _nullableString(map['name']),
      ),
      'markerTap' => AmapMarkerTapEvent(_string(map['id'])),
      'cameraIdle' => AmapCameraIdleEvent(
        AmapCameraPosition.fromJson(map['camera']),
      ),
      'error' => AmapMapErrorEvent(
        code: _string(map['code']),
        message: _string(map['message']),
      ),
      _ => AmapMapErrorEvent(
        code: 'invalid_event',
        message: 'Unknown map event: $type',
      ),
    };
  }
}

final class AmapMapReadyEvent extends AmapMapEvent {
  const AmapMapReadyEvent();
}

final class AmapMapTapEvent extends AmapMapEvent {
  const AmapMapTapEvent(this.point);
  final AmapLatLng point;
}

final class AmapMapLongPressEvent extends AmapMapEvent {
  const AmapMapLongPressEvent(this.point);
  final AmapLatLng point;
}

final class AmapPoiTapEvent extends AmapMapEvent {
  const AmapPoiTapEvent({required this.point, this.id, this.name});
  final AmapLatLng point;
  final String? id;
  final String? name;
}

final class AmapMarkerTapEvent extends AmapMapEvent {
  const AmapMarkerTapEvent(this.markerId);
  final String markerId;
}

final class AmapCameraIdleEvent extends AmapMapEvent {
  const AmapCameraIdleEvent(this.camera);
  final AmapCameraPosition camera;
}

final class AmapMapErrorEvent extends AmapMapEvent {
  const AmapMapErrorEvent({required this.code, required this.message});
  final String code;
  final String message;
}

// Search models.

class AmapPoiQuery {
  const AmapPoiQuery({
    required this.keyword,
    this.city = '',
    this.types = '',
    this.page = 1,
    this.pageSize = 20,
    this.bounds,
  });

  final String keyword;
  final String city;
  final String types;
  final int page;
  final int pageSize;
  final AmapLatLngBounds? bounds;

  Map<String, Object?> toJson() => {
    'keyword': keyword,
    'city': city,
    'types': types,
    'page': page,
    'pageSize': pageSize,
    if (bounds != null) 'bounds': bounds!.toJson(),
  };
}

class AmapAroundQuery {
  const AmapAroundQuery({
    required this.center,
    this.radius = 3000,
    this.keyword = '',
    this.types = '',
    this.page = 1,
    this.pageSize = 20,
  });

  final AmapLatLng center;
  final int radius;
  final String keyword;
  final String types;
  final int page;
  final int pageSize;

  Map<String, Object?> toJson() => {
    ...center.toJson(),
    'radius': radius,
    'keyword': keyword,
    'types': types,
    'page': page,
    'pageSize': pageSize,
  };
}

class AmapInputTipsQuery {
  const AmapInputTipsQuery({
    required this.keyword,
    this.city = '',
    this.cityLimit = false,
    this.location,
  });

  final String keyword;
  final String city;
  final bool cityLimit;
  final AmapLatLng? location;

  Map<String, Object?> toJson() => {
    'keyword': keyword,
    'city': city,
    'cityLimit': cityLimit,
    if (location != null) ...location!.toJson(),
  };
}

class AmapGeocodeQuery {
  const AmapGeocodeQuery({required this.address, this.city = ''});
  final String address;
  final String city;

  Map<String, Object?> toJson() => {'address': address, 'city': city};
}

class AmapRegeocodeQuery {
  const AmapRegeocodeQuery({
    required this.point,
    this.radius = 1000,
    this.extensions = true,
  });
  final AmapLatLng point;
  final double radius;
  final bool extensions;

  Map<String, Object?> toJson() => {
    ...point.toJson(),
    'radius': radius,
    'extensions': extensions,
  };
}

class AmapDistrictQuery {
  const AmapDistrictQuery({
    required this.keyword,
    this.subdistrict = 1,
    this.extensions = true,
  });
  final String keyword;
  final int subdistrict;
  final bool extensions;

  Map<String, Object?> toJson() => {
    'keyword': keyword,
    'subdistrict': subdistrict,
    'extensions': extensions,
  };
}

enum AmapWeatherType { live, forecast }

class AmapWeatherQuery {
  const AmapWeatherQuery({
    required this.city,
    this.type = AmapWeatherType.live,
  });
  final String city;
  final AmapWeatherType type;

  Map<String, Object?> toJson() => {'city': city, 'type': type.name};
}

class AmapTrafficQuery {
  const AmapTrafficQuery({
    required this.center,
    this.radius = 3000,
    this.level = 5,
  });
  final AmapLatLng center;
  final int radius;
  final int level;

  Map<String, Object?> toJson() => {
    ...center.toJson(),
    'radius': radius,
    'level': level,
  };
}

class AmapPoi {
  const AmapPoi({
    required this.id,
    required this.name,
    this.type = '',
    this.address = '',
    this.latLng,
    this.tel = '',
    this.cityName = '',
    this.adcode = '',
    this.distance = 0,
  });

  final String id;
  final String name;
  final String type;
  final String address;
  final AmapLatLng? latLng;
  final String tel;
  final String cityName;
  final String adcode;
  final double distance;

  factory AmapPoi.fromJson(Object? value) {
    final map = _map(value);
    return AmapPoi(
      id: _string(map['id']),
      name: _string(map['name']),
      type: _string(map['type']),
      address: _string(map['address']),
      latLng: map['latitude'] == null
          ? null
          : AmapLatLng(_double(map['latitude']), _double(map['longitude'])),
      tel: _string(map['tel']),
      cityName: _string(map['city']),
      adcode: _string(map['adCode']),
      distance: _double(map['distance']),
    );
  }
}

class AmapPoiPage {
  const AmapPoiPage({required this.items, this.pageCount = 1, this.total = 0});
  final List<AmapPoi> items;
  final int pageCount;
  final int total;

  factory AmapPoiPage.fromJson(Object? value) {
    final map = _map(value);
    final rawItems = (map['pois'] as List<Object?>?) ?? const <Object?>[];
    return AmapPoiPage(
      items: rawItems.map(AmapPoi.fromJson).toList(),
      pageCount: _int(map['pageCount'], 1),
      total: _int(map['total'], 0),
    );
  }
}

class AmapInputTip {
  const AmapInputTip({
    required this.name,
    this.address = '',
    this.district = '',
    this.adcode = '',
    this.poiId = '',
    this.latLng,
  });

  final String name;
  final String address;
  final String district;
  final String adcode;
  final String poiId;
  final AmapLatLng? latLng;

  factory AmapInputTip.fromJson(Object? value) {
    final map = _map(value);
    return AmapInputTip(
      name: _string(map['name']),
      address: _string(map['address']),
      district: _string(map['district']),
      adcode: _string(map['adcode']),
      poiId: _string(map['poiId']),
      latLng: map['latitude'] == null
          ? null
          : AmapLatLng(_double(map['latitude']), _double(map['longitude'])),
    );
  }
}

class AmapGeocodeResult {
  const AmapGeocodeResult({required this.items});
  final List<AmapGeocodeAddress> items;

  factory AmapGeocodeResult.fromJson(Object? value) {
    final map = _map(value);
    final raw = (map['geocodes'] as List<Object?>?) ?? const <Object?>[];
    return AmapGeocodeResult(
      items: raw.map(AmapGeocodeAddress.fromJson).toList(),
    );
  }
}

class AmapGeocodeAddress {
  const AmapGeocodeAddress({
    required this.formattedAddress,
    this.province = '',
    this.city = '',
    this.district = '',
    this.adcode = '',
    this.latLng,
    this.level = '',
  });

  final String formattedAddress;
  final String province;
  final String city;
  final String district;
  final String adcode;
  final AmapLatLng? latLng;
  final String level;

  factory AmapGeocodeAddress.fromJson(Object? value) {
    final map = _map(value);
    return AmapGeocodeAddress(
      formattedAddress: _string(map['formattedAddress']),
      province: _string(map['province']),
      city: _string(map['city']),
      district: _string(map['district']),
      adcode: _string(map['adcode'] ?? map['adCode']),
      latLng: map['latitude'] == null
          ? null
          : AmapLatLng(_double(map['latitude']), _double(map['longitude'])),
      level: _string(map['level']),
    );
  }
}

class AmapRegeocodeResult {
  const AmapRegeocodeResult({
    required this.formattedAddress,
    this.province = '',
    this.city = '',
    this.district = '',
    this.township = '',
    this.neighborhood = '',
    this.building = '',
    this.adcode = '',
    this.cityCode = '',
    this.street = '',
    this.streetNumber = '',
    this.pois = const [],
    this.roads = const [],
  });

  final String formattedAddress;
  final String province;
  final String city;
  final String district;
  final String township;
  final String neighborhood;
  final String building;
  final String adcode;
  final String cityCode;
  final String street;
  final String streetNumber;
  final List<AmapPoi> pois;
  final List<AmapRoad> roads;

  factory AmapRegeocodeResult.fromJson(Object? value) {
    final map = _map(value);
    final rawPois = (map['pois'] as List<Object?>?) ?? const <Object?>[];
    final rawRoads = (map['roads'] as List<Object?>?) ?? const <Object?>[];
    return AmapRegeocodeResult(
      formattedAddress: _string(map['formattedAddress']),
      province: _string(map['province']),
      city: _string(map['city']),
      district: _string(map['district']),
      township: _string(map['township']),
      neighborhood: _string(map['neighborhood']),
      building: _string(map['building']),
      adcode: _string(map['adCode'] ?? map['adcode']),
      cityCode: _string(map['cityCode']),
      street: _string(map['street']),
      streetNumber: _string(map['streetNumber']),
      pois: rawPois.map(AmapPoi.fromJson).toList(),
      roads: rawRoads.map(AmapRoad.fromJson).toList(),
    );
  }
}

class AmapRoad {
  const AmapRoad({required this.name, this.distance = 0, this.direction = ''});
  final String name;
  final double distance;
  final String direction;

  factory AmapRoad.fromJson(Object? value) {
    final map = _map(value);
    return AmapRoad(
      name: _string(map['name']),
      distance: _double(map['distance']),
      direction: _string(map['direction']),
    );
  }
}

class AmapDistrict {
  const AmapDistrict({
    required this.name,
    required this.adcode,
    this.cityCode = '',
    this.level = '',
    this.center,
    this.boundaries = const [],
    this.children = const [],
  });

  final String name;
  final String adcode;
  final String cityCode;
  final String level;
  final AmapLatLng? center;

  /// Each boundary ring is a list of lat/lng points.
  final List<List<AmapLatLng>> boundaries;
  final List<AmapDistrict> children;

  factory AmapDistrict.fromJson(Object? value) {
    final map = _map(value);
    final rawChildren =
        (map['districts'] as List<Object?>?) ?? const <Object?>[];
    final rawPolylines =
        (map['polylines'] as List<Object?>?) ?? const <Object?>[];
    return AmapDistrict(
      name: _string(map['name']),
      adcode: _string(map['adCode'] ?? map['adcode']),
      cityCode: _string(map['cityCode']),
      level: _string(map['level']),
      center: map['latitude'] == null
          ? null
          : AmapLatLng(_double(map['latitude']), _double(map['longitude'])),
      boundaries: rawPolylines.map((ring) {
        final rawPoints = (ring as List<Object?>?) ?? const <Object?>[];
        return rawPoints.map((point) {
          final coords = (point as List<Object?>?) ?? const <Object?>[];
          return AmapLatLng(
            coords.isNotEmpty ? _double(coords[0]) : 0,
            coords.length > 1 ? _double(coords[1]) : 0,
          );
        }).toList();
      }).toList(),
      children: rawChildren.map(AmapDistrict.fromJson).toList(),
    );
  }
}

class AmapWeather {
  const AmapWeather({this.live, this.forecast = const []});
  final AmapLiveWeather? live;
  final List<AmapForecastWeather> forecast;

  factory AmapWeather.fromJson(Object? value) {
    final map = _map(value);
    final rawLive = map['live'];
    final rawForecast =
        (map['forecast'] as List<Object?>?) ?? const <Object?>[];
    return AmapWeather(
      live: rawLive == null ? null : AmapLiveWeather.fromJson(rawLive),
      forecast: rawForecast.map(AmapForecastWeather.fromJson).toList(),
    );
  }
}

class AmapLiveWeather {
  const AmapLiveWeather({
    this.city = '',
    this.weather = '',
    this.temperature = '',
    this.windDirection = '',
    this.windPower = '',
    this.humidity = '',
    this.reportTime = '',
  });

  final String city;
  final String weather;
  final String temperature;
  final String windDirection;
  final String windPower;
  final String humidity;
  final String reportTime;

  factory AmapLiveWeather.fromJson(Object? value) {
    final map = _map(value);
    return AmapLiveWeather(
      city: _string(map['city']),
      weather: _string(map['weather']),
      temperature: _string(map['temperature']),
      windDirection: _string(map['windDirection']),
      windPower: _string(map['windPower']),
      humidity: _string(map['humidity']),
      reportTime: _string(map['reportTime']),
    );
  }
}

class AmapForecastWeather {
  const AmapForecastWeather({
    this.date = '',
    this.dayWeather = '',
    this.nightWeather = '',
    this.dayTemperature = '',
    this.nightTemperature = '',
    this.dayWind = '',
    this.nightWind = '',
  });

  final String date;
  final String dayWeather;
  final String nightWeather;
  final String dayTemperature;
  final String nightTemperature;
  final String dayWind;
  final String nightWind;

  factory AmapForecastWeather.fromJson(Object? value) {
    final map = _map(value);
    return AmapForecastWeather(
      date: _string(map['date']),
      dayWeather: _string(map['dayWeather']),
      nightWeather: _string(map['nightWeather']),
      dayTemperature: _string(map['dayTemperature']),
      nightTemperature: _string(map['nightTemperature']),
      dayWind: _string(map['dayWind']),
      nightWind: _string(map['nightWind']),
    );
  }
}

class AmapTrafficStatus {
  const AmapTrafficStatus({this.description = '', this.roads = const []});
  final String description;
  final List<AmapTrafficRoad> roads;

  factory AmapTrafficStatus.fromJson(Object? value) {
    final map = _map(value);
    final raw = (map['roads'] as List<Object?>?) ?? const <Object?>[];
    return AmapTrafficStatus(
      description: _string(map['description']),
      roads: raw.map(AmapTrafficRoad.fromJson).toList(),
    );
  }
}

class AmapTrafficRoad {
  const AmapTrafficRoad({
    this.name = '',
    this.status = '',
    this.direction = '',
    this.angle = 0,
    this.speed = 0,
  });

  final String name;
  final String status;
  final String direction;
  final double angle;
  final double speed;

  factory AmapTrafficRoad.fromJson(Object? value) {
    final map = _map(value);
    return AmapTrafficRoad(
      name: _string(map['name']),
      status: _string(map['status']),
      direction: _string(map['direction']),
      angle: _double(map['angle']),
      speed: _double(map['speed']),
    );
  }
}

// Location models.

class AmapLocationOption {
  const AmapLocationOption({
    this.onceLocation = true,
    this.intervalMs = 2000,
    this.needAddress = true,
    this.coordinateType = AmapCoordinateType.gcj02,
    this.locationMode = 0,
    this.httpTimeoutMs = 30000,
    this.mockEnable = false,
  });

  final bool onceLocation;
  final int intervalMs;
  final bool needAddress;
  final AmapCoordinateType coordinateType;
  final int locationMode;
  final int httpTimeoutMs;
  final bool mockEnable;

  Map<String, Object?> toJson() => {
    'onceLocation': onceLocation,
    'intervalMs': intervalMs,
    'needAddress': needAddress,
    'coordinateType': coordinateType.name,
    'locationMode': locationMode,
    'httpTimeoutMs': httpTimeoutMs,
    'mockEnable': mockEnable,
  };
}

class AmapLocation {
  const AmapLocation({
    required this.latLng,
    this.coordinateType = AmapCoordinateType.gcj02,
    this.accuracy = 0,
    this.speed = 0,
    this.bearing = 0,
    this.altitude = 0,
    this.address = '',
    this.country = '',
    this.province = '',
    this.city = '',
    this.district = '',
    this.street = '',
    this.timestamp = 0,
    this.errorCode = 0,
    this.errorInfo = '',
  });

  final AmapLatLng latLng;
  final AmapCoordinateType coordinateType;
  final double accuracy;
  final double speed;
  final double bearing;
  final double altitude;
  final String address;
  final String country;
  final String province;
  final String city;
  final String district;
  final String street;
  final int timestamp;
  final int errorCode;
  final String errorInfo;

  factory AmapLocation.fromJson(Object? value) {
    final map = _map(value);
    return AmapLocation(
      latLng: AmapLatLng.fromJson(map),
      coordinateType: AmapCoordinateType.values.firstWhere(
        (e) => e.name == _string(map['coordinateType']),
        orElse: () => AmapCoordinateType.gcj02,
      ),
      accuracy: _double(map['accuracy']),
      speed: _double(map['speed']),
      bearing: _double(map['bearing']),
      altitude: _double(map['altitude']),
      address: _string(map['address']),
      country: _string(map['country']),
      province: _string(map['province']),
      city: _string(map['city']),
      district: _string(map['district']),
      street: _string(map['street']),
      timestamp: _int(map['timestamp'], 0),
      errorCode: _int(map['errorCode'], 0),
      errorInfo: _string(map['errorInfo']),
    );
  }
}

enum AmapGeofenceType { enter, exit, dwell }

class AmapGeofence {
  const AmapGeofence({
    required this.id,
    required this.center,
    required this.radius,
    this.type = AmapGeofenceType.enter,
    this.dwellMs = 10000,
  });

  final String id;
  final AmapLatLng center;
  final double radius;
  final AmapGeofenceType type;
  final int dwellMs;

  Map<String, Object?> toJson() => {
    'id': id,
    ...center.toJson(),
    'radius': radius,
    'type': type.name,
    'dwellMs': dwellMs,
  };
}

enum AmapGeofenceStatus { entered, exited, dwell }

class AmapGeofenceEvent {
  const AmapGeofenceEvent({
    required this.id,
    required this.status,
    required this.latLng,
    this.timestamp = 0,
  });

  final String id;
  final AmapGeofenceStatus status;
  final AmapLatLng latLng;
  final int timestamp;

  factory AmapGeofenceEvent.fromJson(Object? value) {
    final map = _map(value);
    return AmapGeofenceEvent(
      id: _string(map['id']),
      status: AmapGeofenceStatus.values.firstWhere(
        (e) => e.name == _string(map['status']),
        orElse: () => AmapGeofenceStatus.entered,
      ),
      latLng: AmapLatLng.fromJson(map),
      timestamp: _int(map['timestamp'], 0),
    );
  }
}

// Route models.

class AmapDriveQuery {
  const AmapDriveQuery({
    required this.from,
    required this.to,
    this.waypoints = const [],
    this.strategy = 0,
    this.avoidPolygons = const [],
    this.avoidRoad = '',
    this.calculateTolls = false,
    this.calculateTrafficLights = false,
  });

  final AmapLatLng from;
  final AmapLatLng to;
  final List<AmapLatLng> waypoints;
  final int strategy;
  final List<List<AmapLatLng>> avoidPolygons;
  final String avoidRoad;
  final bool calculateTolls;
  final bool calculateTrafficLights;

  Map<String, Object?> toJson() => {
    'from': from.toJson(),
    'to': to.toJson(),
    'waypoints': waypoints.map((p) => p.toJson()).toList(),
    'strategy': strategy,
    'avoidPolygons': avoidPolygons
        .map((ring) => ring.map((p) => p.toJson()).toList())
        .toList(),
    'avoidRoad': avoidRoad,
    'calculateTolls': calculateTolls,
    'calculateTrafficLights': calculateTrafficLights,
  };
}

class AmapWalkQuery {
  const AmapWalkQuery({
    required this.from,
    required this.to,
    this.strategy = 0,
  });
  final AmapLatLng from;
  final AmapLatLng to;
  final int strategy;

  Map<String, Object?> toJson() => {
    'from': from.toJson(),
    'to': to.toJson(),
    'strategy': strategy,
  };
}

class AmapRideQuery {
  const AmapRideQuery({
    required this.from,
    required this.to,
    this.strategy = 0,
  });
  final AmapLatLng from;
  final AmapLatLng to;
  final int strategy;

  Map<String, Object?> toJson() => {
    'from': from.toJson(),
    'to': to.toJson(),
    'strategy': strategy,
  };
}

class AmapTransitQuery {
  const AmapTransitQuery({
    required this.from,
    required this.to,
    this.city = '',
    this.cityd = '',
    this.strategy = 0,
    this.nightFlag = false,
  });

  final AmapLatLng from;
  final AmapLatLng to;
  final String city;
  final String cityd;
  final int strategy;
  final bool nightFlag;

  Map<String, Object?> toJson() => {
    'from': from.toJson(),
    'to': to.toJson(),
    'city': city,
    'cityd': cityd,
    'strategy': strategy,
    'nightFlag': nightFlag,
  };
}

class AmapRouteResult {
  const AmapRouteResult({required this.paths});
  final List<AmapRoutePath> paths;

  factory AmapRouteResult.fromJson(Object? value) {
    final map = _map(value);
    final raw = (map['paths'] as List<Object?>?) ?? const <Object?>[];
    return AmapRouteResult(paths: raw.map(AmapRoutePath.fromJson).toList());
  }
}

class AmapRoutePath {
  const AmapRoutePath({
    required this.distance,
    required this.duration,
    this.steps = const [],
    this.polyline = const [],
    this.tolls = 0,
    this.trafficLights = 0,
  });

  final double distance;
  final double duration;
  final List<AmapRouteStep> steps;
  final List<AmapLatLng> polyline;
  final double tolls;
  final int trafficLights;

  factory AmapRoutePath.fromJson(Object? value) {
    final map = _map(value);
    final rawSteps = (map['steps'] as List<Object?>?) ?? const <Object?>[];
    final rawPolyline =
        (map['polyline'] as List<Object?>?) ?? const <Object?>[];
    return AmapRoutePath(
      distance: _double(map['distance']),
      duration: _double(map['duration']),
      steps: rawSteps.map(AmapRouteStep.fromJson).toList(),
      polyline: rawPolyline.map(AmapLatLng.fromJson).toList(),
      tolls: _double(map['tolls']),
      trafficLights: _int(map['trafficLights'], 0),
    );
  }
}

class AmapRouteStep {
  const AmapRouteStep({
    required this.instruction,
    this.roadName = '',
    this.distance = 0,
    this.duration = 0,
    this.polyline = const [],
    this.action = '',
  });

  final String instruction;
  final String roadName;
  final double distance;
  final double duration;
  final List<AmapLatLng> polyline;
  final String action;

  factory AmapRouteStep.fromJson(Object? value) {
    final map = _map(value);
    final rawPolyline =
        (map['polyline'] as List<Object?>?) ?? const <Object?>[];
    return AmapRouteStep(
      instruction: _string(map['instruction']),
      roadName: _string(map['roadName']),
      distance: _double(map['distance']),
      duration: _double(map['duration']),
      polyline: rawPolyline.map(AmapLatLng.fromJson).toList(),
      action: _string(map['action']),
    );
  }
}

// Navigation models.

class AmapNaviViewOptions {
  const AmapNaviViewOptions({
    this.showTraffic = true,
    this.showCompass = false,
    this.showScale = false,
    this.showZoomControls = false,
    this.autoChangeZoom = true,
    this.naviNightMode = false,
    this.showEndPoint = true,
  });

  final bool showTraffic;
  final bool showCompass;
  final bool showScale;
  final bool showZoomControls;
  final bool autoChangeZoom;
  final bool naviNightMode;
  final bool showEndPoint;

  Map<String, Object?> toJson() => {
    'showTraffic': showTraffic,
    'showCompass': showCompass,
    'showScale': showScale,
    'showZoomControls': showZoomControls,
    'autoChangeZoom': autoChangeZoom,
    'naviNightMode': naviNightMode,
    'showEndPoint': showEndPoint,
  };
}

class AmapNaviRouteQuery {
  const AmapNaviRouteQuery({
    required this.from,
    required this.to,
    this.waypoints = const [],
    this.strategy = 0,
    this.avoidCongestion = true,
  });

  final AmapLatLng from;
  final AmapLatLng to;
  final List<AmapLatLng> waypoints;
  final int strategy;
  final bool avoidCongestion;

  Map<String, Object?> toJson() => {
    'from': from.toJson(),
    'to': to.toJson(),
    'waypoints': waypoints.map((p) => p.toJson()).toList(),
    'strategy': strategy,
    'avoidCongestion': avoidCongestion,
  };
}

class AmapNaviEvent {
  const AmapNaviEvent({required this.type, this.data = const {}});
  final String type;
  final Map<String, Object?> data;

  factory AmapNaviEvent.fromJson(Object? value) {
    final map = _map(value);
    return AmapNaviEvent(
      type: _string(map['type']),
      data: Map<String, Object?>.from(map),
    );
  }
}

// Offline models.

class AmapOfflineMapCity {
  const AmapOfflineMapCity({
    required this.name,
    required this.code,
    this.version = '',
    this.size = 0,
    this.status = 0,
  });

  final String name;
  final String code;
  final String version;
  final int size;
  final int status;

  factory AmapOfflineMapCity.fromJson(Object? value) {
    final map = _map(value);
    return AmapOfflineMapCity(
      name: _string(map['name']),
      code: _string(map['code']),
      version: _string(map['version']),
      size: _int(map['size'], 0),
      status: _int(map['status'], 0),
    );
  }
}

class AmapOfflineEvent {
  const AmapOfflineEvent({
    required this.cityCode,
    this.progress = 0,
    this.complete = false,
    this.errorCode = 0,
    this.message = '',
  });

  final String cityCode;
  final int progress;
  final bool complete;
  final int errorCode;
  final String message;

  factory AmapOfflineEvent.fromJson(Object? value) {
    final map = _map(value);
    return AmapOfflineEvent(
      cityCode: _string(map['cityCode']),
      progress: _int(map['progress'], 0),
      complete: map['complete'] == true,
      errorCode: _int(map['errorCode'], 0),
      message: _string(map['message']),
    );
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _string(Object? value) => value?.toString() ?? '';
String? _nullableString(Object? value) => value?.toString();

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _int(Object? value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
