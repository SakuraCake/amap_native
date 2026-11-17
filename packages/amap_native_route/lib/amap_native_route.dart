import 'package:amap_native_core/amap_native_core.dart';
import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';

export 'package:amap_native_core/amap_native_core.dart'
    show
        AmapDriveQuery,
        AmapLatLng,
        AmapRideQuery,
        AmapRoutePath,
        AmapRouteResult,
        AmapRouteStep,
        AmapTransitQuery,
        AmapWalkQuery;

class AmapRouteClient {
  const AmapRouteClient();

  Future<AmapRouteResult> drive(AmapDriveQuery query) =>
      AmapRoutePlatform.instance.drive(query);

  Future<AmapRouteResult> walk(AmapWalkQuery query) =>
      AmapRoutePlatform.instance.walk(query);

  Future<AmapRouteResult> ride(AmapRideQuery query) =>
      AmapRoutePlatform.instance.ride(query);

  Future<AmapRouteResult> transit(AmapTransitQuery query) =>
      AmapRoutePlatform.instance.transit(query);
}
