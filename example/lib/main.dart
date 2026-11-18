import 'dart:async';

import 'package:amap_native/amap_native.dart';
import 'package:amap_native_navi/amap_native_navi.dart';
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
      appBar: AppBar(title: const Text('AMap Native Example')),
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
                  'This example uses the native AMap Android SDK. Configure '
                  'amap.key in android/local.properties first, and bind the '
                  'Key to the example application ID and signing SHA1.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: (value) =>
                      setState(() => _agreed = value ?? false),
                  title: const Text(
                    'I have read and agree to the AMap privacy policy',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _agreed && !_loading ? _initialize : null,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Get started'),
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
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.my_location),
            label: 'Location',
          ),
          NavigationDestination(icon: Icon(Icons.route), label: 'Route'),
          NavigationDestination(icon: Icon(Icons.download), label: 'Offline'),
          NavigationDestination(
            icon: Icon(Icons.navigation),
            label: 'Navigation',
          ),
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
  String _message = 'Tap the map or a marker';

  final _markers = {
    const AmapMarker(id: 'a', position: AmapLatLng(43.8845, 125.3181)),
    const AmapMarker(id: 'b', position: AmapLatLng(43.9000, 125.3500)),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            tooltip: 'Snapshot',
            onPressed: () async {
              final bytes = await _controller?.snapshot();
              if (!mounted) return;
              setState(() => _message = 'Snapshot ${bytes?.length ?? 0} bytes');
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
                  'Tap ${point.latitude.toStringAsFixed(5)}, '
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
  String _result = 'Enter a keyword, then search';
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
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Keyword',
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
                child: const Text('Input tips'),
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
                child: const Text('District'),
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
  String _status = 'Not started';

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
      setState(() => _status = 'Locating');
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
      appBar: AppBar(title: const Text('Location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The host app requests location permission; this example does not.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _start,
              child: const Text('Start location'),
            ),
            OutlinedButton(
              onPressed: () => _client.stop(),
              child: const Text('Stop'),
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
  String _result = 'Choose a route';

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
            ? 'No route'
            : '${result.paths.first.distance.round()} m / '
                  '${(result.paths.first.duration / 60).round()} min',
      );
    } on AmapException catch (error) {
      setState(() => _result = '${error.code}: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(onPressed: _drive, child: const Text('Driving route')),
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
  String _status = 'Not loaded';

  Future<void> _load() async {
    try {
      final cities = await _client.getCities();
      setState(() {
        _cities = cities;
        _status = '${cities.length} offline cities';
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
      setState(() => _status = 'Downloading ${city.name}');
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
      appBar: AppBar(title: const Text('Offline maps')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _load,
                  child: const Text('Load cities'),
                ),
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
  String _status = 'Waiting for navigation initialization';

  Future<void> _calculate() async {
    try {
      await _controller?.calculateDriveRoute(
        const AmapNaviRouteQuery(
          from: AmapLatLng(43.8845, 125.3181),
          to: AmapLatLng(43.9000, 125.3500),
        ),
      );
      setState(() => _status = 'Calculating route');
    } on AmapException catch (error) {
      setState(() => _status = '${error.code}: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: Column(
        children: [
          Expanded(
            child: AmapNaviView(
              initialCamera: _initialCamera,
              onNaviCreated: (controller) {
                _controller = controller;
                setState(() => _status = 'Navigation initialized');
              },
              onNaviInfoUpdate: (event) => setState(() => _status = event.type),
              onArriveDestination: () => setState(() => _status = 'Arrived'),
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
                  child: const Text('Calculate driving route'),
                ),
                OutlinedButton(
                  onPressed: () => _controller?.startSimulateNavigation(),
                  child: const Text('Simulate navigation'),
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
