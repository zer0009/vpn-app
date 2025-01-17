import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/obfuscation_types.dart';

class ServerCompatibilityChecker {
  Future<Map<ObfuscationType, bool>> checkServerCompatibility(String serverAddress) async {
    try {
      // Initialize with default values
      Map<ObfuscationType, bool> compatibility = {
        ObfuscationType.none: true,
        ObfuscationType.http: false,
        ObfuscationType.tls: false,
        ObfuscationType.shadowsocks: false,
        ObfuscationType.stunnel: false,
        ObfuscationType.websocket: false,
        ObfuscationType.xor: false,
      };

      // Check HTTP/HTTPS availability
      final httpResult = await _checkHttpSupport(serverAddress);
      compatibility[ObfuscationType.http] = httpResult;

      // Check TLS support
      final tlsResult = await _checkTlsSupport(serverAddress);
      compatibility[ObfuscationType.tls] = tlsResult;

      // Check WebSocket support
      final wsResult = await _checkWebSocketSupport(serverAddress);
      compatibility[ObfuscationType.websocket] = wsResult;

      // Check Shadowsocks support
      final ssResult = await _checkShadowsocksSupport(serverAddress);
      compatibility[ObfuscationType.shadowsocks] = ssResult;

      // Check STunnel support
      final stunnelResult = await _checkStunnelSupport(serverAddress);
      compatibility[ObfuscationType.stunnel] = stunnelResult;

      // Check XOR support
      final xorResult = await _checkXorSupport(serverAddress);
      compatibility[ObfuscationType.xor] = xorResult;

      return compatibility;
    } catch (e) {
      print('Error checking server compatibility: $e');
      // Return default compatibility map with only ObfuscationType.none as true
      return {
        ObfuscationType.none: true,
        ObfuscationType.http: false,
        ObfuscationType.tls: false,
        ObfuscationType.shadowsocks: false,
        ObfuscationType.stunnel: false,
        ObfuscationType.websocket: false,
        ObfuscationType.xor: false,
      };
    }
  }

  Future<bool> _checkHttpSupport(String serverAddress) async {
    try {
      final response = await http.get(
        Uri.parse('http://$serverAddress'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 403;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkTlsSupport(String serverAddress) async {
    try {
      final response = await http.get(
        Uri.parse('https://$serverAddress'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 403;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkWebSocketSupport(String serverAddress) async {
    try {
      final response = await http.get(
        Uri.parse('http://$serverAddress'),
        headers: {
          'Upgrade': 'websocket',
          'Connection': 'Upgrade',
        },
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 101 || response.statusCode == 400;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkShadowsocksSupport(String serverAddress) async {
    try {
      // Test common Shadowsocks port
      final socket = await Socket.connect(serverAddress, 8388)
          .timeout(const Duration(seconds: 5));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkStunnelSupport(String serverAddress) async {
    try {
      // Test common STunnel port
      final socket = await Socket.connect(serverAddress, 443)
          .timeout(const Duration(seconds: 5));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkXorSupport(String serverAddress) async {
    // XOR obfuscation is typically supported if the server is running OpenVPN
    // This is a simplified check - you might want to implement more specific testing
    try {
      final socket = await Socket.connect(serverAddress, 1194)
          .timeout(const Duration(seconds: 5));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
} 