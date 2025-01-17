import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart' as openvpn_flutter;

///To store datas of VPN Connection's status detail
class VpnStatus {
  static const connected = VpnStatus._internal('CONNECTED');
  static const connecting = VpnStatus._internal('CONNECTING');
  static const disconnected = VpnStatus._internal('DISCONNECTED');
  static const disconnecting = VpnStatus._internal('DISCONNECTING');
  static const error = VpnStatus._internal('ERROR');

  final String status;
  final DateTime? connectedOn;
  final String? duration;
  final String? byteIn;
  final String? byteOut;
  final String? packetsIn;
  final String? packetsOut;

  const VpnStatus._internal(this.status, {
    this.connectedOn,
    this.duration,
    this.byteIn,
    this.byteOut,
    this.packetsIn,
    this.packetsOut,
  });

  VpnStatus({
    this.connectedOn,
    this.duration,
    this.byteIn,
    this.byteOut,
    this.packetsIn,
    this.packetsOut,
  }) : status = 'UNKNOWN';

  /// VPNStatus as empty data
  factory VpnStatus.empty() => VpnStatus(
        duration: "00:00:00",
        connectedOn: null,
        byteIn: "0",
        byteOut: "0",
        packetsIn: "0",
        packetsOut: "0",
      );

  ///Convert to JSON
  Map<String, dynamic> toJson() => {
        "status": status,
        "connected_on": connectedOn,
        "duration": duration,
        "byte_in": byteIn,
        "byte_out": byteOut,
        "packets_in": packetsIn,
        "packets_out": packetsOut,
      };

  @override
  String toString() => toJson().toString();
}

class VpnService {
  late OpenVPN _openVPN;
  late VpnStatus _status;
  final StreamController<VpnStatus> _statusController = StreamController<VpnStatus>.broadcast();
  final StreamController<VpnStats> _statsController = StreamController<VpnStats>.broadcast();

  Stream<VpnStatus> get statusStream => _statusController.stream;
  Stream<VpnStats> get statsStream => _statsController.stream;
  VpnStatus get status => _status;

  VpnService() {
    _status = VpnStatus.disconnected;
    _initializeVpn();
  }

  Future<void> _initializeVpn() async {
    try {
      _openVPN = OpenVPN(
        onVpnStatusChanged: _convertAndHandleStatus,
        onVpnStageChanged: (VPNStage stage, String message) {
          _handleStageChange(stage, message);
        },
      );
      
      if (Platform.isAndroid) {
        await _openVPN.initialize(
          groupIdentifier: "group.com.example.vpnApp",
          providerBundleIdentifier: "com.example.vpnApp.VPNExtension",
          localizedDescription: "VPN Connection",
        );
      }
    } catch (e) {
      debugPrint('VPN initialization error: $e');
      rethrow;
    }
  }

  VpnStatus _convertAndHandleStatus(openvpn_flutter.VpnStatus? status) {
    if (status == null) {
      return VpnStatus.disconnected;
    }

    final VpnStatus convertedStatus;
    switch (status.connectedOn) {
      case 'CONNECTED':
        convertedStatus = VpnStatus._internal('CONNECTED',
          duration: status.duration,
          byteIn: status.byteIn,
          byteOut: status.byteOut,
          packetsIn: status.packetsIn,
          packetsOut: status.packetsOut,
          connectedOn: DateTime.now(),
        );
        break;
      case 'CONNECTING':
        convertedStatus = VpnStatus.connecting;
        break;
      case 'DISCONNECTED':
        convertedStatus = VpnStatus.disconnected;
        break;
      case 'DISCONNECTING':
        convertedStatus = VpnStatus.disconnecting;
        break;
      default:
        convertedStatus = VpnStatus.error;
    }

    _handleStatusChange(convertedStatus);
    return convertedStatus;
  }

  Future<void> connect(String config) async {
    try {
      if (_status == VpnStatus.connected) {
        await disconnect();
      }

      if (Platform.isAndroid) {
        _openVPN.connect(
          config,
          "VPN Connection",
          username: "vpnUser",
          password: "vpnPass",
        );
      } else {
        _openVPN.connect(
          config,
          "VPN Connection",
        );
      }

      _status = VpnStatus.connecting;
      _statusController.add(_status);
    } catch (e) {
      debugPrint('VPN connection error: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      _openVPN.disconnect();
      _status = VpnStatus.disconnected;
      _statusController.add(_status);
    } catch (e) {
      debugPrint('VPN disconnection error: $e');
      rethrow;
    }
  }

  void _handleStatusChange(VpnStatus vpnStatus) {
    _status = vpnStatus;
    _statusController.add(_status);
  }

  void _handleStageChange(VPNStage stage, String message) {
    final stats = VpnStats.fromStage(stage.toString(), message);
    _statsController.add(stats);
  }

  Future<void> dispose() async {
    await _statusController.close();
    await _statsController.close();
  }
}

class VpnStats {
  final double bytesIn;
  final double bytesOut;
  final Duration duration;
  final String lastMessage;

  VpnStats({
    required this.bytesIn,
    required this.bytesOut,
    required this.duration,
    required this.lastMessage,
  });

  factory VpnStats.fromStage(String stage, String message) {
    try {
      final Map<String, String> stats = {};
      final parts = message.split(' ');
      
      for (final part in parts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          stats[keyValue[0]] = keyValue[1];
        }
      }

      return VpnStats(
        bytesIn: double.tryParse(stats['bytes_received'] ?? '0') ?? 0,
        bytesOut: double.tryParse(stats['bytes_sent'] ?? '0') ?? 0,
        duration: Duration(seconds: int.tryParse(stats['duration'] ?? '0') ?? 0),
        lastMessage: message,
      );
    } catch (e) {
      debugPrint('Error parsing VPN stats: $e');
      return VpnStats(
        bytesIn: 0,
        bytesOut: 0,
        duration: Duration.zero,
        lastMessage: message,
      );
    }
  }

  @override
  String toString() {
    return 'VpnStats(in: ${(bytesIn / 1024 / 1024).toStringAsFixed(2)} MB, '
           'out: ${(bytesOut / 1024 / 1024).toStringAsFixed(2)} MB, '
           'duration: ${duration.inMinutes}m)';
  }
} 