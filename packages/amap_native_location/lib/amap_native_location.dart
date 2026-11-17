import 'package:amap_native_core/amap_native_core.dart';
import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';

export 'package:amap_native_core/amap_native_core.dart'
    show
        AmapCoordinateType,
        AmapGeofence,
        AmapGeofenceEvent,
        AmapGeofenceStatus,
        AmapGeofenceType,
        AmapLatLng,
        AmapLocation,
        AmapLocationOption;

class AmapLocationClient {
  const AmapLocationClient();

  Stream<AmapLocation> get locationEvents =>
      AmapLocationPlatform.instance.locationEvents;

  Stream<AmapGeofenceEvent> get geofenceEvents =>
      AmapLocationPlatform.instance.geofenceEvents;

  Future<void> setOption(AmapLocationOption option) =>
      AmapLocationPlatform.instance.setOption(option);

  Future<void> start() => AmapLocationPlatform.instance.start();

  Future<void> stop() => AmapLocationPlatform.instance.stop();

  Future<void> destroy() => AmapLocationPlatform.instance.destroy();

  Future<AmapLocation?> getLastKnownLocation() =>
      AmapLocationPlatform.instance.getLastKnownLocation();

  Future<void> startGeofence(List<AmapGeofence> fences) =>
      AmapLocationPlatform.instance.startGeofence(fences);

  Future<void> stopGeofence() => AmapLocationPlatform.instance.stopGeofence();
}
