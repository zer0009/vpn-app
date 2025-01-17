import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dart:ui';

class DetailedStatsPanel extends StatelessWidget {
  final int uploadSpeed;
  final int downloadSpeed;
  final int ping;
  final String duration;
  final String dataUsed;
  final String protocol;

  const DetailedStatsPanel({
    super.key,
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.ping,
    required this.duration,
    required this.dataUsed,
    required this.protocol,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.download,
                    title: 'Download',
                    value: '${downloadSpeed}MB/s',
                    color: Colors.green,
                    flex: 1,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.upload,
                    title: 'Upload',
                    value: '${uploadSpeed}MB/s',
                    color: Colors.blue,
                    flex: 1,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.speed,
                    title: 'Ping',
                    value: '${ping}ms',
                    color: Colors.orange,
                    flex: 1,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.data_usage,
                    title: 'Data Used',
                    value: dataUsed,
                    color: Colors.purple,
                    flex: 1,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.timer,
                    title: 'Duration',
                    value: duration,
                    color: Colors.teal,
                    flex: 1,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.security,
                    title: 'Protocol',
                    value: protocol,
                    color: AppColors.accent2,
                    flex: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 