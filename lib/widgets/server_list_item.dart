import 'package:flutter/material.dart';
import '../models/vpn_server.dart';
import '../constants/app_colors.dart';

class ServerListItem extends StatelessWidget {
  final VpnServer server;
  final VoidCallback onTap;
  final bool isRecommended;

  const ServerListItem({
    super.key,
    required this.server,
    required this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withOpacity(0.5),
            AppColors.surface.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFlag(),
                const SizedBox(width: 16),
                Expanded(child: _buildServerInfo()),
                _buildServerStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlag() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(server.flag),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildServerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              server.country,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (isRecommended) ...[
              const SizedBox(width: 8),
              _buildRecommendedBadge(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          server.city,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildServerStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPingBadge(),
        const SizedBox(height: 4),
        _buildLoadIndicator(),
      ],
    );
  }

  Widget _buildPingBadge() {
    final (color, label) = switch (server.ping) {
      < 50 => (Colors.green, 'Excellent'),
      < 100 => (Colors.lime, 'Good'),
      < 200 => (Colors.orange, 'Fair'),
      _ => (Colors.red, 'Poor'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.signal_cellular_alt_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${server.ping} ms',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadIndicator() {
    return Text(
      'Load: ${(server.load * 100).toInt()}%',
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
      ),
    );
  }

  Widget _buildRecommendedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent2.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'RECOMMENDED',
        style: TextStyle(
          color: AppColors.accent2,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 