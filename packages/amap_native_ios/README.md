# amap_native_ios

Explicit iOS stub for the
[`amap_native`](https://github.com/SakuraCake/amap_native) federated Flutter
plugins.

This package lets an iOS host compile, but it does not provide a native map or
location implementation. Every map, search, location, route, navigation and
offline call throws `AmapUnsupportedError`.

Do not present iOS as a supported native map target in this version. Use a
WebView map or another provider on iOS.
