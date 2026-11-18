# amap_native_android

Android implementation of the
[`amap_native`](https://github.com/SakuraCake/amap_native) federated Flutter
plugins, backed by the native AMap Android SDK.

## SDK selection

By default the package uses:

```text
com.amap.api:3dmap-location-search
```

When the application depends on `amap_native_navi`, the Gradle plugin detects
that dependency and switches to:

```text
com.amap.api:navi-3dmap-location-search
```

The two artifacts contain overlapping map, search and location classes, so the
plugin never depends on both. The navigation variant is significantly larger.

## Key and privacy

The host application must declare the Android Key in its manifest:

```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="YOUR_ANDROID_KEY" />
```

Call `AmapNative.initialize` with an agreed `AmapPrivacy` value before creating
any map or starting location. See the repository root README for the full setup
and the Android-only limitation.
