import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../services/traffic_monitor.dart';
import '../constants/app_colors.dart';

class TrafficStatsWidget extends StatelessWidget {
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, vpnProvider, child) {
        final TrafficStats? stats = vpnProvider.currentTrafficStats;
        if (!vpnProvider.isConnected || stats == null) {
          return const Text('No traffic data available');
        }
        
        return Column(
          children: [
            Text('Download: ${_formatBytes(stats.bytesIn)}'),
            Text('Upload: ${_formatBytes(stats.bytesOut)}'),
          ],
        );
      },
    );
  }
} 