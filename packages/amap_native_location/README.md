# amap_native_location

One-shot and continuous location, address fields and geofencing for the
[`amap_native`](https://github.com/SakuraCake/amap_native) federated Flutter
plugins.

Use `AmapLocationClient`. The host application must request
`ACCESS_FINE_LOCATION` and/or `ACCESS_COARSE_LOCATION`, and must not start
location before the AMap privacy consent has been recorded.

Android requires `amap_native_android`; iOS currently throws
`AmapUnsupportedError`.
