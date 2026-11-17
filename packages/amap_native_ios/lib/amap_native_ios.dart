import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';

export 'package:amap_native_core/amap_native_core.dart';

/// Dart-only iOS plugin. Every platform operation throws [AmapUnsupportedError].
class AmapNativeIos {
  AmapNativeIos._();

  static void registerWith() {
    AmapMapPlatform.instance = UnsupportedAmapMapPlatform();
    AmapSearchPlatform.instance = UnsupportedAmapSearchPlatform();
    AmapLocationPlatform.instance = UnsupportedAmapLocationPlatform();
    AmapRoutePlatform.instance = UnsupportedAmapRoutePlatform();
    AmapNaviPlatform.instance = UnsupportedAmapNaviPlatform();
    AmapOfflinePlatform.instance = UnsupportedAmapOfflinePlatform();
  }
}
