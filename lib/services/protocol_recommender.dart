import '../providers/vpn_provider.dart';

class ProtocolRecommender {
  static VpnProtocolType recommendProtocol({
    required bool isStreaming,
    required bool isGaming,
    required bool isSecurityPriority,
    required int currentPing,
  }) {
    if (isGaming && currentPing > 100) {
      return VpnProtocolType.udp; // Lowest latency for gaming
    }
    
    if (isStreaming && currentPing < 150) {
      return VpnProtocolType.tlsV2; // Balance of speed and security
    }
    
    if (isSecurityPriority) {
      return VpnProtocolType.tlsV3; // Maximum security
    }
    
    // Default recommendation based on ping
    if (currentPing < 50) {
      return VpnProtocolType.tlsV2;
    } else if (currentPing < 100) {
      return VpnProtocolType.tcp;
    } else {
      return VpnProtocolType.udp;
    }
  }

  static String getRecommendationReason(VpnProtocolType protocol) {
    switch (protocol) {
      case VpnProtocolType.udp:
        return 'Recommended for gaming and low latency';
      case VpnProtocolType.tcp:
        return 'Best for stable connections';
      case VpnProtocolType.tlsV2:
        return 'Balanced security and performance';
      case VpnProtocolType.tlsV3:
        return 'Maximum security and privacy';
      default:
        return 'General purpose protocol';
    }
  }
} 