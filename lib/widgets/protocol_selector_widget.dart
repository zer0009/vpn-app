import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/vpn_provider.dart';
import 'package:provider/provider.dart';

class ProtocolSelectorWidget extends StatelessWidget {
  const ProtocolSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildTitle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildProtocolList(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            'Select Protocol',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolList(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.protocolDetails.length,
            itemBuilder: (context, index) {
              final protocol = VpnProtocolType.values[index];
              final details = provider.protocolDetails[protocol]!;
              final isSelected = provider.currentProtocol == protocol;

              return ListTile(
                onTap: () {
                  provider.changeProtocol(protocol);
                  Navigator.pop(context);
                },
                leading: Icon(
                  _getProtocolIcon(protocol),
                  color: isSelected ? AppColors.accent2 : Colors.white,
                ),
                title: Text(
                  protocol.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? AppColors.accent2 : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  details,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.accent2,
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  IconData _getProtocolIcon(VpnProtocolType protocol) {
    switch (protocol) {
      case VpnProtocolType.udp:
        return Icons.speed_rounded;
      case VpnProtocolType.tcp:
        return Icons.security_rounded;
      case VpnProtocolType.tlsV1:
      case VpnProtocolType.tlsV2:
      case VpnProtocolType.tlsV3:
        return Icons.enhanced_encryption_rounded;
      case VpnProtocolType.http:
      case VpnProtocolType.http2:
      case VpnProtocolType.http3:
        return Icons.public_rounded;
    }
  }
} 