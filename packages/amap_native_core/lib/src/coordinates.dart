import 'dart:math' as math;

import 'models.dart';

/// Coordinate conversions between the systems used by AMap, GPS and Baidu.
class AmapCoordinates {
  const AmapCoordinates._();

  static const double _a = 6378245.0;
  static const double _ee = 0.00669342162296594323;
  static const double _xPi = math.pi * 3000.0 / 180.0;

  static AmapLatLng wgs84ToGcj02(AmapLatLng point) {
    if (_outOfChina(point)) return point;
    final dLat = _transformLat(point.longitude - 105, point.latitude - 35);
    final dLng = _transformLng(point.longitude - 105, point.latitude - 35);
    final radLat = point.latitude / 180 * math.pi;
    var magic = math.sin(radLat);
    magic = 1 - _ee * magic * magic;
    final sqrtMagic = math.sqrt(magic);
    final latitude =
        point.latitude +
        (dLat * 180) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * math.pi);
    final longitude =
        point.longitude +
        (dLng * 180) / (_a / sqrtMagic * math.cos(radLat) * math.pi);
    return AmapLatLng(latitude, longitude);
  }

  static AmapLatLng gcj02ToWgs84(AmapLatLng point) {
    if (_outOfChina(point)) return point;
    final gcj = wgs84ToGcj02(point);
    return AmapLatLng(
      point.latitude * 2 - gcj.latitude,
      point.longitude * 2 - gcj.longitude,
    );
  }

  static AmapLatLng gcj02ToBd09(AmapLatLng point) {
    final z =
        math.sqrt(
          point.longitude * point.longitude + point.latitude * point.latitude,
        ) +
        0.00002 * math.sin(point.latitude * _xPi);
    final theta =
        math.atan2(point.latitude, point.longitude) +
        0.000003 * math.cos(point.longitude * _xPi);
    return AmapLatLng(
      z * math.sin(theta) + 0.006,
      z * math.cos(theta) + 0.0065,
    );
  }

  static AmapLatLng bd09ToGcj02(AmapLatLng point) {
    final x = point.longitude - 0.0065;
    final y = point.latitude - 0.006;
    final z = math.sqrt(x * x + y * y) - 0.00002 * math.sin(y * _xPi);
    final theta = math.atan2(y, x) - 0.000003 * math.cos(x * _xPi);
    return AmapLatLng(z * math.sin(theta), z * math.cos(theta));
  }

  static double distanceMeters(AmapLatLng a, AmapLatLng b) {
    const earthRadius = 6371008.8;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final deltaLat = (b.latitude - a.latitude) * math.pi / 180;
    final deltaLng = (b.longitude - a.longitude) * math.pi / 180;
    final h =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static bool contains(AmapLatLngBounds bounds, AmapLatLng point) =>
      bounds.contains(point);

  static bool _outOfChina(AmapLatLng point) =>
      point.longitude < 72.004 ||
      point.longitude > 137.8347 ||
      point.latitude < 0.8293 ||
      point.latitude > 55.8271;

  static double _transformLat(double x, double y) {
    var ret =
        -100.0 +
        2.0 * x +
        3.0 * y +
        0.2 * y * y +
        0.1 * x * y +
        0.2 * math.sqrt(x.abs());
    ret +=
        (20.0 * math.sin(6.0 * x * math.pi) +
            20.0 * math.sin(2.0 * x * math.pi)) *
        2.0 /
        3.0;
    ret +=
        (20.0 * math.sin(y * math.pi) + 40.0 * math.sin(y / 3.0 * math.pi)) *
        2.0 /
        3.0;
    ret +=
        (160.0 * math.sin(y / 12.0 * math.pi) +
            320 * math.sin(y * math.pi / 30.0)) *
        2.0 /
        3.0;
    return ret;
  }

  static double _transformLng(double x, double y) {
    var ret =
        300.0 +
        x +
        2.0 * y +
        0.1 * x * x +
        0.1 * x * y +
        0.1 * math.sqrt(x.abs());
    ret +=
        (20.0 * math.sin(6.0 * x * math.pi) +
            20.0 * math.sin(2.0 * x * math.pi)) *
        2.0 /
        3.0;
    ret +=
        (20.0 * math.sin(x * math.pi) + 40.0 * math.sin(x / 3.0 * math.pi)) *
        2.0 /
        3.0;
    ret +=
        (150.0 * math.sin(x / 12.0 * math.pi) +
            300.0 * math.sin(x / 30.0 * math.pi)) *
        2.0 /
        3.0;
    return ret;
  }
}
