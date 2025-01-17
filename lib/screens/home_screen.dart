import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/traffic_stats_widget.dart';
import '../models/vpn_server.dart';
import 'server_list_screen.dart';
import '../widgets/connection_button.dart';
// import '../widgets/detailed_stats_panel.dart';
import '../widgets/animated_connection_state.dart';
import '../widgets/protocol_selector_widget.dart';
import '../widgets/connection_options.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(_backgroundController);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Enhanced animated background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(_backgroundAnimation.value),
                      math.sin(_backgroundAnimation.value),
                    ),
                    end: Alignment(
                      -math.cos(_backgroundAnimation.value),
                      -math.sin(_backgroundAnimation.value),
                    ),
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.secondary.withOpacity(0.15),
                      AppColors.accent2.withOpacity(0.1),
                    ],
                  ),
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.secondary.withOpacity(0.1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'VPN Shield',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildIconButton(
                icon: Icons.settings,
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<VpnProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(height: 40),
                  const ConnectionButton(),
                  const SizedBox(height: 40),
                  _buildConnectionOptions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServerCard(VpnProvider provider) {
    final server = provider.selectedServer;
    return Hero(
      tag: 'server_card',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServerListScreen()),
          ),
          child: Container(
            width: double.infinity,  // Make card full width
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface.withOpacity(0.5),
                  AppColors.surface.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildServerCardContent(server),
          ),
        ),
      ),
    );
  }

  Widget _buildServerCardContent(VpnServer? server) {
    return Column(
      children: [
        Row(
          children: [
            _buildServerFlag(server),
            const SizedBox(width: 20),
            Expanded(
              child: _buildServerInfo(server),
            ),
            _buildArrowButton(),
          ],
        ),
        if (server != null) ...[
          const SizedBox(height: 16),
          _buildPingIndicator(server),
        ],
      ],
    );
  }

  Widget _buildConnectionStatus(VpnProvider provider) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            provider.isConnected
                ? 'Your connection is secure'
                : 'Connect to protect your privacy',
            key: ValueKey(provider.isConnected),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ),
        if (provider.isConnecting)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 1.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                provider.statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildServerFlag(VpnServer? server) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 2,
        ),
        image: server != null
            ? DecorationImage(
                image: AssetImage(server.flag),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: server == null
          ? Icon(
              Icons.flag_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 24,
            )
          : null,
    );
  }

  Widget _buildServerInfo(VpnServer? server) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Server',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          server?.country ?? 'Choose Location',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (server != null) ...[
          const SizedBox(height: 4),
          Text(
            server.city,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArrowButton() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.keyboard_arrow_right_rounded,
        color: Colors.white.withOpacity(0.7),
        size: 24,
      ),
    );
  }

  Widget _buildPingIndicator(VpnServer server) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.signal_cellular_alt_rounded,
            size: 16,
            color: AppColors.accent2,
          ),
          const SizedBox(width: 8),
          Text(
            'Ping: ${server.ping} ms',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildProtocolSelector(VpnProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withOpacity(0.4),
            AppColors.surface.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protocol',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: VpnProtocolType.values.map((protocol) {
                final isSelected = provider.currentProtocol == protocol;
                return GestureDetector(
                  onTap: () => provider.changeProtocol(protocol),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent2.withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent2
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      protocol.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accent2
                            : Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionOptions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          ConnectionOption(
            icon: Icons.language_rounded,
            title: 'Free VPN',
            subtitle: 'Choose from available servers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServerListScreen()),
            ),
          ),
          ConnectionOption(
            icon: Icons.auto_awesome_rounded,
            title: 'Smart Location',
            subtitle: 'Auto-select best protocol',
            onTap: () => _showProtocolSelector(),
            showBorder: false,
          ),
        ],
      ),
    );
  }

  void _showProtocolSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProtocolSelectorWidget(),
    );
  }
} 