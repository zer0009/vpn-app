import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dart:math' as math;

class AnimatedConnectionState extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const AnimatedConnectionState({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  });

  @override
  State<AnimatedConnectionState> createState() => _AnimatedConnectionStateState();
}

class _AnimatedConnectionStateState extends State<AnimatedConnectionState>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isConnecting) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedConnectionState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnecting != oldWidget.isConnecting) {
      if (widget.isConnecting) {
        _rotationController.repeat();
        _pulseController.repeat(reverse: true);
      } else {
        _rotationController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isConnecting ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isConnected
                    ? AppColors.accent2.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: widget.isConnected
                      ? AppColors.accent2
                      : Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.isConnecting)
                    Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(100, 100),
                        painter: LoadingArcPainter(),
                      ),
                    ),
                  Icon(
                    widget.isConnected
                        ? Icons.power_settings_new
                        : Icons.power_settings_new_outlined,
                    size: 40,
                    color: widget.isConnected
                        ? AppColors.accent2
                        : Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LoadingArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent2
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    canvas.drawArc(
      rect,
      0,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 