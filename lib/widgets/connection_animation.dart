import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ConnectionAnimation extends StatefulWidget {
  final bool isConnected;
  final double size;

  const ConnectionAnimation({
    super.key,
    required this.isConnected,
    this.size = 180,
  });

  @override
  State<ConnectionAnimation> createState() => _ConnectionAnimationState();
}

class _ConnectionAnimationState extends State<ConnectionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isConnected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ConnectionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isConnected
                        ? AppColors.connected
                        : AppColors.disconnected,
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.isConnected
                  ? [AppColors.connected, AppColors.connected.withOpacity(0.7)]
                  : [AppColors.disconnected, AppColors.disconnected.withOpacity(0.7)],
            ),
          ),
          child: Icon(
            widget.isConnected ? Icons.power_settings_new : Icons.power_off,
            size: widget.size * 0.4,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
} 