# amap_native_android

Android implementation of the `amap_native` federated Flutter plugins.

## SDK selection

By default this package uses:

```text
com.amap.api:3dmap-location-search:11.3.100_loc11.3.101_sea9.8.1
```

It contains map, search, location, route planning and offline maps, but **not**
the navigation SDK. The Android arm64 release APK for `tsilema` is substantially
smaller with this build.

To include navigation, add this to the host app's `android/gradle.properties`:

```properties
amapNativeNavi=true
```

The plugin then switches to `navi-3dmap-location-search` and adds roughly 70 MB
of navigation native libraries. The two SDK combinations are mutually exclusive.

## Key and privacy

Add the AMap Android key to the host manifest and initialize privacy before any
SDK call. See the repository root README.
