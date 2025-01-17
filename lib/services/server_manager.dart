import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/vpn_server.dart';
import 'package:flutter/foundation.dart';

class ServerManager {
  final Map<String, int> _serverPings = {};
  final Map<String, DateTime> _lastPingCheck = {};
  Timer? _pingTimer;

  Future<int> measureServerPing(String host) async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse('https://$host'))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds;
      }
    } catch (e) {
      debugPrint('Error measuring ping: $e');
    }
    return -1;
  }

  Future<List<VpnServer>> getSortedServers(List<VpnServer> servers) async {
    final List<VpnServer> sortedServers = [...servers];
    
    // Update pings for servers that haven't been checked recently
    await Future.wait(
      sortedServers.map((server) async {
        if (_shouldUpdatePing(server.id)) {
          final ping = await measureServerPing(server.country);
          _serverPings[server.id] = ping;
          _lastPingCheck[server.id] = DateTime.now();
        }
      }),
    );

    // Sort servers by ping
    sortedServers.sort((a, b) {
      final pingA = _serverPings[a.id] ?? 999;
      final pingB = _serverPings[b.id] ?? 999;
      return pingA.compareTo(pingB);
    });

    return sortedServers;
  }

  bool _shouldUpdatePing(String serverId) {
    final lastCheck = _lastPingCheck[serverId];
    if (lastCheck == null) return true;
    
    return DateTime.now().difference(lastCheck).inMinutes > 5;
  }

  void startAutoPing() {
    _pingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      // Trigger ping updates for all servers
    });
  }

  void dispose() {
    _pingTimer?.cancel();
  }
} 