import 'dart:async';

import 'package:amap_native/amap_native.dart';
import 'package:flutter/material.dart';

const _initialCamera = AmapCameraPosition(
  target: AmapLatLng(43.8845, 125.3181),
  zoom: 13.4,
);

void main() => runApp(const AmapExampleApp());

class AmapExampleApp extends StatelessWidget {
  const AmapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'amap_native example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff1769aa),
        useMaterial3: true,
      ),
      home: const _ConsentPage(),
    );
  }
}

class _ConsentPage extends StatefulWidget {
  const _ConsentPage();

  @override
  State<_ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<_ConsentPage> {
  bool _agreed = false;
  bool _loading = false;
  String? _error;

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AmapNative.initialize(
        privacy: AmapPrivacy(
          containsPolicy: true,
          shown: true,
          agreed: _agreed,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const _HomePage()),
      );
    } on AmapException catch (error) {
      setState(() => _error = '${error.code}: ${error.message}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AMap Native 示例')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.map_outlined, size: 72),
                const SizedBox(height: 16),
                const Text(
                  '本示例使用高德 Android 原生 SDK。请先在 '
                  'android/local.properties 配置 amap.key，并确保 Key '
                  '绑定了示例包名与签名 SHA1。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: (value) =>
                      setState(() => _agreed = value ?? false),
                  title: const Text('我已阅读并同意高德地图隐私政策'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _agreed && !_loading ? _initialize : null,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('开始使用'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  SelectableText(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _MapPage(),
      const _SearchPage(),
      const _LocationPage(),
      const _RoutePage(),
      const _OfflinePage(),
      const _NaviPage(),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: '地图'),
          NavigationDestination(icon: Icon(Icons.search), label: '搜索'),
          NavigationDestination(icon: Icon(Icons.my_location), label: '定位'),
          NavigationDestination(icon: Icon(Icons.route), label: '路线'),
          NavigationDestination(icon: Icon(Icons.download), label: '离线'),
          NavigationDestination(icon: Icon(Icons.navigation), label: '导航'),
        ],
      ),
    );
  }
}

class _MapPage extends StatefulWidget {
  const _MapPage();

  @override
  State<_MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<_MapPage> {
  AmapMapController? _controller;
  String _message = '点击地图或 marker';

  final _markers = {
    const AmapMarker(id: 'a', position: AmapLatLng(43.8845, 125.3181)),
    const AmapMarker(id: 'b', position: AmapLatLng(43.9000, 125.3500)),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地图'),
        actions: [
          IconButton(
            tooltip: '截图',
            onPressed: () async {
              final bytes = await _controller?.snapshot();
              if (!mounted) return;
              setState(() => _message = '截图 ${bytes?.length ?? 0} 字节');
            },
            icon: const Icon(Icons.camera_alt_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          AmapMapView(
            initialCamera: _initialCamera,
            markers: _markers,
            circles: const {
              AmapCircle(
                id: 'center',
                center: AmapLatLng(43.8845, 125.3181),
                radius: 800,
                strokeWidth: 2,
                strokeColor: Color(0x660000ff),
                fillColor: Color(0x220000ff),
              ),
            },
            onMapCreated: (controller) => _controller = controller,
            onTap: (point) => setState(
              () => _message =
                  '点击 ${point.latitude.toStringAsFixed(5)}, '
                  '${point.longitude.toStringAsFixed(5)}',
            ),
            onMarkerTap: (id) => setState(() => _message = 'Marker $id'),
            onPoiTap: (poi) =>
                setState(() => _message = 'POI ${poi.name ?? poi.id ?? ''}'),
            onError: (code, message) =>
                setState(() => _message = '$code: $message'),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_message),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage();

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _search = const AmapSearchClient();
  final _controller = TextEditingController(text: '万达');
  String _result = '输入关键词后搜索';
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      await action();
    } on AmapException catch (error) {
      setState(() => _result = '${error.code}: ${error.message}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '关键词',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _loading
                    ? null
                    : () => _run(() async {
                        final page = await _search.searchPoi(
                          AmapPoiQuery(keyword: _controller.text, city: '长春'),
                        );
                        setState(
                          () => _result = page.items
                              .map((e) => '${e.name} · ${e.address}')
                              .join('\n'),
                        );
                      }),
                child: const Text('POI'),
              ),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _run(() async {
                        final tips = await _search.inputTips(
                          AmapInputTipsQuery(
                            keyword: _controller.text,
                            city: '长春',
                          ),
                        );
                        setState(
                          () => _result = tips
                              .map((e) => '${e.name} · ${e.address}')
                              .join('\n'),
                        );
                      }),
                child: const Text('输入提示'),
              ),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _run(() async {
                        final districts = await _search.searchDistrict(
                          const AmapDistrictQuery(keyword: '长春'),
                        );
                        setState(
                          () => _result = districts
                              .map((e) => '${e.name} · ${e.adcode}')
                              .join('\n'),
                        );
                      }),
                child: const Text('行政区'),
              ),
            ],
          ),
          const Divider(height: 32),
          if (_loading) const LinearProgressIndicator(),
          SelectableText(_result),
        ],
      ),
    );
  }
}

class _LocationPage extends StatefulWidget {
  const _LocationPage();

  @override
  State<_LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<_LocationPage> {
  final _client = const AmapLocationClient();
  StreamSubscription<AmapLocation>? _subscription;
  String _status = '未启动';

  Future<void> _start() async {
    try {
      await _client.setOption(
        const AmapLocationOption(onceLocation: false, intervalMs: 3000),
      );
      _subscription ??= _client.locationEvents.listen((location) {
        setState(
          () => _status =
              '${location.latLng.latitude}, ${location.latLng.longitude}\n'
              '${location.address}',
        );
      });
      await _client.start();
      setState(() => _status = '定位中');
    } on AmapException catch (error) {
      setState(() => _status = '${error.code}: ${error.message}');
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_client.destroy());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('定位')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('定位权限由宿主申请；本例不自动请求权限。'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _start, child: const Text('开始定位')),
            OutlinedButton(
              onPressed: () => _client.stop(),
              child: const Text('停止'),
            ),
            const Divider(height: 32),
            SelectableText(_status),
          ],
        ),
      ),
    );
  }
}

class _RoutePage extends StatefulWidget {
  const _RoutePage();

  @override
  State<_RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<_RoutePage> {
  final _client = const AmapRouteClient();
  String _result = '选择一种路线';

  Future<void> _drive() async {
    try {
      final result = await _client.drive(
        const AmapDriveQuery(
          from: AmapLatLng(43.8845, 125.3181),
          to: AmapLatLng(43.9000, 125.3500),
        ),
      );
      setState(
        () => _result = result.paths.isEmpty
            ? '没有路线'
            : '${result.paths.first.distance.round()} 米 / '
                  '${(result.paths.first.duration / 60).round()} 分钟',
      );
    } on AmapException catch (error) {
      setState(() => _result = '${error.code}: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('路线')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(onPressed: _drive, child: const Text('驾车路线')),
            const SizedBox(height: 24),
            SelectableText(_result),
          ],
        ),
      ),
    );
  }
}

class _OfflinePage extends StatefulWidget {
  const _OfflinePage();

  @override
  State<_OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<_OfflinePage> {
  final _client = const AmapOfflineMapClient();
  StreamSubscription<AmapOfflineEvent>? _subscription;
  List<AmapOfflineMapCity> _cities = const [];
  String _status = '尚未加载';

  Future<void> _load() async {
    try {
      final cities = await _client.getCities();
      setState(() {
        _cities = cities;
        _status = '${cities.length} 个离线城市';
      });
    } on AmapException catch (error) {
      setState(() => _status = '${error.code}: ${error.message}');
    }
  }

  Future<void> _download(AmapOfflineMapCity city) async {
    _subscription ??= _client.events.listen((event) {
      setState(() => _status = '${event.cityCode}: ${event.progress}%');
    });
    try {
      await _client.download(city.code);
      setState(() => _status = '开始下载 ${city.name}');
    } on AmapException catch (error) {
      setState(() => _status = '${error.code}: ${error.message}');
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('离线地图')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(onPressed: _load, child: const Text('加载城市')),
                const SizedBox(height: 8),
                Text(_status),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                return ListTile(
                  title: Text(city.name),
                  subtitle: Text('${city.code} · ${city.size}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _download(city),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NaviPage extends StatefulWidget {
  const _NaviPage();

  @override
  State<_NaviPage> createState() => _NaviPageState();
}

class _NaviPageState extends State<_NaviPage> {
  AmapNaviController? _controller;
  String _status = '等待导航初始化';

  Future<void> _calculate() async {
    try {
      await _controller?.calculateDriveRoute(
        const AmapNaviRouteQuery(
          from: AmapLatLng(43.8845, 125.3181),
          to: AmapLatLng(43.9000, 125.3500),
        ),
      );
      setState(() => _status = '路线计算中');
    } on AmapException catch (error) {
      setState(() => _status = '${error.code}: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导航')),
      body: Column(
        children: [
          Expanded(
            child: AmapNaviView(
              initialCamera: _initialCamera,
              onNaviCreated: (controller) {
                _controller = controller;
                setState(() => _status = '导航已初始化');
              },
              onNaviInfoUpdate: (event) => setState(() => _status = event.type),
              onArriveDestination: () => setState(() => _status = '已到达'),
              onError: (code, message) =>
                  setState(() => _status = '$code: $message'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: _calculate,
                  child: const Text('计算驾车路线'),
                ),
                OutlinedButton(
                  onPressed: () => _controller?.startSimulateNavigation(),
                  child: const Text('模拟导航'),
                ),
                Text(_status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
