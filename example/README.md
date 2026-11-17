# amap_native example

Android demo for the native AMap federated plugin.

## Key

Create `android/local.properties` with:

```properties
amap.key=你的 Android Key
```

The Key must be bound to `ink.qichen.amap_native_example` and the debug/release
SHA1. The app shows a privacy consent screen before initializing the SDK.

## Build

```bash
flutter pub get
flutter build apk --debug
```

The demo includes map/overlay/snapshot, POI and district search, location,
route planning, offline city download, and navigation simulation. Runtime map
tests require a real key and an ARM Android device/emulator.

The default build uses the base AMap SDK. This example opts into navigation by
including `amap_native_navi` in `pubspec.yaml`; the Android Gradle plugin detects
that dependency automatically. Remove `amap_native_navi` from the pubspec to
build the smaller base-only APK.
