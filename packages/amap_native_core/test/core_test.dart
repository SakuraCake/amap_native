import 'dart:typed_data';

import 'package:amap_native_core/amap_native_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmapCoordinates', () {
    test('converts Beijing WGS84 to GCJ-02 within tolerance', () {
      final result = AmapCoordinates.wgs84ToGcj02(
        const AmapLatLng(39.915, 116.404),
      );
      expect(result.latitude, closeTo(39.916404, 1e-5));
      expect(result.longitude, closeTo(116.410244, 1e-5));
    });

    test('returns overseas coordinates unchanged', () {
      const point = AmapLatLng(35.6762, 139.6503);
      expect(AmapCoordinates.wgs84ToGcj02(point), point);
      expect(AmapCoordinates.gcj02ToWgs84(point), point);
    });

    test('distance is symmetric and zero for identical points', () {
      const a = AmapLatLng(43.8845, 125.3181);
      const b = AmapLatLng(43.9000, 125.3500);
      expect(AmapCoordinates.distanceMeters(a, a), 0);
      expect(
        AmapCoordinates.distanceMeters(a, b),
        closeTo(AmapCoordinates.distanceMeters(b, a), 1e-9),
      );
    });
  });

  group('model serialization', () {
    test('camera and map event round trip', () {
      const camera = AmapCameraPosition(
        target: AmapLatLng(43.8845, 125.3181),
        zoom: 13.4,
      );
      final event = AmapMapEvent.fromJson({
        'type': 'cameraIdle',
        'camera': camera.toJson(),
      });
      expect(event, isA<AmapCameraIdleEvent>());
      expect((event as AmapCameraIdleEvent).camera, camera);
    });

    test('poi page parses native fields', () {
      final page = AmapPoiPage.fromJson({
        'pageCount': 2,
        'pois': [
          {
            'id': 'B123',
            'name': '万达广场',
            'address': '红旗街',
            'city': '长春市',
            'adCode': '220104',
            'latitude': 43.86,
            'longitude': 125.29,
          },
        ],
      });
      expect(page.pageCount, 2);
      expect(page.items.single.name, '万达广场');
      expect(page.items.single.latLng, const AmapLatLng(43.86, 125.29));
    });

    test('route path parses steps and polyline', () {
      final path = AmapRoutePath.fromJson({
        'distance': 1200,
        'duration': 300,
        'polyline': [
          {'latitude': 43.8, 'longitude': 125.3},
        ],
        'steps': [
          {
            'instruction': '直行',
            'roadName': '人民大街',
            'distance': 1200,
            'duration': 300,
          },
        ],
      });
      expect(path.polyline.single, const AmapLatLng(43.8, 125.3));
      expect(path.steps.single.roadName, '人民大街');
    });

    test('custom map style serializes style assets', () {
      final style = AmapMapStyle.custom(
        styleId: 'style-1',
        styleData: Uint8List.fromList([1]),
        styleExtraData: Uint8List.fromList([2]),
        styleTextureData: Uint8List.fromList([3]),
      );
      expect(style.toJson()['styleId'], 'style-1');
      expect((style.toJson()['styleData'] as Uint8List).single, 1);
    });
  });
}
