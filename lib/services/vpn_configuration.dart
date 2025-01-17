import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/vpn_server.dart';
import '../models/vpn_stage.dart';

typedef VpnStateCallback = void Function(VPNStage stage, String message);

class VpnConfiguration {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  
  bool _killSwitchEnabled = false;
  String? _lastKnownDns;
  
  Future<void> enableKillSwitch() async {
    try {
      _killSwitchEnabled = true;
      debugPrint('Kill switch enabled');
    } catch (e) {
      debugPrint('Error enabling kill switch: $e');
      rethrow;
    }
  }

  Future<void> disableKillSwitch() async {
    try {
      _killSwitchEnabled = false;
      debugPrint('Kill switch disabled');
    } catch (e) {
      debugPrint('Error disabling kill switch: $e');
      rethrow;
    }
  }

  bool get isKillSwitchEnabled => _killSwitchEnabled;

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    if (!_killSwitchEnabled) return;

    if (result != ConnectivityResult.none) {
      final currentDns = await _networkInfo.getWifiGatewayIP();
      if (currentDns != _lastKnownDns) {
        // DNS leak detected, disconnect internet
        await _emergencyDisconnect();
      }
    }
  }

  Future<void> _emergencyDisconnect() async {
    const channel = MethodChannel('vpn_app/network_control');
    
    try {
      if (Platform.isAndroid) {
        await channel.invokeMethod('blockNetwork');
      } else if (Platform.isIOS) {
        await channel.invokeMethod('enforceVpnConnection');
      }
      
      // Notify the VPN provider to disconnect
      // This would require passing a callback or using a service locator
      debugPrint('Emergency disconnect triggered');
    } catch (e) {
      debugPrint('Emergency disconnect failed: $e');
    }
  }

  Future<bool> validateConfiguration(VpnServer server) async {
    try {
      // Check if server configuration is not empty
      if (server.ovpnConfiguration.isEmpty) {
        return false;
      }

      // Validate IP address format
      if (!_isValidIpAddress(server.ip)) {
        return false;
      }

      // Validate OpenVPN configuration format
      if (!_isValidOvpnConfig(server.ovpnConfiguration)) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Configuration validation error: $e');
      return false;
    }
  }

  bool _isValidIpAddress(String ip) {
    try {
      return RegExp(
        r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      ).hasMatch(ip);
    } catch (e) {
      return false;
    }
  }

  bool _isValidOvpnConfig(String config) {
    // Basic OpenVPN configuration validation
    // Check for essential OpenVPN directives
    return config.contains('client') &&
        (config.contains('remote ') || config.contains('remote-random')) &&
        (config.contains('dev tun') || config.contains('dev tap'));
  }
} 