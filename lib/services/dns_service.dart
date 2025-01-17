import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DnsConfiguration {
  static const _channel = MethodChannel('vpn_app/dns_control');
  static const List<String> predefinedDns = [
    '1.1.1.1', // Cloudflare
    '8.8.8.8', // Google
    '9.9.9.9', // Quad9
    '208.67.222.222', // OpenDNS
  ];

  String? _currentDns;
  bool _isDnsEncrypted = false;

  Future<void> applyConfiguration() async {
    if (_currentDns == null) return;

    try {
      await _channel.invokeMethod('setDns', {'dns': _currentDns});
      debugPrint('DNS configuration applied: $_currentDns');
    } catch (e) {
      debugPrint('Failed to apply DNS configuration: $e');
      rethrow;
    }
  }

  Future<void> setCustomDns(String dnsServer) async {
    _currentDns = dnsServer;
    if (_currentDns != null) {
      await applyConfiguration();
    }
  }

  String? get currentDns => _currentDns;
  bool get isDnsEncrypted => _isDnsEncrypted;

  Future<void> enableDnsOverTls() async {
    _isDnsEncrypted = true;
    // Implement DNS-over-TLS configuration
  }

  Future<void> _setAndroidDns(String dnsServer) async {
    // Implementation would require platform-specific code
    // using MethodChannel to configure DNS
  }

  Future<void> _setIosDns(String dnsServer) async {
    // Implementation would require platform-specific code
    // using MethodChannel to configure DNS
  }
} 