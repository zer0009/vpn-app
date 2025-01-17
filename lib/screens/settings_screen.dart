import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/vpn_provider.dart';
import '../widgets/obfuscation_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<VpnProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Connection'),
              _buildSettingCard(
                title: 'Auto-Connect',
                subtitle: 'Connect VPN automatically on startup',
                trailing: Switch(
                  value: provider.autoConnect,
                  onChanged: (value) => provider.toggleAutoConnect(value),
                  activeColor: AppColors.primary,
                ),
              ),
              _buildSettingCard(
                title: 'Kill Switch',
                subtitle: 'Block internet when VPN disconnects',
                trailing: Switch(
                  value: provider.killSwitch,
                  onChanged: (value) => provider.toggleKillSwitch(value),
                  activeColor: AppColors.primary,
                ),
              ),
              
              _buildSectionHeader('Security'),
              const ObfuscationSettings(),
              _buildSettingCard(
                title: 'Split Tunneling',
                subtitle: 'Choose apps to bypass VPN',
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Split Tunneling coming soon')),
                  );
                },
              ),
              _buildSettingCard(
                title: 'DNS Settings',
                subtitle: 'Custom DNS configuration',
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('DNS Settings coming soon')),
                  );
                },
              ),

              _buildSectionHeader('Protocol'),
              _buildProtocolSelector(provider),

              _buildSectionHeader('Account'),
              _buildSettingCard(
                title: 'Profile',
                subtitle: 'Manage your account',
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile management coming soon')),
                  );
                },
              ),
              
              _buildSectionHeader('About'),
              _buildSettingCard(
                title: 'Version',
                subtitle: '1.0.0',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Latest',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textPrimary.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildProtocolSelector(VpnProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VPN Protocol',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildProtocolChip('UDP', provider),
              _buildProtocolChip('TCP', provider),
              _buildProtocolChip('IKEv2', provider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolChip(String protocol, VpnProvider provider) {
    final isSelected = provider.selectedProtocol == protocol;
    return FilterChip(
      selected: isSelected,
      label: Text(protocol),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      backgroundColor: AppColors.surface,
      onSelected: (bool selected) {
        if (selected) {
          provider.setProtocol(protocol);
        }
      },
    );
  }
} 