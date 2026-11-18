# amap_native_platform_interface

Platform contracts shared by the
[`amap_native`](https://github.com/SakuraCake/amap_native) federated Flutter
plugins.

The package defines the map, search, location, route, navigation and offline
platform interfaces. Platform implementations (`amap_native_android` and
`amap_native_ios`) register these interfaces; feature packages call them.

This is an implementation package, not the public application API. Most apps
should depend on `amap_native`.
