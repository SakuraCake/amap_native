# amap_native_android

Android implementation of the `amap_native` federated Flutter plugins.

## SDK selection

By default this package uses:

```text
com.amap.api:3dmap-location-search:11.3.100_loc11.3.101_sea9.8.1
```

It contains map, search, location, route planning and offline maps, but **not**
the navigation SDK. The default `amap_native` umbrella also does not export
navigation APIs.

To include navigation, add the optional Dart package in the app's
`pubspec.yaml`:

```yaml
dependencies:
  amap_native_navi: ^0.1.0
  amap_native_android: ^0.1.0
```

The Android Gradle configuration reads `.dart_tool/package_config.json`; when
`amap_native_navi` is present it switches to `navi-3dmap-location-search` and
adds roughly 70 MB of navigation native libraries. No `gradle.properties` flag
is required. The two SDK combinations are mutually exclusive.

## Key and privacy

Add the AMap Android key to the host manifest and initialize privacy before any
SDK call. See the repository root README.
