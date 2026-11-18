# amap_native_offline

Offline map city listing and download management for the
[`amap_native`](https://github.com/SakuraCake/amap_native) federated Flutter
plugins.

Use `AmapOfflineMapClient` for city lists and download, pause, resume, remove
and update operations. Download progress is delivered as a broadcast stream.

Android requires `amap_native_android`; iOS currently throws
`AmapUnsupportedError`. Offline map service access must be enabled for the AMap
Key.
