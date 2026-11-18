# amap_native_navi

Navigation view and simulated navigation for the
[`amap_native`](https://github.com/SakuraCake/amap_native) federated Flutter
plugins.

Adding this package to an app's `pubspec.yaml` makes `amap_native_android`
switch from `3dmap-location-search` to the combined
`navi-3dmap-location-search` artifact. This adds the AMap navigation native
libraries and requires navigation service access on the AMap Key.

Android only. iOS currently throws `AmapUnsupportedError`.
