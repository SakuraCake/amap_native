import 'dart:async';

import 'package:amap_native_core/amap_native_core.dart';
import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';
import 'package:flutter/widgets.dart';

export 'package:amap_native_core/amap_native_core.dart'
    show
        AmapCameraPosition,
        AmapCameraUpdate,
        AmapCircle,
        AmapGroundOverlay,
        AmapHeatmap,
        AmapLatLng,
        AmapLatLngBounds,
        AmapMapLanguage,
        AmapMapOptions,
        AmapMapStyle,
        AmapMapType,
        AmapMarker,
        AmapPolygon,
        AmapPolyline,
        AmapScreenCoordinate,
        AmapTileOverlay;
export 'package:amap_native_platform_interface/amap_native_platform_interface.dart'
    show AmapMapController;

class AmapMapView extends StatefulWidget {
  const AmapMapView({
    super.key,
    required this.initialCamera,
    this.options = const AmapMapOptions(),
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.circles = const {},
    this.tileOverlays = const {},
    this.groundOverlays = const {},
    this.heatmaps = const {},
    this.onMapCreated,
    this.onMapReady,
    this.onTap,
    this.onLongPress,
    this.onPoiTap,
    this.onMarkerTap,
    this.onCameraIdle,
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
  final ValueChanged<AmapMapController>? onMapCreated;
  final VoidCallback? onMapReady;
  final ValueChanged<AmapLatLng>? onTap;
  final ValueChanged<AmapLatLng>? onLongPress;
  final ValueChanged<AmapPoiTapEvent>? onPoiTap;
  final ValueChanged<String>? onMarkerTap;
  final ValueChanged<AmapCameraPosition>? onCameraIdle;
  final void Function(String code, String message)? onError;

  @override
  State<AmapMapView> createState() => _AmapMapViewState();
}

class _AmapMapViewState extends State<AmapMapView> {
  int? _viewId;
  AmapMapController? _controller;
  StreamSubscription<AmapMapEvent>? _events;
  String? _lastError;

  @override
  void didUpdateWidget(covariant AmapMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = _viewId;
    if (id == null) return;
    final config = _configuration();
    unawaited(
      AmapMapPlatform.instance.updateOverlays(id, config).catchError((
        Object error,
        StackTrace stack,
      ) {
        _reportError('update_overlays', error.toString());
      }),
    );
  }

  AmapMapViewConfiguration _configuration() => AmapMapViewConfiguration(
    initialCamera: widget.initialCamera,
    options: widget.options,
    markers: widget.markers,
    polylines: widget.polylines,
    polygons: widget.polygons,
    circles: widget.circles,
    tileOverlays: widget.tileOverlays,
    groundOverlays: widget.groundOverlays,
    heatmaps: widget.heatmaps,
    onPlatformViewCreated: _onPlatformViewCreated,
    onError: _reportError,
  );

  void _onPlatformViewCreated(int id) {
    if (!mounted) return;
    _viewId = id;
    final controller = AmapMapPlatform.instance.createController(id);
    _controller = controller;
    _events = AmapMapPlatform.instance
        .eventsFor(id)
        .listen(
          _handleEvent,
          onError: (Object error, StackTrace stack) {
            _reportError('map_events', error.toString());
          },
        );
    widget.onMapCreated?.call(controller);
  }

  void _handleEvent(AmapMapEvent event) {
    switch (event) {
      case AmapMapReadyEvent():
        widget.onMapReady?.call();
      case AmapMapTapEvent(:final point):
        widget.onTap?.call(point);
      case AmapMapLongPressEvent(:final point):
        widget.onLongPress?.call(point);
      case AmapPoiTapEvent():
        widget.onPoiTap?.call(event);
      case AmapMarkerTapEvent(:final markerId):
        widget.onMarkerTap?.call(markerId);
      case AmapCameraIdleEvent(:final camera):
        widget.onCameraIdle?.call(camera);
      case AmapMapErrorEvent(:final code, :final message):
        _reportError(code, message);
    }
  }

  void _reportError(String code, String message) {
    _lastError = message;
    widget.onError?.call(code, message);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    final controller = _controller;
    if (controller != null) {
      unawaited(
        AmapMapPlatform.instance
            .clear(controller.viewId)
            .catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _lastError;
    if (error != null) {
      return ColoredBox(
        color: const Color(0xfff2f2f2),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Map failed to load: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff555555)),
            ),
          ),
        ),
      );
    }
    return AmapMapPlatform.instance.buildView(_configuration());
  }
}

class AmapClusterGroup {
  const AmapClusterGroup({
    required this.markers,
    required this.center,
    required this.screenPosition,
  });

  final List<AmapMarker> markers;
  final AmapLatLng center;
  final Offset screenPosition;

  int get count => markers.length;
}

List<AmapClusterGroup> clusterAmapMarkers({
  required List<AmapMarker> markers,
  required Map<String, Offset> screenPositions,
  double cellSize = 64,
  int minClusterSize = 5,
  int maxGroups = 60,
}) {
  if (markers.isEmpty) return const [];
  final size = cellSize <= 0 ? 64.0 : cellSize;
  final cells = <String, List<AmapMarker>>{};
  final groups = <AmapClusterGroup>[];

  for (final marker in markers) {
    final position = screenPositions[marker.id];
    if (position == null) {
      groups.add(
        AmapClusterGroup(
          markers: [marker],
          center: marker.position,
          screenPosition: const Offset(0, 0),
        ),
      );
      continue;
    }
    final key =
        '${(position.dx / size).floor()}:${(position.dy / size).floor()}';
    cells.putIfAbsent(key, () => []).add(marker);
  }

  for (final cellMarkers in cells.values) {
    if (cellMarkers.length < minClusterSize) {
      groups.addAll(cellMarkers.map(_singleMarkerGroup));
    } else {
      groups.add(_group(cellMarkers, screenPositions));
    }
  }

  if (groups.length <= maxGroups || maxGroups <= 0) return groups;
  groups.sort((a, b) => b.count.compareTo(a.count));
  final kept = groups.take(maxGroups - 1).toList();
  final rest = groups.skip(maxGroups - 1).toList();
  if (rest.isEmpty) return groups;
  final mergedMarkers = rest.expand((g) => g.markers).toList();
  kept.add(_group(mergedMarkers, screenPositions));
  return kept;
}

AmapClusterGroup _singleMarkerGroup(AmapMarker marker) => AmapClusterGroup(
  markers: [marker],
  center: marker.position,
  screenPosition: const Offset(0, 0),
);

AmapClusterGroup _group(
  List<AmapMarker> markers,
  Map<String, Offset> screenPositions,
) {
  final count = markers.length;
  var lat = 0.0;
  var lng = 0.0;
  var x = 0.0;
  var y = 0.0;
  var projected = 0;
  for (final marker in markers) {
    lat += marker.position.latitude;
    lng += marker.position.longitude;
    final position = screenPositions[marker.id];
    if (position != null) {
      x += position.dx;
      y += position.dy;
      projected++;
    }
  }
  return AmapClusterGroup(
    markers: List<AmapMarker>.unmodifiable(markers),
    center: AmapLatLng(lat / count, lng / count),
    screenPosition: projected == 0
        ? const Offset(0, 0)
        : Offset(x / projected, y / projected),
  );
}

/// Re-exported convenience for callers that only need a projected offset.
Offset amapOffsetFromScreenCoordinate(AmapScreenCoordinate coordinate) =>
    Offset(coordinate.x, coordinate.y);

/// Clamp a projected cluster position when a platform returns non-finite data.
Offset safeAmapOffset(Offset offset) => Offset(
  offset.dx.isFinite ? offset.dx : 0,
  offset.dy.isFinite ? offset.dy : 0,
);

/// Distance helper that keeps map callers from importing core directly.
double approximateMapDistance(AmapLatLng a, AmapLatLng b) =>
    AmapCoordinates.distanceMeters(a, b);
