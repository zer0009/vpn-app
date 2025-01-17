import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TrafficStats {
  final int bytesIn;
  final int bytesOut;
  final DateTime timestamp;
  final double downloadSpeed;
  final double uploadSpeed;
  final Duration duration;
  final int ping;

  TrafficStats({
    required this.bytesIn,
    required this.bytesOut,
    this.downloadSpeed = 0.0,
    this.uploadSpeed = 0.0,
    this.duration = const Duration(),
    this.ping = 0,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();

  factory TrafficStats.fromData({
    required double downloadSpeed,
    required double uploadSpeed,
    required int bytesIn,
    required int bytesOut,
    required Duration duration,
    required int ping,
  }) {
    return TrafficStats(
      bytesIn: bytesIn,
      bytesOut: bytesOut,
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      duration: duration,
      ping: ping,
    );
  }
}

class TrafficMonitor {
  Timer? _timer;
  final _statsController = StreamController<TrafficStats>.broadcast();
  int _lastUpload = 0;
  int _lastDownload = 0;
  int _totalUpload = 0;
  int _totalDownload = 0;

  Stream<TrafficStats> get trafficStats => _statsController.stream;

  void startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTrafficStats();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _statsController.close();
  }

  Future<void> _updateTrafficStats() async {
    try {
      if (Platform.isLinux) {
        await _updateLinuxTrafficStats();
      } else if (Platform.isAndroid) {
        await _updateAndroidTrafficStats();
      } else if (Platform.isIOS) {
        await _updateIosTrafficStats();
      }
    } catch (e) {
      debugPrint('Error monitoring traffic: $e');
    }
  }

  Future<void> _updateLinuxTrafficStats() async {
    final proc = await Process.run('cat', ['/proc/net/dev']);
    final lines = proc.stdout.toString().split('\n');
    
    int currentUpload = 0;
    int currentDownload = 0;

    for (var line in lines) {
      if (line.contains('tun0')) {
        final parts = line.trim().split(RegExp(r'\s+'));
        currentDownload = int.parse(parts[1]);
        currentUpload = int.parse(parts[9]);
        break;
      }
    }

    final uploadSpeed = currentUpload - _lastUpload;
    final downloadSpeed = currentDownload - _lastDownload;

    _totalUpload += uploadSpeed;
    _totalDownload += downloadSpeed;

    _lastUpload = currentUpload;
    _lastDownload = currentDownload;

    _statsController.add(TrafficStats(
      bytesIn: _totalUpload,
      bytesOut: _totalDownload,
    ));
  }

  Future<void> _updateAndroidTrafficStats() async {
    const channel = MethodChannel('vpn_app/traffic_stats');
    try {
      final Map stats = await channel.invokeMethod('getTrafficStats');
      _updateStats(stats['upload'], stats['download']);
    } catch (e) {
      debugPrint('Error getting Android traffic stats: $e');
    }
  }

  Future<void> _updateIosTrafficStats() async {
    const channel = MethodChannel('vpn_app/traffic_stats');
    try {
      final Map stats = await channel.invokeMethod('getTrafficStats');
      _updateStats(stats['upload'], stats['download']);
    } catch (e) {
      debugPrint('Error getting iOS traffic stats: $e');
    }
  }

  void _updateStats(int upload, int download) {
    final uploadSpeed = upload - _lastUpload;
    final downloadSpeed = download - _lastDownload;

    _totalUpload += uploadSpeed;
    _totalDownload += downloadSpeed;

    _lastUpload = upload;
    _lastDownload = download;

    _statsController.add(TrafficStats(
      bytesIn: _totalUpload,
      bytesOut: _totalDownload,
    ));
  }
} 