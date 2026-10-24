class ConnectionEvent {
  final int uid;
  final String? packageName;
  final String host;
  final int port;
  final String protocol;
  final DateTime timestamp;
  final bool blocked;
  String? organization; // Campo mutabile per la risoluzione ASN

  ConnectionEvent({
    required this.uid,
    this.packageName,
    required this.host,
    required this.port,
    required this.protocol,
    required this.timestamp,
    this.blocked = false,
    this.organization,
  });

  factory ConnectionEvent.fromMap(Map<dynamic, dynamic> m) {
    final host = m['host'] as String? ?? '';
    return ConnectionEvent(
      uid: m['uid'] as int? ?? -1,
      packageName: m['packageName'] as String?,
      host: host,
      port: m['port'] as int? ?? 0,
      protocol: m['protocol'] as String? ?? 'tcp',
      timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int? ?? 0),
      blocked: (m['allowed'] as bool? ?? true) == false,
    );
  }

  String get ip {
    final idx = host.lastIndexOf(':');
    if (idx > 0) return host.substring(0, idx);
    return host;
  }

  int get extractedPort {
    final idx = host.lastIndexOf(':');
    if (idx > 0) {
      final p = int.tryParse(host.substring(idx + 1));
      if (p != null) return p;
    }
    return port;
  }
}
