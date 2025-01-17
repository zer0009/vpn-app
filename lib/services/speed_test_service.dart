import 'dart:async';
import 'dart:io';
import 'dart:math' show max;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SpeedTestService {
  static const String _speedTestUrl = 'https://speedtest.net/api/js/servers';
  static const int _downloadSize = 25000000; // 25MB
  static const Duration _timeout = Duration(seconds: 30);

  Future<SpeedTestResult> measureSpeed() async {
    try {
      final startTime = DateTime.now();
      
      // Download test
      final downloadSpeed = await _measureDownloadSpeed();
      
      // Upload test
      final uploadSpeed = await _measureUploadSpeed();
      
      // Latency test
      final latency = await measureLatency();

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      return SpeedTestResult(
        downloadSpeed: downloadSpeed,
        uploadSpeed: uploadSpeed,
        latency: latency,
        testDuration: duration,
      );
    } catch (e) {
      debugPrint('Speed test error: $e');
      rethrow;
    }
  }

  Future<double> _measureDownloadSpeed() async {
    try {
      final client = http.Client();
      final stopwatch = Stopwatch()..start();
      
      final response = await client.get(
        Uri.parse('https://speedtest.net/api/js/download?size=$_downloadSize'),
      ).timeout(_timeout);

      stopwatch.stop();
      client.close();

      if (response.statusCode == 200) {
        // Calculate speed in Mbps
        final duration = stopwatch.elapsedMilliseconds / 1000; // Convert to seconds
        final size = response.bodyBytes.length;
        return (size * 8 / duration) / 1000000; // Convert to Mbps
      } else {
        throw Exception('Download test failed');
      }
    } catch (e) {
      debugPrint('Download speed test error: $e');
      return 0.0;
    }
  }

  Future<double> _measureUploadSpeed() async {
    try {
      final client = http.Client();
      final data = List.generate(1024 * 1024, (index) => 0); // 1MB of data
      final stopwatch = Stopwatch()..start();

      final response = await client.post(
        Uri.parse('https://speedtest.net/api/js/upload'),
        body: data,
      ).timeout(_timeout);

      stopwatch.stop();
      client.close();

      if (response.statusCode == 200) {
        final duration = stopwatch.elapsedMilliseconds / 1000;
        final size = data.length;
        return (size * 8 / duration) / 1000000; // Convert to Mbps
      } else {
        throw Exception('Upload test failed');
      }
    } catch (e) {
      debugPrint('Upload speed test error: $e');
      return 0.0;
    }
  }

  Future<int> measureLatency() async {
    try {
      final List<int> latencies = [];
      const pingCount = 4;

      for (var i = 0; i < pingCount; i++) {
        final stopwatch = Stopwatch()..start();
        
        final socket = await Socket.connect(
          'speedtest.net',
          80,
          timeout: const Duration(seconds: 2),
        );
        
        stopwatch.stop();
        await socket.close();
        
        latencies.add(stopwatch.elapsedMilliseconds);
      }

      // Remove highest value and calculate average
      latencies.remove(latencies.reduce(max));
      return latencies.reduce((a, b) => a + b) ~/ latencies.length;
    } catch (e) {
      debugPrint('Latency test error: $e');
      return 999;
    }
  }
}

class SpeedTestResult {
  final double downloadSpeed;
  final double uploadSpeed;
  final int latency;
  final Duration testDuration;

  SpeedTestResult({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.latency,
    required this.testDuration,
  });

  @override
  String toString() {
    return 'SpeedTestResult(download: ${downloadSpeed.toStringAsFixed(2)} Mbps, '
           'upload: ${uploadSpeed.toStringAsFixed(2)} Mbps, '
           'latency: ${latency}ms, '
           'duration: ${testDuration.inSeconds}s)';
  }
}