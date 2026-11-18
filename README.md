# amap_native

Federated Flutter plugins for the native Android AMap SDK. This project is not
maintained by AMap. The iOS implementation is an explicit `AmapUnsupportedError`
stub; it does not provide a native map.

Project home: [skono.dev](https://skono.dev)

## Packages

| Package | Purpose |
| --- | --- |
| `amap_native_core` | Coordinates, models, privacy initialization, exceptions |
| `amap_native_platform_interface` | Federated plugin platform contracts |
| `amap_native_map` | Map widget, controller, overlays, marker clustering |
| `amap_native_search` | POI, input tips, geocoding, reverse geocoding, districts, weather, traffic |
| `amap_native_location` | One-shot and continuous location, address, geofence |
| `amap_native_route` | Driving, walking, cycling and transit routes |
| `amap_native_navi` | Navigation view and simulated navigation |
| `amap_native_offline` | Offline map cities and download progress |
| `amap_native_android` | Android native implementation (includes the navigation SDK) |
| `amap_native_ios` | Explicit unsupported iOS stub |
| `amap_native` | Umbrella package that exports the Dart API |

## Android setup

1. Depend on `amap_native` and `amap_native_android`.
2. Create an Android Key in the AMap console and bind it to the application ID
   and the debug/release SHA1 fingerprints.
3. Add the Key to the host application's `<application>` element in
   `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="YOUR_ANDROID_KEY" />
```

4. Privacy compliance: before creating a map or starting location, the host must
   show its privacy policy and obtain consent, then call:

```dart
await AmapNative.initialize(
  privacy: AmapPrivacy(
    containsPolicy: true,
    shown: true,
    agreed: true,
  ),
);
```

`amap_native` does not show a privacy dialog itself and never calls the AMap SDK
before consent.

### One Android implementation and APK size

`amap_native_android` uses the base artifact
`3dmap-location-search` (map, search, location, route, offline) by default and
does **not** include the navigation native libraries. The default umbrella
package also does not export navigation APIs, so they cannot be called by
accident.

To enable navigation, add:

```yaml
dependencies:
  amap_native_navi: ^0.1.0
  amap_native_android: ^0.1.0
```

The `amap_native_android` Gradle configuration detects `amap_native_navi` in the
dependency graph and switches to `navi-3dmap-location-search`. No
`gradle.properties` flag is required. This adds the roughly 70 MB
`libAMapSDK_NAVI` native library; only apps that need navigation should enable
it. The two AMap SDK artifact combinations are mutually exclusive, and the
plugin never depends on both.

The AMap AARs mainly provide ARM libraries; x86_64 emulators may not load the
map.

## iOS

Depend on `amap_native` and `amap_native_ios`. The app compiles on iOS, but any
map, search or location call throws `AmapUnsupportedError`. Do not treat iOS as
a supported map target in this version.

## Known limitations

- The AMap Android SDK 11.3.100 search artifact does not expose a public traffic
  status class. `AmapSearchClient.trafficStatus` returns an `unsupported`
  exception on Android. Use the AMap Web service with a suitable Key type if
  traffic status is required.
- The navigation SDK does not expose a TTS volume setter.
  `AmapNaviController.setVolume` returns `unsupported`.
  `AmapNaviViewOptions.showScale`, `showZoomControls` and `showEndPoint` have no
  native equivalents.
- `setPadding` applies Android View padding, not AMap camera padding. Camera
  `fitBounds` still uses the supplied padding.
- `tsilema` enables the native map only on the Android home route. The admin
  shop editor keeps its WebView until native point selection is verified
  separately.

## Styling

The native Android SDK does not accept the JavaScript style URI
`amap://styles/whitesmoke`. Export `style.data` and `style_extra.data` from the
AMap console and pass them through `AmapCustomStyle`. Otherwise use
`AmapMapStyle.normal`.

## Language

All repository documentation, code comments and library error messages are in
English. Chinese text is limited to user data, AMap responses and example POI
test fixtures.

## License

The plugin source code in this repository is licensed under the **BSD 3-Clause
License**; see the root `LICENSE` and each package's `LICENSE`.

That license does not cover the AMap Android map SDK, navigation SDK, offline
map data or their resources. Those are licensed by AMap under its own SDK and
service terms, and this repository does not redistribute their source. Users
must comply with AMap's Key, privacy, navigation, offline and commercial usage
requirements. The BSD 3-Clause License does not imply AMap endorsement.

## Development

```bash
flutter pub get
dart run melos bootstrap
flutter analyze
dart run melos run test
cd example && flutter build apk --debug
```

The example reads its Key from `example/android/local.properties` under
`amap.key`; the repository contains no real Key.
