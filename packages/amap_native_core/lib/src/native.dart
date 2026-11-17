import 'package:flutter/services.dart';

import 'models.dart';

const MethodChannel amapNativeCoreChannel = MethodChannel('amap_native/core');

/// Process-wide AMap bootstrap. Call [initialize] only after privacy consent.
class AmapNative {
  AmapNative._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize({required AmapPrivacy privacy}) async {
    if (!privacy.isAgreed) {
      throw const AmapException(
        'privacy_not_agreed',
        'AMap privacy policy must be shown and agreed before initialization.',
      );
    }
    try {
      await amapNativeCoreChannel.invokeMethod<void>(
        'initialize',
        privacy.toJson(),
      );
      _initialized = true;
    } on MissingPluginException {
      throw const AmapUnsupportedError(
        'No AMap native implementation is registered for this platform.',
      );
    } on PlatformException catch (error) {
      throw AmapException(
        error.code,
        error.message ?? 'AMap initialization failed.',
        error.details,
      );
    }
  }

  static Future<String> platformVersion() async {
    try {
      return await amapNativeCoreChannel.invokeMethod<String>(
            'platformVersion',
          ) ??
          '';
    } on MissingPluginException {
      throw const AmapUnsupportedError(
        'No AMap native implementation is registered for this platform.',
      );
    } on PlatformException catch (error) {
      throw AmapException(
        error.code,
        error.message ?? 'Unable to read AMap platform version.',
        error.details,
      );
    }
  }
}
