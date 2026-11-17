import 'package:amap_native_core/amap_native_core.dart';
import 'package:amap_native_platform_interface/amap_native_platform_interface.dart';

export 'package:amap_native_core/amap_native_core.dart'
    show AmapOfflineEvent, AmapOfflineMapCity;

class AmapOfflineMapClient {
  const AmapOfflineMapClient();

  Future<List<AmapOfflineMapCity>> getCities() =>
      AmapOfflinePlatform.instance.getCities();

  Stream<AmapOfflineEvent> get events => AmapOfflinePlatform.instance.events;

  Future<void> download(String cityCode) =>
      AmapOfflinePlatform.instance.download(cityCode);

  Future<void> pause(String cityCode) =>
      AmapOfflinePlatform.instance.pause(cityCode);

  Future<void> resume(String cityCode) =>
      AmapOfflinePlatform.instance.resume(cityCode);

  Future<void> remove(String cityCode) =>
      AmapOfflinePlatform.instance.remove(cityCode);

  Future<void> update(String cityCode) =>
      AmapOfflinePlatform.instance.update(cityCode);
}
