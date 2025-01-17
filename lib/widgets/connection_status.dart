import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, vpnProvider, child) {
        String statusText = 'Disconnected';
        if (vpnProvider.isConnecting) {
          statusText = 'Connecting...';
        } else if (vpnProvider.isConnected) {
          statusText = 'Connected';
        }
        return Text(statusText);
      },
    );
  }
} 