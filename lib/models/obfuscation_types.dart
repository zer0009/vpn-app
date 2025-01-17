enum ObfuscationType {
  none,
  http,
  tls,
  shadowsocks,
  xor,
  stunnel,
  websocket
}

class ObfuscationConfig {
  final ObfuscationType type;
  final String domain;
  final Map<String, dynamic> additionalParams;
  final bool isEnabled;

  ObfuscationConfig({
    required this.type,
    required this.domain,
    required this.isEnabled,
    this.additionalParams = const {},
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'domain': domain,
    'isEnabled': isEnabled,
    'additionalParams': additionalParams,
  };

  factory ObfuscationConfig.fromJson(Map<String, dynamic> json) {
    return ObfuscationConfig(
      type: ObfuscationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ObfuscationType.none,
      ),
      domain: json['domain'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      additionalParams: json['additionalParams'] ?? {},
    );
  }
} 