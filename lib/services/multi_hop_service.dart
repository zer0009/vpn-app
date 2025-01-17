import '../models/vpn_server.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MultiHopConfiguration {
  final List<VpnServer> serverChain;
  final bool isEnabled;

  MultiHopConfiguration({
    required this.serverChain,
    this.isEnabled = false,
  });
}

class MultiHopService {
  MultiHopConfiguration? _currentConfig;
  bool _isEnabled = false;

  MultiHopConfiguration? get currentConfig => _currentConfig;
  bool get isEnabled => _isEnabled;

  Future<void> enableMultiHop(List<VpnServer> servers) async {
    if (servers.length < 2) {
      throw Exception('Multi-hop requires at least 2 servers');
    }

    _currentConfig = MultiHopConfiguration(
      serverChain: servers,
      isEnabled: true,
    );
    _isEnabled = true;

    await _configureMultiHop(servers);
  }

  Future<void> disableMultiHop() async {
    _isEnabled = false;
    _currentConfig = null;
    await _resetConfiguration();
  }

  Future<void> _configureMultiHop(List<VpnServer> servers) async {
    const channel = MethodChannel('vpn_app/vpn_config');
    
    try {
      // Convert server chain to format expected by native code
      final serverConfigs = servers.map((server) => {
        'country': server.country,
        'ovpnConfig': server.ovpnConfiguration,
        'ip': server.ip, // You'll need to add this to VpnServer model
      }).toList();

      await channel.invokeMethod('configureMultiHop', {
        'servers': serverConfigs,
      });
    } catch (e) {
      debugPrint('Multi-hop configuration failed: $e');
      throw Exception('Failed to configure multi-hop VPN');
    }
  }

  Future<void> _resetConfiguration() async {
    const channel = MethodChannel('vpn_app/vpn_config');
    
    try {
      await channel.invokeMethod('resetVpnConfiguration');
    } catch (e) {
      debugPrint('Reset configuration failed: $e');
      throw Exception('Failed to reset VPN configuration');
    }
  }
} 