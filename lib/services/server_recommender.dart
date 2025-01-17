import '../models/vpn_server.dart';

class ServerRecommender {
  static const int EXCELLENT_PING = 50;
  static const int GOOD_PING = 100;
  static const double MIN_LOAD = 0.7;

  static List<VpnServer> getRecommendedServers(
    List<VpnServer> servers, {
    bool isStreaming = false,
    bool isGaming = false,
    bool isPrivacyFocus = false,
  }) {
    // Create a copy of the list to avoid modifying the original
    final List<VpnServer> sortedServers = List.from(servers);

    // Calculate server scores
    final scores = Map<VpnServer, double>.fromIterable(
      sortedServers,
      key: (server) => server,
      value: (server) => _calculateServerScore(
        server,
        isStreaming: isStreaming,
        isGaming: isGaming,
        isPrivacyFocus: isPrivacyFocus,
      ),
    );

    // Sort servers by score
    sortedServers.sort((a, b) => scores[b]!.compareTo(scores[a]!));

    return sortedServers;
  }

  static double _calculateServerScore(
    VpnServer server, {
    bool isStreaming = false,
    bool isGaming = false,
    bool isPrivacyFocus = false,
  }) {
    double score = 0;

    // Base score from ping
    if (server.ping <= EXCELLENT_PING) {
      score += 100;
    } else if (server.ping <= GOOD_PING) {
      score += 80;
    } else {
      score += 50;
    }

    // Adjust for server load
    score *= (1 - server.load);

    // Specific use case adjustments
    if (isStreaming) {
      score *= server.bandwidth > 100 ? 1.3 : 0.7;
    }

    if (isGaming) {
      score *= server.ping < 50 ? 1.5 : 0.6;
    }

    if (isPrivacyFocus) {
      score *= server.hasDoubleVPN ? 1.4 : 0.8;
    }

    return score;
  }

  static String getRecommendationReason(VpnServer server) {
    if (server.ping <= EXCELLENT_PING) {
      return 'Excellent ping for gaming';
    } else if (server.bandwidth > 100) {
      return 'High bandwidth for streaming';
    } else if (server.hasDoubleVPN) {
      return 'Enhanced privacy with Double VPN';
    } else if (server.load < MIN_LOAD) {
      return 'Low server load for better performance';
    }
    return 'Balanced performance';
  }
} 