# amap_native

非高德官方维护的 Flutter 原生插件集合，使用 Android 高德 SDK。iOS 第一版只有显式
`AmapUnsupportedError` 桩，不提供原生地图。

## 包

| 包 | 作用 |
| --- | --- |
| `amap_native_core` | 坐标、模型、隐私初始化、异常 |
| `amap_native_platform_interface` | 联邦插件平台契约 |
| `amap_native_map` | 地图 Widget、Controller、覆盖物、Marker 聚合 |
| `amap_native_search` | POI、输入提示、地理/逆地理、行政区、天气、交通态势 |
| `amap_native_location` | 单次/连续定位、地址、电子围栏 |
| `amap_native_route` | 驾车、步行、骑行、公交路线 |
| `amap_native_navi` | 导航 View、模拟导航 |
| `amap_native_offline` | 离线地图城市与下载进度 |
| `amap_native_android` | Android 原生实现（包含导航 SDK） |
| `amap_native_ios` | iOS 显式不支持桩 |
| `amap_native` | 导出全部 Dart API 的门面包 |

## Android 接入

1. 依赖 `amap_native` 和 `amap_native_android`。
2. 在高德控制台创建 Android Key，绑定应用包名和调试/发布 SHA1。
3. 在宿主 `android/app/src/main/AndroidManifest.xml` 的 `<application>` 中加入：

```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="你的 Android Key" />
```

4. 隐私合规：在创建任何地图或启动定位前，由宿主展示隐私政策，取得同意后调用：

```dart
await AmapNative.initialize(
  privacy: AmapPrivacy(
    containsPolicy: true,
    shown: true,
    agreed: true,
  ),
);
```

`amap_native` 不自行弹隐私弹窗，也不会在未同意时调用高德 SDK。

### 单个 Android 实现包的代价

`amap_native_android` 使用 `navi-3dmap-location-search` 组合包，因此同时包含地图、
搜索、定位与导航。高德导航 artifact 与基础地图 artifact 存在重复类；单独拆包会造成
Android 构建冲突。所有 Android 用户都会携带导航 SDK，APK 体积会增大。

高德 AAR 主要提供 ARM 库；x86_64 模拟器可能无法加载地图。

## iOS

依赖 `amap_native` 和 `amap_native_ios`。iOS 能编译，但任何地图/搜索/定位调用会抛出
`AmapUnsupportedError`。不要在 iOS 上把它当作可用地图方案。

## 已知限制

- AMap Android SDK 11.3.100 的搜索包没有公开交通态势查询类，`AmapSearchClient.trafficStatus`
  在 Android 上会返回 `unsupported` 异常；需要交通态势时请使用高德 Web 服务并自行处理 Key 类型。
- 导航 SDK 不提供 TTS 音量设置方法，`AmapNaviController.setVolume` 会返回 `unsupported`；
  `AmapNaviViewOptions.showScale` / `showZoomControls` / `showEndPoint` 没有对应原生开关。
- 地图 `setPadding` 使用 Android View padding，不是高德相机 padding；相机 fitBounds 仍按传入
  padding 计算。
- `tsilema` 只在首页 Android 路径启用原生地图；后台编辑页保留 WebView，直到单独完成原生
  选点回归。

## 样式

Android 原生 SDK 不接受 JavaScript 的 `amap://styles/whitesmoke`。请在高德控制台导出
`style.data` / `style_extra.data`，通过 `AmapCustomStyle` 传入；否则使用
`AmapMapStyle.normal`。

## 开发

```bash
flutter pub get
dart run melos bootstrap
flutter analyze
dart run melos run test
cd example && flutter build apk --debug
```

示例 Key 从 `example/android/local.properties` 的 `amap.key` 读取；仓库不包含真实 Key。
