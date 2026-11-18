# amap_native

Umbrella package for the
[`amap_native`](https://github.com/SakuraCake/amap_native) federated Flutter
plugins. It exports the core API plus map, search, location, route and offline
clients.

Android applications must also depend on `amap_native_android`. Add
`amap_native_navi` only when navigation is required; that switches the Android
implementation to the larger combined navigation artifact.

iOS applications depend on `amap_native_ios`; all native operations currently
throw `AmapUnsupportedError`.

Project home: [skono.dev](https://skono.dev)
