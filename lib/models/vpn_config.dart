class VpnConfig {
  final String countryName;
  final String flagUrl;
  final String ovpnConfig;
  final String username;
  final String password;

  VpnConfig({
    required this.countryName,
    required this.flagUrl,
    required this.ovpnConfig,
    this.username = '',
    this.password = '',
  });
} 