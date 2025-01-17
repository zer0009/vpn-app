import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import 'speed_test_service.dart';
import 'vpn_service.dart';
import '../models/obfuscation_types.dart';

enum ProtocolConfiguration {
  tcp,
  udp,
  wireguard,
  httpObfuscated,
  tlsObfuscated,
}

class ProtocolManager extends ChangeNotifier {
  final SpeedTestService _speedTest = SpeedTestService();
  final VpnService _vpnService = VpnService();
  
  static const String _protocolKey = 'selected_protocol';
  static const String _obfuscationKey = 'obfuscation_enabled';
  static const String _obfuscationTypeKey = 'obfuscation_type';
  static const String _obfuscationDomainKey = 'obfuscation_domain';
  
  ProtocolConfiguration _currentProtocol = ProtocolConfiguration.udp;
  bool _isObfuscationEnabled = false;
  ObfuscationType _obfuscationType = ObfuscationType.none;
  String _obfuscationDomain = '';
  bool _isChangingProtocol = false;
  Timer? _speedTestTimer;

  // Add performance metrics properties
  double _currentSpeed = 0.0;
  int _currentLatency = 0;
  bool _isProtocolStable = true;
  final Map<ProtocolConfiguration, ProtocolMetrics> _protocolMetrics = {};

  // Getters
  ProtocolConfiguration get currentProtocol => _currentProtocol;
  bool get isObfuscationEnabled => _isObfuscationEnabled;
  ObfuscationType get obfuscationType => _obfuscationType;
  String get obfuscationDomain => _obfuscationDomain;
  bool get isChangingProtocol => _isChangingProtocol;
  double get currentSpeed => _currentSpeed;
  int get currentLatency => _currentLatency;
  bool get isProtocolStable => _isProtocolStable;

  ProtocolManager() {
    _initializeProtocolMetrics();
  }

  void _initializeProtocolMetrics() {
    _protocolMetrics.addAll({
      ProtocolConfiguration.tcp: ProtocolMetrics(
        description: 'TCP - Reliable connection',
        defaultPort: 443,
      ),
      ProtocolConfiguration.udp: ProtocolMetrics(
        description: 'UDP - Fast performance',
        defaultPort: 1194,
      ),
      ProtocolConfiguration.wireguard: ProtocolMetrics(
        description: 'WireGuard - Modern & secure',
        defaultPort: 51820,
      ),
      ProtocolConfiguration.httpObfuscated: ProtocolMetrics(
        description: 'HTTP - Obfuscated traffic',
        defaultPort: 80,
      ),
      ProtocolConfiguration.tlsObfuscated: ProtocolMetrics(
        description: 'TLS - Enhanced obfuscation',
        defaultPort: 443,
      ),
    });
  }

  Future<void> initialize() async {
    await _loadSettings();
    _startPerformanceMonitoring();
  }

  void _startPerformanceMonitoring() {
    _speedTestTimer?.cancel();
    _speedTestTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _measureCurrentPerformance();
    });
  }

  Future<void> _measureCurrentPerformance() async {
    try {
      final result = await _speedTest.measureSpeed();
      
      _currentSpeed = result.downloadSpeed;
      _currentLatency = result.latency;
      
      final metrics = _protocolMetrics[_currentProtocol]!;
      metrics.updateMetrics(_currentSpeed, _currentLatency);
      
      _isProtocolStable = _checkStability(
        _currentSpeed,
        _currentLatency,
        result.testDuration,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Performance measurement error: $e');
      _handlePerformanceError();
    }
  }

  bool _checkStability(double speed, int latency, Duration testDuration) {
    // Define stability thresholds
    const minAcceptableSpeed = 5.0; // Mbps
    const maxAcceptableLatency = 200; // ms
    const maxAcceptableTestDuration = Duration(seconds: 5);

    return speed >= minAcceptableSpeed && 
           latency <= maxAcceptableLatency &&
           testDuration <= maxAcceptableTestDuration;
  }

  void _handlePerformanceError() {
    final metrics = _protocolMetrics[_currentProtocol]!;
    metrics.failedConnections++;
    metrics.updateStabilityScore();
    
    if (!_isProtocolStable) {
      _recommendBetterProtocol();
    }
  }

  Future<void> _recommendBetterProtocol() async {
    final betterProtocol = _findBestProtocol();
    if (betterProtocol != _currentProtocol) {
      debugPrint('Recommending switch to better protocol: $betterProtocol');
      // Implement your protocol switch recommendation UI here
    }
  }

  ProtocolConfiguration _findBestProtocol() {
    var bestProtocol = _currentProtocol;
    var bestScore = double.negativeInfinity;

    for (var entry in _protocolMetrics.entries) {
      final score = entry.value.calculateOverallScore();
      if (score > bestScore) {
        bestScore = score;
        bestProtocol = entry.key;
      }
    }

    return bestProtocol;
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load protocol
      final protocolStr = prefs.getString(_protocolKey);
      if (protocolStr != null) {
        _currentProtocol = ProtocolConfiguration.values.firstWhere(
          (e) => e.toString() == protocolStr,
          orElse: () => ProtocolConfiguration.udp,
        );
      }

      // Load obfuscation settings
      _isObfuscationEnabled = prefs.getBool(_obfuscationKey) ?? false;
      final obfuscationTypeStr = prefs.getString(_obfuscationTypeKey);
      if (obfuscationTypeStr != null) {
        _obfuscationType = ObfuscationType.values.firstWhere(
          (e) => e.toString() == obfuscationTypeStr,
          orElse: () => ObfuscationType.none,
        );
      }
      _obfuscationDomain = prefs.getString(_obfuscationDomainKey) ?? '';
      
      debugPrint('Protocol settings loaded: $_currentProtocol, Obfuscation: $_isObfuscationEnabled');
    } catch (e) {
      debugPrint('Error loading protocol settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_protocolKey, _currentProtocol.toString());
      await prefs.setBool(_obfuscationKey, _isObfuscationEnabled);
      await prefs.setString(_obfuscationTypeKey, _obfuscationType.toString());
      await prefs.setString(_obfuscationDomainKey, _obfuscationDomain);
    } catch (e) {
      debugPrint('Error saving protocol settings: $e');
    }
  }

  Future<void> switchProtocol(ProtocolConfiguration protocol) async {
    _currentProtocol = protocol;
    await _saveSettings();
    await applyCurrentProtocol();
  }

  Future<void> configureObfuscation({
    required bool enabled,
    required ObfuscationType type,
    required String domain,
  }) async {
    _isObfuscationEnabled = enabled;
    _obfuscationType = type;
    _obfuscationDomain = domain;
    
    // Update protocol based on obfuscation settings
    if (enabled) {
      switch (type) {
        case ObfuscationType.http:
          _currentProtocol = ProtocolConfiguration.httpObfuscated;
          break;
        case ObfuscationType.tls:
          _currentProtocol = ProtocolConfiguration.tlsObfuscated;
          break;
        case ObfuscationType.shadowsocks:
          // Handle Shadowsocks protocol
          _currentProtocol = ProtocolConfiguration.tcp; // or appropriate fallback
          break;
        case ObfuscationType.stunnel:
          _currentProtocol = ProtocolConfiguration.tlsObfuscated;
          break;
        case ObfuscationType.websocket:
          _currentProtocol = ProtocolConfiguration.httpObfuscated;
          break;
        case ObfuscationType.xor:
          _currentProtocol = ProtocolConfiguration.tcp; // or appropriate fallback
          break;
        case ObfuscationType.none:
          // Keep current non-obfuscated protocol
          break;
      }
    }
    
    await _saveSettings();
    await applyCurrentProtocol();
  }

  Future<void> applyCurrentProtocol() async {
    try {
      final config = await _generateProtocolConfig();
      debugPrint('Applying protocol configuration: ${config.length} bytes');
      
      // Here you would typically apply the configuration to your VPN connection
      // This is a placeholder for the actual implementation
      await _applyConfiguration(config);
      
    } catch (e) {
      debugPrint('Failed to apply protocol configuration: $e');
      rethrow;
    }
  }

  Future<String> _generateProtocolConfig() async {
    final StringBuffer config = StringBuffer();
    
    // Base protocol configuration
    switch (_currentProtocol) {
      case ProtocolConfiguration.tcp:
        config.writeln('proto tcp');
        config.writeln('remote-proto tcp');
        break;
        
      case ProtocolConfiguration.udp:
        config.writeln('proto udp');
        config.writeln('remote-proto udp');
        break;
        
      case ProtocolConfiguration.wireguard:
        config.writeln('proto udp');
        config.writeln('use-wireguard');
        break;
        
      case ProtocolConfiguration.httpObfuscated:
        config.writeln('proto tcp');
        if (_obfuscationDomain.isNotEmpty) {
          config.writeln('http-proxy-option CUSTOM-HEADER Host $_obfuscationDomain');
          config.writeln('http-proxy $_obfuscationDomain 80');
        }
        break;
        
      case ProtocolConfiguration.tlsObfuscated:
        config.writeln('proto tcp');
        if (_obfuscationDomain.isNotEmpty) {
          config.writeln('tls-crypt');
          config.writeln('tls-client');
          config.writeln('remote-cert-tls server');
          config.writeln('sni $_obfuscationDomain');
        }
        break;
    }

    // Add common settings
    config.writeln('cipher AES-256-GCM');
    config.writeln('auth SHA256');
    config.writeln('keysize 256');
    
    // Add additional security settings for obfuscated protocols
    if (_isObfuscationEnabled) {
      config.writeln('tls-version-min 1.2');
      config.writeln('tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384');
    }

    return config.toString();
  }

  Future<void> _applyConfiguration(String config) async {
    try {
      await _vpnService.connect(config);
    } catch (e) {
      debugPrint('VPN configuration error: $e');
      rethrow;
    }
  }

  String getProtocolDescription(ProtocolConfiguration protocol) {
    return _protocolMetrics[protocol]?.description ?? 'Unknown protocol';
  }

  bool isObfuscatedProtocol(ProtocolConfiguration protocol) {
    return protocol == ProtocolConfiguration.httpObfuscated || 
           protocol == ProtocolConfiguration.tlsObfuscated;
  }

  List<ProtocolConfiguration> getAvailableProtocols({bool includeObfuscated = true}) {
    if (includeObfuscated) {
      return ProtocolConfiguration.values;
    }
    return ProtocolConfiguration.values.where(
      (p) => !isObfuscatedProtocol(p)
    ).toList();
  }

  // Method to get recommended protocol based on usage
  ProtocolConfiguration getRecommendedProtocol({
    bool isGaming = false,
    bool isStreaming = false,
    bool isSecurityPriority = false,
    int currentPing = 0,
  }) {
    if (isGaming && currentPing > 100) {
      return ProtocolConfiguration.udp;
    }
    
    if (isStreaming && currentPing < 150) {
      return ProtocolConfiguration.tcp;
    }
    
    if (isSecurityPriority) {
      return ProtocolConfiguration.tlsObfuscated;
    }
    
    return ProtocolConfiguration.udp; // Default recommendation
  }

  @override
  void dispose() {
    _speedTestTimer?.cancel();
    _vpnService.dispose();
    super.dispose();
  }
}

class ProtocolMetrics {
  final String description;
  final int defaultPort;
  double averageSpeed;
  int averageLatency;
  double stabilityScore;
  int successfulConnections;
  int failedConnections;
  final List<double> _speedHistory = [];
  final List<int> _latencyHistory = [];
  static const int _maxHistorySize = 10;

  ProtocolMetrics({
    required this.description,
    required this.defaultPort,
    this.averageSpeed = 0.0,
    this.averageLatency = 0,
    this.stabilityScore = 0.0,
    this.successfulConnections = 0,
    this.failedConnections = 0,
  });

  void updateMetrics(double speed, int latency) {
    _speedHistory.add(speed);
    _latencyHistory.add(latency);

    if (_speedHistory.length > _maxHistorySize) {
      _speedHistory.removeAt(0);
      _latencyHistory.removeAt(0);
    }

    averageSpeed = _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;
    averageLatency = (_latencyHistory.reduce((a, b) => a + b) / _latencyHistory.length).round();
    updateStabilityScore();
  }

  void updateStabilityScore() {
    if (successfulConnections + failedConnections == 0) {
      stabilityScore = 0.0;
      return;
    }
    
    final successRate = successfulConnections / (successfulConnections + failedConnections);
    final speedVariance = _calculateVariance(_speedHistory);
    final latencyVariance = _calculateVariance(_latencyHistory.map((e) => e.toDouble()).toList());

    stabilityScore = successRate * 0.4 + 
                     (1 - speedVariance) * 0.3 + 
                     (1 - latencyVariance) * 0.3;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((value) => math.pow(value - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  double calculateOverallScore() {
    const weights = {
      'speed': 0.3,
      'latency': 0.3,
      'stability': 0.4,
    };

    return (averageSpeed * weights['speed']!) +
           ((1000 - averageLatency) / 1000 * weights['latency']!) +
           (stabilityScore * weights['stability']!);
  }
} 