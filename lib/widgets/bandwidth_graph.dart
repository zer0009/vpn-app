import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';

class BandwidthGraph extends StatelessWidget {
  final List<double> downloadSpeeds;
  final List<double> uploadSpeeds;
  final double maxSpeed;
  final Duration duration;

  const BandwidthGraph({
    super.key,
    required this.downloadSpeeds,
    required this.uploadSpeeds,
    required this.maxSpeed,
    this.duration = const Duration(minutes: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bandwidth Usage',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: BandwidthGraphPainter(
                downloadSpeeds: downloadSpeeds,
                uploadSpeeds: uploadSpeeds,
                maxSpeed: maxSpeed,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Download', Colors.green),
              const SizedBox(width: 24),
              _buildLegendItem('Upload', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class BandwidthGraphPainter extends CustomPainter {
  final List<double> downloadSpeeds;
  final List<double> uploadSpeeds;
  final double maxSpeed;

  BandwidthGraphPainter({
    required this.downloadSpeeds,
    required this.uploadSpeeds,
    required this.maxSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final downloadPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height),
        Offset(0, 0),
        [
          Colors.green.withOpacity(0.1),
          Colors.green.withOpacity(0.3),
        ],
      )
      ..style = PaintingStyle.fill;

    final uploadPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height),
        Offset(0, 0),
        [
          Colors.blue.withOpacity(0.1),
          Colors.blue.withOpacity(0.3),
        ],
      )
      ..style = PaintingStyle.fill;

    final downloadLinePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final uploadLinePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawGraph(
      canvas,
      size,
      downloadSpeeds,
      downloadPaint,
      downloadLinePaint,
    );

    _drawGraph(
      canvas,
      size,
      uploadSpeeds,
      uploadPaint,
      uploadLinePaint,
    );

    _drawGridLines(canvas, size);
  }

  void _drawGraph(
    Canvas canvas,
    Size size,
    List<double> speeds,
    Paint fillPaint,
    Paint linePaint,
  ) {
    if (speeds.isEmpty) return;

    final path = Path();
    final linePath = Path();

    final width = size.width;
    final height = size.height;
    final stepX = width / (speeds.length - 1);

    path.moveTo(0, height);
    linePath.moveTo(0, height - (speeds[0] / maxSpeed * height));

    for (var i = 0; i < speeds.length; i++) {
      final x = stepX * i;
      final y = height - (speeds[i] / maxSpeed * height);
      
      if (i == 0) {
        path.moveTo(x, height);
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      linePath.lineTo(x, y);
    }

    path.lineTo(width, height);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
      
      // Draw speed labels
      final speed = (maxSpeed * (4 - i) / 4).toStringAsFixed(1);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$speed MB/s',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas,
        Offset(-35, y - 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 