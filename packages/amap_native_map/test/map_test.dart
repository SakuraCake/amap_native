import 'dart:typed_data';

import 'package:amap_native_core/amap_native_core.dart';
import 'package:amap_native_map/amap_native_map.dart';
import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMapPlatform extends AmapMapPlatform {
  AmapCameraUpdate? camera;
  AmapLatLngBounds? bounds;
  EdgeInsets? padding;
  List<AmapLatLng> projected = const [];
  bool cleared = false;

  @override
  Widget buildView(AmapMapViewConfiguration configuration) =>
      const SizedBox.shrink();

  @override
  Stream<AmapMapEvent> eventsFor(int viewId) => const Stream.empty();

  @override
  Future<void> updateOverlays(
    int viewId,
    AmapMapViewConfiguration configuration,
  ) async {}

  @override
  Future<void> moveCamera(
    int viewId,
    AmapCameraUpdate update, {
    bool animated = true,
    Duration duration = const Duration(milliseconds: 250),
  }) async {
    camera = update;
  }

  @override
  Future<void> fitBounds(
    int viewId,
    AmapLatLngBounds value, {
    EdgeInsets padding = const EdgeInsets.all(48),
    double? maxZoom,
  }) async {
    bounds = value;
    this.padding = padding;
  }

  @override
  Future<void> setPadding(int viewId, EdgeInsets value) async {
    padding = value;
  }

  @override
  Future<void> clear(int viewId) async {
    cleared = true;
  }

  @override
  Future<Uint8List?> snapshot(int viewId) async => Uint8List.fromList([1, 2]);

  @override
  Future<List<AmapScreenCoordinate>> project(
    int viewId,
    List<AmapLatLng> points,
  ) async {
    projected = points;
    return points
        .map((p) => AmapScreenCoordinate(p.longitude, p.latitude))
        .toList();
  }
}

AmapMarker marker(String id, double lat, double lng) =>
    AmapMarker(id: id, position: AmapLatLng(lat, lng));

void main() {
  test('cluster keeps four markers apart and merges five', () {
    final markers = List.generate(
      5,
      (i) => marker('m$i', 43.8, 125.3 + i * 0.0001),
    );
    final positions = <String, Offset>{
      for (var i = 0; i < 4; i++) 'm$i': const Offset(10, 10),
      'm4': const Offset(500, 500),
    };
    final four = clusterAmapMarkers(
      markers: markers.take(4).toList(),
      screenPositions: positions,
    );
    expect(four.length, 4);
    expect(four.every((g) => g.count == 1), isTrue);

    final five = clusterAmapMarkers(
      markers: markers,
      screenPositions: {
        for (var i = 0; i < 5; i++) 'm$i': const Offset(10, 10),
      },
    );
    expect(five.length, 1);
    expect(five.single.count, 5);
    expect(five.single.center.latitude, closeTo(43.8, 1e-9));
    expect(five.single.screenPosition, const Offset(10, 10));
  });

  test('cluster caps at maxGroups and merges the tail', () {
    final markers = <AmapMarker>[];
    final positions = <String, Offset>{};
    for (var group = 0; group < 61; group++) {
      for (var member = 0; member < 5; member++) {
        final id = 'g${group}_m$member';
        markers.add(marker(id, 43.8 + group * 0.001, 125.3));
        positions[id] = Offset(group * 100.0, 20);
      }
    }
    final groups = clusterAmapMarkers(
      markers: markers,
      screenPositions: positions,
      maxGroups: 60,
    );
    expect(groups.length, 60);
    expect(groups.last.count, 10);
  });

  test('controller forwards camera, bounds, projection and snapshot', () async {
    final platform = _FakeMapPlatform();
    AmapMapPlatform.instance = platform;
    final controller = AmapMapPlatform.instance.createController(7);
    const target = AmapLatLng(43.9, 125.4);

    await controller.moveCamera(
      const AmapCameraUpdate(target: target, zoom: 12),
    );
    expect(platform.camera?.target, target);
    await controller.fitBounds(
      const AmapLatLngBounds(AmapLatLng(43.8, 125.2), AmapLatLng(44.0, 125.5)),
      padding: const EdgeInsets.all(12),
    );
    expect(platform.padding, const EdgeInsets.all(12));
    final screen = await controller.project([target]);
    expect(screen.single, const AmapScreenCoordinate(125.4, 43.9));
    expect(await controller.snapshot(), Uint8List.fromList([1, 2]));
    expect(platform.projected.single, target);
  });

  test('default platform reports unsupported', () {
    final platform = UnsupportedAmapMapPlatform();
    expect(
      () => platform.buildView(
        const AmapMapViewConfiguration(
          initialCamera: AmapCameraPosition(target: AmapLatLng(0, 0), zoom: 3),
        ),
      ),
      throwsA(isA<AmapUnsupportedError>()),
    );
  });
}
