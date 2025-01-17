import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/obfuscation_types.dart';

class ServerCompatibilityChecker {
  static const int _testTimeout = 5; // seconds
  static const Map<ObfuscationType, List<int>> _defaultPorts = {
    ObfuscationType.shadowsocks: [8388, 8389, 443],
    ObfuscationType.stunnel: [443, 993],
    ObfuscationType.websocket: [80, 443, 8080],
    ObfuscationType.http: [80, 8080],
    ObfuscationType.tls: [443, 8443],
    ObfuscationType.xor: [443, 8443],
  };

  Future<Map<ObfuscationType, bool>> checkServerCompatibility(String serverAddress) async {
    Map<ObfuscationType, bool> results = {};
    
    for (var type in ObfuscationType.values) {
      if (type == ObfuscationType.none) {
        results[type] = true;
        continue;
      }
      
      try {
        results[type] = await _testObfuscationType(serverAddress, type);
      } catch (e) {
        debugPrint('Error testing $type: $e');
        results[type] = false;
      }
    }
    
    return results;
  }

  Future<bool> _testObfuscationType(String serverAddress, ObfuscationType type) async {
    List<int> portsToTest = _defaultPorts[type] ?? [443];
    List<Future<bool>> tests = [];

    for (int port in portsToTest) {
      tests.add(_testConnection(serverAddress, port, type));
    }

    try {
      final results = await Future.wait(tests);
      return results.any((success) => success);
    } catch (e) {
      debugPrint('Connection test failed for $type: $e');
      return false;
    }
  }

  Future<bool> _testConnection(String serverAddress, int port, ObfuscationType type) async {
    try {
      switch (type) {
        case ObfuscationType.shadowsocks:
          return await _testShadowsocksPort(serverAddress, port);
        case ObfuscationType.stunnel:
          return await _testStunnelPort(serverAddress, port);
        case ObfuscationType.websocket:
          return await _testWebSocketPort(serverAddress, port);
        case ObfuscationType.http:
          return await _testHttpPort(serverAddress, port);
        case ObfuscationType.tls:
          return await _testTlsPort(serverAddress, port);
        case ObfuscationType.xor:
          return await _testXorPort(serverAddress, port);
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Port test failed for $type:$port - $e');
      return false;
    }
  }

  Future<bool> _testShadowsocksPort(String address, int port) async {
    try {
      final socket = await Socket.connect(
        address,
        port,
        timeout: const Duration(seconds: _testTimeout),
      );
      
      // Send Shadowsocks handshake
      final handshake = [0x03, 0x00, 0x00];
      socket.add(handshake);
      
      final response = await socket.first.timeout(
        const Duration(seconds: _testTimeout),
      );
      
      await socket.close();
      return response.length > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testStunnelPort(String address, int port) async {
    try {
      final socket = await SecureSocket.connect(
        address,
        port,
        timeout: const Duration(seconds: _testTimeout),
        onBadCertificate: (_) => true,
      );
      
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testWebSocketPort(String address, int port) async {
    try {
      final uri = Uri.parse('ws://$address:$port');
      final webSocket = await WebSocket.connect(
        uri.toString(),
        headers: {
          'Upgrade': 'websocket',
          'Connection': 'Upgrade',
        },
      ).timeout(const Duration(seconds: _testTimeout));
      
      await webSocket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testHttpPort(String address, int port) async {
    try {
      final uri = Uri.parse('http://$address:$port');
      final response = await HttpClient().getUrl(uri)
          .timeout(const Duration(seconds: _testTimeout))
          .then((request) => request.close());
      
      await response.drain();
      return response.statusCode == 101 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testTlsPort(String address, int port) async {
    try {
      final socket = await SecureSocket.connect(
        address,
        port,
        timeout: const Duration(seconds: _testTimeout),
        onBadCertificate: (_) => true,
      );
      
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testXorPort(String address, int port) async {
    try {
      final socket = await Socket.connect(
        address,
        port,
        timeout: const Duration(seconds: _testTimeout),
      );
      
      // Send XOR probe
      final probe = [0xFF, 0x00, 0xFF];
      socket.add(probe);
      
      final response = await socket.first.timeout(
        const Duration(seconds: _testTimeout),
      );
      
      await socket.close();
      return response.length > 0;
    } catch (e) {
      return false;
    }
  }
} 