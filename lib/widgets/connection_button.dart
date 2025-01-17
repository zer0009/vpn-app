import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'dart:math' as math;
import '../providers/vpn_provider.dart';
import '../constants/app_colors.dart';
import '../services/traffic_monitor.dart';

class ConnectionButton extends StatefulWidget {
  const ConnectionButton({Key? key}) : super(key: key);

  @override
  State<ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends State<ConnectionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, provider, _) {
        if ((provider.isConnecting || provider.isRecovering) && !_controller.isAnimating) {
          _controller.repeat();
        } else if (provider.isConnected) {
          _controller.repeat(period: const Duration(seconds: 3));
        } else if (provider.hasError) {
          _controller.stop();
          _controller.reset();
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.hasError && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Connection failed. Please try again or select a different server.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.resetError();
                          provider.toggleConnection();
                        },
                        child: const Text(
                          'RETRY',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red.withOpacity(0.8),
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        } else {
          _controller.stop();
          _controller.reset();
        }

        return GestureDetector(
          onTap: () {
            if (provider.isRecovering) {
              return;
            }
            
            if (provider.selectedServer == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connecting to fastest server...'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            provider.toggleConnection();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: provider.isConnecting || provider.isRecovering
                    ? _scaleAnimation.value
                    : provider.isConnected
                        ? _pulseAnimation.value
                        : provider.hasError
                            ? 0.95
                            : 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Enhanced outer glow
                    if (provider.isConnected)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getButtonColor(provider).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                    // Main button with enhanced gradient
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: provider.hasError
                              ? [
                                  Colors.red.withOpacity(0.7),
                                  Colors.red.withOpacity(0.5),
                                ]
                              : [
                                  _getGradientStartColor(provider),
                                  _getGradientEndColor(provider),
                                ],
                          stops: const [0.2, 0.8],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getButtonColor(provider).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: provider.isConnected ? 8 : 5,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 60,
                            spreadRadius: -10,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Enhanced glass effect
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.05),
                                ],
                                stops: const [0.1, 0.9],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Enhanced icon with glow effect
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getButtonColor(provider).withOpacity(0.3),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getButtonIcon(provider),
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      provider.isRecovering 
                                          ? 'Connecting...'
                                          : _getButtonText(provider),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Enhanced status indicator
                          if (provider.isConnected)
                            Positioned(
                              top: 30,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.connected,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.shield_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Protected',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Server Info when connecting
                          if (provider.isConnecting && provider.selectedServer != null)
                            Positioned(
                              bottom: -60,
                              child: Text(
                                'Connecting to ${provider.selectedServer!.country}...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          // Connection stages
                          if (provider.isConnecting)
                            LoadingIndicator(stage: provider.currentStage),

                          if (provider.isConnected)
                            const RippleAnimation(isActive: true),

                          if (provider.isConnected)
                            Positioned(
                              top: -40,
                              child: TrafficIndicator(stats: provider.currentTrafficStats),
                            ),

                          // Add error indicator
                          if (provider.hasError)
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getButtonText(VpnProvider provider) {
    if (provider.isConnecting) return 'Connecting...';
    if (provider.isConnected) return 'Connected';
    if (provider.hasError) return 'Connect';
    return 'Connect';
  }

  Color _getButtonColor(VpnProvider provider) {
    if (provider.hasError) return Colors.red;
    if (provider.isConnecting) {
      return AppColors.secondary;
    }
    return provider.isConnected ? AppColors.connected : AppColors.disconnected;
  }

  Color _getGradientStartColor(VpnProvider provider) {
    if (provider.isConnecting) {
      return AppColors.secondary.withOpacity(0.9);
    }
    return provider.isConnected 
        ? AppColors.connected.withOpacity(0.9)
        : AppColors.disconnected.withOpacity(0.9);
  }

  Color _getGradientEndColor(VpnProvider provider) {
    if (provider.isConnecting) {
      return AppColors.secondary.withOpacity(0.7);
    }
    return provider.isConnected
        ? AppColors.connected.withOpacity(0.7)
        : AppColors.disconnected.withOpacity(0.7);
  }

  IconData _getButtonIcon(VpnProvider provider) {
    return provider.isConnected
        ? Icons.power_settings_new_rounded
        : Icons.power_settings_new_outlined;
  }

  Widget _buildConnectionStatus(VpnProvider provider) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        provider.statusMessage,
        key: ValueKey(provider.statusMessage),
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStageIndicator(VPNStage stage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: VPNStage.values
          .where((s) => s != VPNStage.unknown)
          .map((s) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s == stage
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                ),
              ))
          .toList(),
    );
  }
}

class ConnectionStageIndicator extends StatelessWidget {
  final VPNStage stage;
  final String message;

  const ConnectionStageIndicator({
    Key? key,
    required this.stage,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(stage),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RippleAnimation extends StatelessWidget {
  final bool isActive;
  
  const RippleAnimation({
    Key? key,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isActive
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (index) {
                    return Transform.scale(
                      scale: 1 + (index + 1) * 0.2 * value,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.connected.withOpacity(
                              (1 - (index + 1) * 0.2 * value).clamp(0.0, 1.0),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
              onEnd: () {
                // Rebuild to create continuous animation
                if (isActive) {
                  (context as Element).markNeedsBuild();
                }
              },
            )
          : const SizedBox.shrink(),
    );
  }
}

class TrafficIndicator extends StatelessWidget {
  final TrafficStats? stats;
  
  const TrafficIndicator({
    Key? key,
    this.stats,
  }) : super(key: key);

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_upward_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            _formatSpeed(stats!.bytesOut),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_downward_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            _formatSpeed(stats!.bytesIn),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final VPNStage stage;
  
  const LoadingIndicator({
    Key? key,
    required this.stage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rotating dots
        RotatingDots(),
        
        // Inner progress ring
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: null,
            strokeWidth: 2,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.5),
            ),
          ),
        ),
        
        // Stage-specific animation
        _buildStageAnimation(stage),
      ],
    );
  }

  Widget _buildStageAnimation(VPNStage stage) {
    switch (stage) {
      case VPNStage.connecting:
        return const PulsingDots();
      case VPNStage.authenticating:
        return const AuthenticationAnimation();
      case VPNStage.get_config:
        return const ConfigurationAnimation();
      case VPNStage.assign_ip:
        return const ConfigurationAnimation();
      case VPNStage.connected:
        return const ConnectedAnimation();
      case VPNStage.disconnected:
        return const DisconnectedAnimation();
      case VPNStage.error:
        return const ErrorAnimation();
      default:
        return const PulsingDots();
    }
  }
}

class RotatingDots extends StatefulWidget {
  const RotatingDots({Key? key}) : super(key: key);

  @override
  State<RotatingDots> createState() => _RotatingDotsState();
}

class _RotatingDotsState extends State<RotatingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(8, (index) {
                final angle = (index / 8) * 2 * math.pi;
                final offset = Offset(
                  math.cos(angle) * 80,
                  math.sin(angle) * 80,
                );
                final opacity = (1 - (_controller.value - index / 8).abs())
                    .clamp(0.3, 1.0);

                return Positioned(
                  left: 90 + offset.dx - 4,
                  top: 90 + offset.dy - 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class PulsingDots extends StatefulWidget {
  const PulsingDots({Key? key}) : super(key: key);

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animation = Tween<double>(begin: 0.3, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(delay, delay + 0.4, curve: Curves.easeInOut),
              ),
            );

            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(animation.value),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class AuthenticationAnimation extends StatelessWidget {
  const AuthenticationAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock_outline,
        color: Colors.white.withOpacity(0.8),
        size: 20,
      ),
    );
  }
}

class ConfigurationAnimation extends StatelessWidget {
  const ConfigurationAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.settings,
        color: Colors.white.withOpacity(0.8),
        size: 20,
      ),
    );
  }
}

class IpAssignmentAnimation extends StatelessWidget {
  const IpAssignmentAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.wifi,
        color: Colors.white.withOpacity(0.8),
        size: 20,
      ),
    );
  }
}

class ConnectedAnimation extends StatelessWidget {
  const ConnectedAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_outline,
        color: Colors.white.withOpacity(0.8),
        size: 20,
      ),
    );
  }
}

class DisconnectedAnimation extends StatelessWidget {
  const DisconnectedAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.power_settings_new_outlined,
        color: Colors.white.withOpacity(0.8),
        size: 20,
      ),
    );
  }
}

class ErrorAnimation extends StatelessWidget {
  const ErrorAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.error_outline,
        color: Colors.red.withOpacity(0.8),
        size: 20,
      ),
    );
  }
} 