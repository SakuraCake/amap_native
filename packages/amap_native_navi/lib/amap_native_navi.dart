import 'dart:async';

import 'package:amap_native_core/amap_native_core.dart';
import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';
import 'package:flutter/widgets.dart';

export 'package:amap_native_core/amap_native_core.dart'
    show
        AmapCameraPosition,
        AmapLatLng,
        AmapNaviEvent,
        AmapNaviRouteQuery,
        AmapNaviViewOptions;
export 'package:amap_native_platform_interface/amap_native_platform_interface.dart'
    show AmapNaviController;

class AmapNaviView extends StatefulWidget {
  const AmapNaviView({
    super.key,
    required this.initialCamera,
    this.options = const AmapNaviViewOptions(),
    this.onNaviCreated,
    this.onNaviInfoUpdate,
    this.onArriveDestination,
    this.onError,
  });

  final AmapCameraPosition initialCamera;
  final AmapNaviViewOptions options;
  final ValueChanged<AmapNaviController>? onNaviCreated;
  final ValueChanged<AmapNaviEvent>? onNaviInfoUpdate;
  final VoidCallback? onArriveDestination;
  final void Function(String code, String message)? onError;

  @override
  State<AmapNaviView> createState() => _AmapNaviViewState();
}

class _AmapNaviViewState extends State<AmapNaviView> {
  AmapNaviController? _controller;
  StreamSubscription<AmapNaviEvent>? _events;
  String? _lastError;

  void _configured(int id) {
    if (!mounted) return;
    final controller = AmapNaviPlatform.instance.createController(id);
    _controller = controller;
    _events = AmapNaviPlatform.instance
        .eventsFor(id)
        .listen(
          (event) {
            switch (event.type) {
              case 'arriveDestination':
                widget.onArriveDestination?.call();
              case 'error':
                _reportError(
                  event.data['code']?.toString() ?? 'navi_error',
                  event.data['message']?.toString() ?? '导航出错',
                );
              default:
                widget.onNaviInfoUpdate?.call(event);
            }
          },
          onError: (Object error, StackTrace stack) {
            _reportError('navi_events', error.toString());
          },
        );
    widget.onNaviCreated?.call(controller);
  }

  void _reportError(String code, String message) {
    _lastError = message;
    widget.onError?.call(code, message);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.dispose().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _lastError;
    if (error != null) {
      return ColoredBox(
        color: const Color(0xfff2f2f2),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '导航加载失败：$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff555555)),
            ),
          ),
        ),
      );
    }
    return AmapNaviPlatform.instance.buildNaviView(
      AmapNaviViewConfiguration(
        initialCamera: widget.initialCamera,
        options: widget.options,
        onPlatformViewCreated: _configured,
        onError: _reportError,
      ),
    );
  }
}
