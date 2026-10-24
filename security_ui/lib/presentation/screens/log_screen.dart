import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/connection_event.dart';
import '../../data/services/vpn_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _vpn = VpnService();
  final List<ConnectionEvent> _events = [];
  StreamSubscription? _sub;
  bool _onlyBlocked = false;
  String _retention = 'OFF';

  @override
  void initState() {
    super.initState();
    _loadRetention();
    _sub = _vpn.connectionEvents.listen((e) {
      final ev = ConnectionEvent.fromMap(e);
      if (!mounted) return;
      setState(() {
        _events.insert(0, ev);
        if (_events.length > 500) _events.removeLast();
      });
    });
  }


  Future<void> _loadRetention() async {
    final r = await _vpn.getLogRetention();
    if (mounted) setState(() => _retention = r);
  }

  Future<void> _setRetention(String value) async {
    await _vpn.setLogRetention(value);
    if (mounted) setState(() => _retention = value);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _onlyBlocked ? _events.where((e) => e.blocked).toList() : _events;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Recent Connections (${filtered.length})', style: const TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.timer, color: Colors.cyanAccent),
            initialValue: _retention,
            onSelected: _setRetention,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'OFF', child: Text('OFF')),
              PopupMenuItem(value: '24H', child: Text('24 Hours')),
              PopupMenuItem(value: '3D', child: Text('3 Days')),
            ],
          ),
          IconButton(
            icon: Icon(_onlyBlocked ? Icons.filter_alt : Icons.filter_alt_off, color: Colors.cyanAccent),
            onPressed: () => setState(() => _onlyBlocked = !_onlyBlocked),
          ),
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text('No connections recorded.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final e = filtered[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: e.blocked ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: e.blocked ? Colors.redAccent.withOpacity(0.5) : Colors.white12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      e.blocked ? Icons.block : Icons.check_circle_outline,
                      color: e.blocked ? Colors.redAccent : Colors.greenAccent,
                    ),
                    title: Text('${e.ip}:${e.extractedPort}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${e.protocol} · ${e.blocked ? "blocked" : "allowed"}',
                        style: TextStyle(color: e.blocked ? Colors.redAccent : Colors.greenAccent)),
                  ),
                );
              },
            ),
    );
  }
}
