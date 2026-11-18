# amap_native_search

POI search, input tips, geocoding, reverse geocoding, district search and
weather for the [`amap_native`](https://github.com/SakuraCake/amap_native)
federated Flutter plugins.

Use `AmapSearchClient` from this package. Android requires
`amap_native_android`; iOS currently throws `AmapUnsupportedError`.

Traffic status is not exposed by the bundled Android SDK 11.3.100 search
artifact and returns an `unsupported` exception. See the repository root README
for Android Key and privacy setup.
