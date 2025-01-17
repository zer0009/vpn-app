import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ConnectionQualityWidget extends StatelessWidget {
  final int ping;
  final bool isConnected;

  const ConnectionQualityWidget({
    super.key,
    required this.ping,
    required this.isConnected,
  });

  String get qualityText {
    if (!isConnected) return 'Not Connected';
    if (ping < 50) return 'Excellent';
    if (ping < 100) return 'Good';
    if (ping < 150) return 'Fair';
    return 'Poor';
  }

  Color get qualityColor {
    if (!isConnected) return Colors.grey;
    if (ping < 50) return Colors.green;
    if (ping < 100) return Colors.lightGreen;
    if (ping < 150) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: qualityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qualityColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_tethering,
            color: qualityColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            qualityText,
            style: TextStyle(
              color: qualityColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isConnected) ...[
            const SizedBox(width: 8),
            Text(
              '$ping ms',
              style: TextStyle(
                color: qualityColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 