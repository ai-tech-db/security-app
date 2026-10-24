import 'package:flutter/material.dart';
import '../../data/services/vpn_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _vpn = VpnService();
  final _domainController = TextEditingController();
  List<String> _blacklist = [];

  @override
  void initState() {
    super.initState();
    _loadBlacklist();
  }

  Future<void> _loadBlacklist() async {
    final list = await _vpn.getBlacklist();
    if (mounted) setState(() => _blacklist = list);
  }

  Future<void> _addDomain() async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) return;
    final updated = await _vpn.addToBlacklist(domain);
    if (mounted) {
      setState(() {
        _blacklist = updated;
        _domainController.clear();
      });
    }
  }

  Future<void> _removeDomain(String domain) async {
    final updated = await _vpn.removeFromBlacklist(domain);
    if (mounted) setState(() => _blacklist = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings & Blacklist', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Blacklist',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _domainController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. example.com',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addDomain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_blacklist.isEmpty)
            const Text('No domains in blacklist.', style: TextStyle(color: Colors.white54))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _blacklist.map((d) => Chip(
                label: Text(d, style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                deleteIconColor: Colors.white70,
                onDeleted: () => _removeDomain(d),
              )).toList(),
            ),
          const SizedBox(height: 48),
          const Text(
            'Danger Zone',
            style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await _vpn.exitApp();
            },
            icon: const Icon(Icons.power_settings_new),
            label: const Text('Exit Application & Stop VPN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              foregroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
