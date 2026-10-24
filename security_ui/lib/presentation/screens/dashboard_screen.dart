import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../../data/models/connection_event.dart';
import '../../data/models/installed_app.dart';
import '../../data/services/vpn_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _vpn = VpnService();
  final _notifications = FlutterLocalNotificationsPlugin();
  bool _vpnOn = false;
  bool _busy = false;
  bool _onlyBlocked = false;
  List<InstalledApp> _apps = const [];
  List<String> _blacklist = const [];
  final List<ConnectionEvent> _events = [];
  final Map<String, String> _asnCache = {};
  StreamSubscription? _sub;
  final _domainController = TextEditingController();
  bool _notificationsReady = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _sub = _vpn.connectionEvents.listen((e) {
      final ev = ConnectionEvent.fromMap(e);
      if (!mounted) return;
      setState(() {
        _events.insert(0, ev);
        if (_events.length > 500) _events.removeLast();
      });
      if (ev.blocked && _notificationsReady) {
        _showBlockedNotification(ev);
      }
      _resolveAsn(ev);
    }, onError: (err) {
      print('EVENT ERROR: $err');
    });
    _refresh();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _notificationsReady = true;
  }

  // Throttle per dominio: mostra al massimo una notifica ogni 10 secondi per lo stesso sito
  final Map<String, DateTime> _lastNotificationPerDomain = {};
  int _notificationToggle = 0;

  Future<void> _showBlockedNotification(ConnectionEvent e) async {
    final key = e.ip;
    final now = DateTime.now();
    final last = _lastNotificationPerDomain[key];
    if (last != null && now.difference(last).inSeconds < 10) {
      return;
    }
    _lastNotificationPerDomain[key] = now;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'blocked_connections',
        'Blocked Connections',
        importance: Importance.high,
        priority: Priority.high,
        onlyAlertOnce: true,
      ),
    );
    _notificationToggle = 1 - _notificationToggle;
    final id = 1000 + _notificationToggle;
    await _notifications.show(
      id,
      'Connection Blocked',
      '${e.ip}:${e.extractedPort} (${e.protocol})',
      details,
    );
  }

  Future<void> _resolveAsn(ConnectionEvent ev) async {
    final ip = ev.ip;
    if (ip.isEmpty || _asnCache.containsKey(ip) || ev.organization != null) return;
    try {
      final url = Uri.parse('http://ip-api.com/json/$ip?fields=status,org,as');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final org = data['org'] ?? data['as'] ?? 'Unknown';
          _asnCache[ip] = org;
          ev.organization = org;
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final on = await _vpn.getStatus();
      final apps = await _vpn.getInstalledApps();
      final blacklist = await _vpn.getBlacklist();
      if (!mounted) return;
      setState(() {
        _vpnOn = on;
        _apps = apps;
        _blacklist = blacklist;
      });
    } catch (e) {
      print('REFRESH ERROR: $e');
    }
  }

  Future<void> _toggleVpn() async {
    setState(() => _busy = true);
    // Timeout di sicurezza: se la VPN non risponde in 8 secondi, resetta
    final timeout = Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _busy) {
        print('VPN start timeout, resetting');
        setState(() => _busy = false);
      }
    });
    try {
      if (_vpnOn) {
        await _vpn.stopVpn();
        await _refresh();
        if (mounted) setState(() => _busy = false);
      } else {
        final ok = await _vpn.startVpn();
        print('startVpn returned: $ok');
        if (ok != true) {
          if (mounted) setState(() => _busy = false);
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
          await _refresh();
          if (mounted) setState(() => _busy = false);
        }
      }
    } catch (e) {
      print('TOGGLE ERROR: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestBatteryExemption() async {
    await _vpn.requestIgnoreBatteryOptimization();
  }

  Future<void> _addDomain() async {
    final d = _domainController.text.trim();
    if (d.isEmpty) return;
    try {
      final updated = await _vpn.addToBlacklist(d);
      if (!mounted) return;
      setState(() {
        _blacklist = updated;
        _domainController.clear();
      });
    } catch (e) {
      print('ADD ERROR: $e');
    }
  }

  Future<void> _removeDomain(String domain) async {
    try {
      final updated = await _vpn.removeFromBlacklist(domain);
      if (!mounted) return;
      setState(() => _blacklist = updated);
    } catch (e) {
      print('REMOVE ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final suspicious = _apps.where((a) => a.isSuspicious).toList();
    final filtered = _onlyBlocked ? _events.where((e) => e.blocked).toList() : _events;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.cyanAccent, size: 28),
            const SizedBox(width: 8),
            const Text('Security APP', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_onlyBlocked ? Icons.filter_alt : Icons.filter_alt_off, color: Colors.cyanAccent),
            onPressed: () => setState(() => _onlyBlocked = !_onlyBlocked),
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh, color: Colors.cyanAccent)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNeonCard(
            gradient: LinearGradient(colors: [Colors.cyanAccent.withOpacity(0.2), Colors.transparent]),
            child: ListTile(
              leading: Icon(_vpnOn ? Icons.shield : Icons.shield_outlined,
                  color: _vpnOn ? Colors.greenAccent : Colors.grey, size: 32),
              title: Text(_vpnOn ? 'VPN Active' : 'VPN Inactive',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Suspicious: ${suspicious.length} · Events: ${_events.length}',
                  style: const TextStyle(color: Colors.grey)),
              trailing: _busy
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Switch(
                      value: _vpnOn,
                      activeColor: Colors.greenAccent,
                      onChanged: (_) => _toggleVpn(),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _buildNeonCard(
            child: ListTile(
              leading: const Icon(Icons.battery_alert_outlined, color: Colors.orangeAccent),
              title: const Text('Battery Optimization', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Keep VPN active in background', style: TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right, color: Colors.cyanAccent),
              onTap: _requestBatteryExemption,
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Suspicious Apps (${suspicious.length})'),
          const SizedBox(height: 8),
          if (suspicious.isEmpty)
            const Text('No suspicious apps found.', style: TextStyle(color: Colors.grey))
          else
            ...suspicious.map((a) => _buildNeonCard(
                  child: ListTile(
                    title: Text(a.label, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Risk: ${a.riskScore} · ${a.riskReasons.join(", ")}',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    trailing: Text('${a.riskScore}',
                        style: TextStyle(
                          color: a.riskScore >= 75 ? Colors.redAccent : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildNeonCard({required Widget child, Color color = Colors.transparent, Gradient? gradient}) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.cyanAccent, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
