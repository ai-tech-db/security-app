import 'dart:async';
import 'package:flutter/services.dart';
import '../models/installed_app.dart';

class VpnService {
  static const _method = MethodChannel('com.aitechdb.security.security_monitor/bridge');
  static const _events = EventChannel('com.aitechdb.security.security_monitor/events');
  static const _startResult = EventChannel('com.aitechdb.security.security_monitor/start_result');

  Stream<Map<dynamic, dynamic>> get connectionEvents =>
      _events.receiveBroadcastStream().map((e) => e as Map);

  Stream<bool> get startResult =>
      _startResult.receiveBroadcastStream().map((e) => e as bool);

  Future<bool> startVpn() async =>
      (await _method.invokeMethod<bool>('startVpn')) ?? false;

  Future<void> stopVpn() => _method.invokeMethod('stopVpn');

  Future<bool> getStatus() async =>
      (await _method.invokeMethod<bool>('getStatus')) ?? false;

  Future<List<InstalledApp>> getInstalledApps() async {
    final list = await _method.invokeListMethod<dynamic>('getInstalledApps') ?? [];
    return list.map((e) => InstalledApp.fromMap(e as Map)).toList();
  }

  Future<Map<String, dynamic>?> getApkSignature(String packageName) =>
      _method.invokeMapMethod<String, dynamic>('getApkSignature', {'packageName': packageName});

  Future<List<String>> getBlacklist() async {
    final list = await _method.invokeListMethod<dynamic>('getBlacklist') ?? [];
    return list.map((e) => e as String).toList();
  }

  Future<List<String>> addToBlacklist(String domain) async {
    final list = await _method.invokeListMethod<dynamic>('addToBlacklist', {'domain': domain}) ?? [];
    return list.map((e) => e as String).toList();
  }

  Future<List<String>> removeFromBlacklist(String domain) async {
    final list = await _method.invokeListMethod<dynamic>('removeFromBlacklist', {'domain': domain}) ?? [];
    return list.map((e) => e as String).toList();
  }

  Future<bool> requestIgnoreBatteryOptimization() async =>
      (await _method.invokeMethod<bool>('requestIgnoreBatteryOptimization')) ?? false;

  Future<String> getLogRetention() async =>
      (await _method.invokeMethod<String>('getLogRetention')) ?? 'OFF';

  Future<void> setLogRetention(String value) =>
      _method.invokeMethod('setLogRetention', {'value': value});

  Future<void> exitApp() async {
    await _method.invokeMethod('exitApp');
  }
}
