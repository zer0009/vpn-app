import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import '../models/vpn_server.dart';
import '../models/obfuscation_types.dart';
import '../services/vpn_configuration.dart';
import '../services/traffic_monitor.dart';
import '../services/server_manager.dart';
import '../services/dns_service.dart';
import '../services/split_tunnel_service.dart';
import '../services/protocol_manager.dart';
import '../services/multi_hop_service.dart';
import '../services/obfuscation_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

enum VpnProtocolType {
  udp,
  tcp,
  tlsV1,
  tlsV2,
  tlsV3,
  http,
  http2,
  http3,
}

class VpnProvider with ChangeNotifier {
  bool _isConnected = false;
  VpnServer? _selectedServer;
  List<VpnServer> _servers = [];
  final VpnConfiguration _vpnConfig = VpnConfiguration();
  final TrafficMonitor _trafficMonitor = TrafficMonitor();
  final ServerManager _serverManager = ServerManager();
  final DnsConfiguration _dnsConfig = DnsConfiguration();
  final SplitTunnelService _splitTunnel = SplitTunnelService();
  final ProtocolManager _protocolManager = ProtocolManager();
  final MultiHopService _multiHop = MultiHopService();
  
  StreamSubscription? _trafficSubscription;
  TrafficStats _currentTrafficStats = TrafficStats(bytesIn: 0,bytesOut: 0);
  bool _isDarkMode = false;
  static const String _themeKey = 'isDarkMode';
  bool _isConnecting = false;
  Timer? _connectionTimer;
  static const int _connectionTimeout = 15; // seconds

  // Settings State
  bool _autoConnect = false;
  final bool _killSwitch = false;
  String _selectedProtocol = 'UDP';
  
  TrafficStats get currentTrafficStats => _currentTrafficStats;

  bool get isConnected => _isConnected;
  VpnServer? get selectedServer => _selectedServer;
  List<VpnServer> get servers => _servers;
  bool get isDarkMode => _isDarkMode;
  bool get isConnecting => _isConnecting;
  bool get isRecovering => _isRecovering;


  final _storage = const FlutterSecureStorage();
  
  // Add new properties
  int _connectionRetries = 0;
  static const int _maxRetries = 3;
  bool _isRecovering = false;

  // Add OpenVPN instance
  late OpenVPN _openVPN;

  // Add these new variables
  VPNStage _currentStage = VPNStage.disconnected;
  String _statusMessage = 'Disconnected';
  
  // Add getters for the new variables
  VPNStage get currentStage => _currentStage;
  String get statusMessage => _statusMessage;

  // Add new properties for error handling
  bool _hasError = false;
  String _errorMessage = '';
  int _retryAttempts = 0;
  static const int maxRetryAttempts = 3;
  Timer? _retryTimer;

  // Add getters
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  // Add new properties
  VpnProtocolType _currentProtocol = VpnProtocolType.udp;
  final Map<VpnProtocolType, String> _protocolDetails = {
    VpnProtocolType.udp: 'Fast streaming & gaming',
    VpnProtocolType.tcp: 'Reliable connection',
    VpnProtocolType.tlsV1: 'Basic encryption',
    VpnProtocolType.tlsV2: 'Enhanced security',
    VpnProtocolType.tlsV3: 'Maximum protection',
    VpnProtocolType.http: 'Web browsing',
    VpnProtocolType.http2: 'Improved web performance',
    VpnProtocolType.http3: 'Modern web protocol',
  };

  // Add getters
  VpnProtocolType get currentProtocol => _currentProtocol;
  Map<VpnProtocolType, String> get protocolDetails => Map.unmodifiable(_protocolDetails);

  // Add new properties
  final List<double> _downloadSpeedHistory = [];
  final List<double> _uploadSpeedHistory = [];
  static const int _maxHistoryPoints = 50;
  
  // Add getters
  List<double> get downloadSpeedHistory => _downloadSpeedHistory;
  List<double> get uploadSpeedHistory => _uploadSpeedHistory;
  double get maxSpeed => _calculateMaxSpeed();

  // Add missing properties
  bool _isStreaming = false;
  bool _isGaming = false;
  bool _isSecurityPriority = false;
  int _currentPing = 0;
  String _connectionDuration = '00:00:00';
  String _totalDataUsed = '0 MB';

  // Add getters
  bool get isStreaming => _isStreaming;
  bool get isGaming => _isGaming;
  bool get isSecurityPriority => _isSecurityPriority;
  int get currentPing => _currentPing;
  String get connectionDuration => _connectionDuration;
  String get totalDataUsed => _totalDataUsed;

  // Add new properties for obfuscation
  bool _isObfuscationEnabled = false;
  String _obfuscationDomain = '';
  ObfuscationType _obfuscationType = ObfuscationType.none;
  
  // Add getters
  bool get isObfuscationEnabled => _isObfuscationEnabled;
  String get obfuscationDomain => _obfuscationDomain;
  ObfuscationType get obfuscationType => _obfuscationType;

  // Add new constant
  static const String _lastConnectionStateKey = 'lastConnectionState';

  // Add new properties
  int _totalConnectionAttempts = 0;
  int _successfulConnections = 0;
  DateTime? _lastSuccessfulConnection;
  Map<String, int> _errorFrequency = {};

  // Add new properties
  static const int _qualityCheckInterval = 30; // seconds
  Timer? _qualityCheckTimer;
  double _connectionQuality = 1.0; // 0.0 to 1.0
  List<int> _recentPings = [];
  static const int _maxPingHistory = 10;

  // Add ObfuscationService instance
  final ObfuscationService _obfuscationService = ObfuscationService();

  VpnProvider() {
    initializeCredentials();
    _initializeOpenVPN();
    _loadServers();
    _initializeTrafficMonitoring();
    _loadThemePreference();
    _loadInitialServer();
    _restoreLastConnectionState();
  }

  Future<void> _restoreLastConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasConnected = prefs.getBool(_lastConnectionStateKey) ?? false;
      
      if (wasConnected && _autoConnect) {
        // Delay connection attempt to ensure proper initialization
        Future.delayed(const Duration(seconds: 2), () {
          toggleConnection();
        });
      }
    } catch (e) {
      debugPrint('Error restoring connection state: $e');
    }
  }

  void _initializeOpenVPN() {
    try {
      _openVPN = OpenVPN(
        onVpnStatusChanged: _onVpnStatusChanged,
        onVpnStageChanged: _onVpnStageChanged,
      );
      
      _openVPN.initialize(
        groupIdentifier: "group.com.example.vpn_app",
        providerBundleIdentifier: "com.example.vpn_app.VPNExtension",
        localizedDescription: "VPN Connection",
        lastStage: (stage) {
          debugPrint('Last Stage: $stage');
        },
      ).catchError((e) {
        debugPrint('OpenVPN initialization error: $e');
      });
    } catch (e) {
      debugPrint('OpenVPN setup error: $e');
    }
  }

  void _onVpnStatusChanged(dynamic status) {
    if (status != null) {
      _isConnected = status.toString().toLowerCase() == 'connected';
      _isConnecting = status.toString().toLowerCase() == 'connecting';
      notifyListeners();
    }
  }

  void _onVpnStageChanged(dynamic stage, String message) {
    try {
      _totalConnectionAttempts++;
      
      debugPrint('Processing VPN stage change: $stage, Message: $message');
      
      switch (stage) {
        case VPNStage.disconnected:
          _isConnected = false;
          _isConnecting = false;
          _connectionTimer?.cancel();
          break;
          
        case VPNStage.connected:
          _isConnected = true;
          _isConnecting = false;
          _connectionRetries = 0;
          _connectionTimer?.cancel();
          _startTrafficMonitoring();
          _successfulConnections++;
          _lastSuccessfulConnection = DateTime.now();
          break;
          
        case VPNStage.error:
          debugPrint('VPN Error: $message');
          _errorMessage = message;
          _handleConnectionError();
          _errorFrequency[message] = (_errorFrequency[message] ?? 0) + 1;
          break;
          
        case VPNStage.vpn_generate_config:
          debugPrint('Generating VPN config...');
          _isConnecting = true;
          break;
          
        case VPNStage.unknown:
          if (message.toLowerCase() == 'noprocess') {
            debugPrint('OpenVPN process not running');
            _errorMessage = 'OpenVPN process not running';
            if (_isConnecting) {
              _handleConnectionError();
            }
          } else if (message.toLowerCase() == 'reconnect') {
            debugPrint('VPN reconnecting...');
            _isConnecting = true;
            _startConnectionTimer();
          }
          break;
          
        case VPNStage.wait_connection:
          debugPrint('Waiting for connection...');
          _isConnecting = true;
          break;
          
        default:
          debugPrint('Unhandled VPN stage: $stage');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error processing VPN stage change: $e');
      _errorMessage = 'Error processing VPN stage: $e';
      _handleConnectionError();
    }
  }

  Future<void> toggleConnection() async {
    try {
      if (_isRecovering) {
        debugPrint('Recovery in progress, ignoring connection request');
        return;
      }

      // Reset error state when starting new connection
      _hasError = false;
      _errorMessage = '';
      
      _isConnecting = true;
      _currentStage = VPNStage.prepare;
      _statusMessage = 'Preparing VPN...';
      notifyListeners();

      if (_selectedServer == null) {
        await _loadInitialServer();
        if (_selectedServer == null) {
          throw Exception('No server available');
        }
      }

      final hasPermission = await checkVpnPermission();
      if (!hasPermission) {
        debugPrint('VPN permission not granted');
        return;
      }

      if (_isConnected) {
        await _performDisconnect();
      } else {
        // Get the OpenVPN configuration
        debugPrint('Getting OpenVPN config for ${_selectedServer!.hostname}');
        final configContent = await _selectedServer!.getConfig();
        
        // Validate the config before proceeding
        if (!configContent.contains('client') || 
            !configContent.contains('remote ')) {
          throw Exception('Invalid OpenVPN configuration');
        }

        final config = await _generateModifiedConfig(configContent);
        
        // More thorough disconnect
        try {
          _openVPN.disconnect();
        } catch (e) {
          debugPrint('Disconnect error (ignorable): $e');
        }
        
        await Future.delayed(const Duration(seconds: 2));
        
        // Re-initialize OpenVPN
        _initializeOpenVPN();
        await Future.delayed(const Duration(seconds: 1));
        
        debugPrint('Connecting to ${_selectedServer!.hostname}');
        await _openVPN.connect(
          config,
          _selectedServer!.serverName,
          username: 'vpn',
          password: 'vpn',
          bypassPackages: [],
          certIsRequired: true,
        );

        _connectionRetries = 0;
        _startConnectionTimer();
      }

      // Save connection state after successful connection/disconnection
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lastConnectionStateKey, _isConnected);
      
    } catch (e) {
      debugPrint('VPN connection error: $e');
      _errorMessage = e.toString();
      await _handleConnectionError();
    }
  }

  Future<void> _performDisconnect() async {
    try {
      _isConnecting = true;
      notifyListeners();
      
      // Cancel any ongoing retries
      _retryTimer?.cancel();
      _retryAttempts = 0;
      _hasError = false;
      _isRecovering = false;
      
      // More robust disconnect
      try {
        _openVPN.disconnect();
      } catch (e) {
        debugPrint('Disconnect error (ignorable): $e');
      }
      
      await Future.delayed(const Duration(seconds: 3));
      
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during disconnect: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedServer(VpnServer server) async {
    _selectedServer = server;
    notifyListeners();
  }

  Future<void> _loadServers() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final configPath = '${appDir.path}/configs/public-vpn-225.opengw.net_tcp443.ovpn';
      _servers = [VpnServer.getSpecificServer(configPath)];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading servers: $e');
      _servers = [];
      notifyListeners();
    }
  }

  Future<int> _measureServerPing(String host) async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 2));
      stopwatch.stop();
      
      if (result.isNotEmpty) {
        final ping = stopwatch.elapsedMilliseconds;
        debugPrint('Ping for $host: $ping ms');
        return ping;
      }
    } catch (e) {
      debugPrint('Ping measurement failed for $host: $e');
    }
    return 999; // Default high ping for failed measurements
  }

  void _initializeTrafficMonitoring() {
    _trafficSubscription = _trafficMonitor.trafficStats.listen((stats) {
      _currentTrafficStats = stats;
      notifyListeners();
    });
  }

  Future<void> toggleKillSwitch(bool enabled) async {
    if (enabled) {
      await _vpnConfig.enableKillSwitch();
    } else {
      await _vpnConfig.disableKillSwitch();
    }
    notifyListeners();
  }

  Future<void> refreshServerList() async {
    _servers = await _serverManager.getSortedServers(_servers);
    notifyListeners();
  }

  Future<void> updateProtocol(ProtocolConfiguration config) async {
    await _protocolManager.switchProtocol(config);
    if (isConnected) {
      await toggleConnection();
      await toggleConnection();
    }
    notifyListeners();
  }

  Future<void> configureMultiHop(List<VpnServer> servers) async {
    await _multiHop.enableMultiHop(servers);
    notifyListeners();
  }

  Future<void> updateDns(String dnsServer) async {
    await _dnsConfig.setCustomDns(dnsServer);
    notifyListeners();
  }

  Future<void> toggleSplitTunneling(bool enabled) async {
    await _splitTunnel.toggleSplitTunneling(enabled);
    notifyListeners();
  }

  void _startTrafficMonitoring() {
    _trafficMonitor.startMonitoring();
  }

  void _stopTrafficMonitoring() {
    _trafficMonitor.stopMonitoring();
    _currentTrafficStats = TrafficStats(bytesIn: 0,bytesOut: 0);
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  void _handleConnectionTimeout() {
    debugPrint('Connection timeout reached');
    _openVPN.disconnect();
    _handleConnectionError();
  }

  Future<String> _generateModifiedConfig(String originalConfig) async {
    try {
      final StringBuffer configBuffer = StringBuffer();
      
      // Add obfuscation configuration if enabled
      if (_isObfuscationEnabled && _obfuscationDomain.isNotEmpty) {
        switch (_obfuscationType) {
          case ObfuscationType.http:
            // HTTP obfuscation settings
            configBuffer.writeln('# HTTP Obfuscation Settings');
            configBuffer.writeln('http-proxy ${_obfuscationDomain} 80');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "Host: ${_obfuscationDomain}"');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "Accept: text/html,application/xhtml+xml,application/xml"');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "Accept-Language: en-US,en;q=0.9"');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "Connection: keep-alive"');
            break;
            
          case ObfuscationType.tls:
            // TLS obfuscation settings
            configBuffer.writeln('# TLS Obfuscation Settings');
            configBuffer.writeln('tls-version-min 1.2');
            configBuffer.writeln('tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384:TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384');
            configBuffer.writeln('tls-crypt-v2');
            configBuffer.writeln('tls-client');
            configBuffer.writeln('remote-cert-tls server');
            configBuffer.writeln('verify-x509-name "${_obfuscationDomain}" name');
            configBuffer.writeln('sni "${_obfuscationDomain}"');
            break;
            
          case ObfuscationType.shadowsocks:
            // Shadowsocks obfuscation settings
            configBuffer.writeln('# Shadowsocks Obfuscation Settings');
            configBuffer.writeln('plugin shadowsocks-plugin');
            configBuffer.writeln('plugin-opts "server;host=${_obfuscationDomain};port=443"');
            break;
            
          case ObfuscationType.stunnel:
            // STunnel obfuscation settings
            configBuffer.writeln('# STunnel Obfuscation Settings');
            configBuffer.writeln('stunnel');
            configBuffer.writeln('stunnel-proxy ${_obfuscationDomain}:443');
            configBuffer.writeln('stunnel-verify-chain');
            break;
            
          case ObfuscationType.websocket:
            // WebSocket obfuscation settings
            configBuffer.writeln('# WebSocket Obfuscation Settings');
            configBuffer.writeln('http-proxy ${_obfuscationDomain} 80');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "Host: ${_obfuscationDomain}"');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "Upgrade: websocket"');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "Connection: Upgrade"');
            configBuffer.writeln('http-proxy-option CUSTOM-HEADER "Sec-WebSocket-Protocol: openvpn"');
            break;
            
          case ObfuscationType.xor:
            // XOR obfuscation settings
            configBuffer.writeln('# XOR Obfuscation Settings');
            configBuffer.writeln('scramble xormask');
            configBuffer.writeln('scramble-key "${_obfuscationDomain}"');
            break;
            
          case ObfuscationType.none:
            // No obfuscation settings needed
            break;
        }
        
        // Add additional scrambling options
        configBuffer.writeln('scramble obfuscate');
        configBuffer.writeln('mssfix 1400');
      }

      // Add protocol-specific configuration
      switch (_currentProtocol) {
        case VpnProtocolType.udp:
          configBuffer.writeln('proto udp');
          break;
        case VpnProtocolType.tcp:
          configBuffer.writeln('proto tcp');
          break;
        case VpnProtocolType.tlsV1:
          configBuffer.writeln('proto tcp');
          configBuffer.writeln('tls-version-min 1.0');
          break;
        case VpnProtocolType.tlsV2:
          configBuffer.writeln('proto tcp');
          configBuffer.writeln('tls-version-min 1.2');
          break;
        case VpnProtocolType.tlsV3:
          configBuffer.writeln('proto tcp');
          configBuffer.writeln('tls-version-min 1.3');
          break;
        case VpnProtocolType.http:
          configBuffer.writeln('proto tcp');
          configBuffer.writeln('http-proxy');
          break;
        case VpnProtocolType.http2:
          configBuffer.writeln('proto tcp');
          configBuffer.writeln('http-proxy');
          configBuffer.writeln('http-proxy-option VERSION 2');
          break;
        case VpnProtocolType.http3:
          configBuffer.writeln('proto tcp');
          configBuffer.writeln('http-proxy');
          configBuffer.writeln('http-proxy-option VERSION 3');
          break;
      }

      // Add header comment
      configBuffer.writeln('###############################');
      configBuffer.writeln('# Modified OpenVPN config file #');
      configBuffer.writeln('###############################');
      configBuffer.writeln();

      // Basic settings - matching original config more closely
      configBuffer.writeln('client');
      configBuffer.writeln('dev tun');
      configBuffer.writeln('dev-type tun');
      configBuffer.writeln('proto tcp');
      configBuffer.writeln('remote ${_selectedServer!.hostname} ${_selectedServer!.port}');
      
      // Connection settings
      configBuffer.writeln('nobind');
      configBuffer.writeln('persist-tun');
      configBuffer.writeln('cipher AES-128-CBC');
      configBuffer.writeln('auth SHA1');
      configBuffer.writeln('verb 2');
      configBuffer.writeln('mute 3');
      configBuffer.writeln('push-peer-info');
      configBuffer.writeln('ping 10');
      configBuffer.writeln('ping-restart 60');
      configBuffer.writeln('hand-window 70');
      configBuffer.writeln('server-poll-timeout 4');
      configBuffer.writeln('reneg-sec 2592000');
      configBuffer.writeln('sndbuf 393216');
      configBuffer.writeln('rcvbuf 393216');
      configBuffer.writeln('max-routes 1000');
      configBuffer.writeln('remote-cert-tls server');
      configBuffer.writeln('comp-lzo no');
      configBuffer.writeln('auth-user-pass');
      configBuffer.writeln('key-direction 1');
      
      // Add data ciphers from original config
      configBuffer.writeln('ignore-unknown-option data-ciphers');
      configBuffer.writeln('data-ciphers AES-128-GCM:AES-128-CBC');

      // Extract certificates from original config
      final certSections = {
        'ca': extractSection(originalConfig, 'ca'),
        'cert': extractSection(originalConfig, 'cert'),
        'key': extractSection(originalConfig, 'key'),
        'tls-auth': extractSection(originalConfig, 'tls-auth')
      };

      // Add certificates to config
      certSections.forEach((key, value) {
        if (value.isNotEmpty) {
          configBuffer.writeln('<$key>');
          configBuffer.writeln(value.trim());
          configBuffer.writeln('</$key>');
          configBuffer.writeln();
        }
      });

      final config = configBuffer.toString();
      debugPrint('Generated OpenVPN config (length: ${config.length})');
      return config;
    } catch (e, stackTrace) {
      debugPrint('Config generation error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  String extractSection(String config, String section) {
    final startTag = '<$section>';
    final endTag = '</$section>';
    
    if (config.contains(startTag) && config.contains(endTag)) {
      final start = config.indexOf(startTag) + startTag.length;
      final end = config.indexOf(endTag);
      return config.substring(start, end).trim();
    }
    return '';
  }

  bool _validateConfig(String config) {
    if (config.isEmpty) return false;
    
    // Check for required sections
    final requiredSections = ['ca', 'cert', 'key', 'tls-auth'];
    for (final section in requiredSections) {
      if (!config.contains('<$section>') || !config.contains('</$section>')) {
        debugPrint('Missing required section: $section');
        return false;
      }
    }
    
    // Check for basic configuration
    final requiredSettings = [
      'client',
      'dev tun',
      'remote',
      'cipher',
      'auth',
      'proto tcp',
    ];
    
    for (final setting in requiredSettings) {
      if (!config.contains(setting)) {
        debugPrint('Missing required setting: $setting');
        return false;
      }
    }
    
    return true;
  }

  Future<void> _loadInitialServer() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final configPath = '${appDir.path}/configs/public-vpn-225.opengw.net_tcp443.ovpn';
      _selectedServer = VpnServer.getSpecificServer(configPath);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading initial server: $e');
      throw Exception('Failed to load initial server: $e');
    }
  }

  Future<void> initializeCredentials() async {
    final hasCredentials = await _storage.read(key: 'vpn_credentials_stored');
    if (hasCredentials != 'true') {
      // VPNGate doesn't require authentication
      await _storage.write(key: 'vpn_username', value: 'vpn');
      await _storage.write(key: 'vpn_password', value: 'vpn');
      await _storage.write(key: 'vpn_credentials_stored', value: 'true');
    }
  }

  @override
  void dispose() {
    _trafficSubscription?.cancel();
    _trafficMonitor.stopMonitoring();
    _serverManager.dispose();
    _connectionTimer?.cancel();
    _retryTimer?.cancel();
    _qualityCheckTimer?.cancel();
    super.dispose();
  }

  DnsConfiguration get dnsConfig => _dnsConfig;
  SplitTunnelService get splitTunnel => _splitTunnel;
  ProtocolManager get protocolManager => _protocolManager;
  MultiHopService get multiHop => _multiHop;

  // Getters
  bool get autoConnect => _autoConnect;
  bool get killSwitch => _killSwitch;
  String get selectedProtocol => _selectedProtocol;

  // Settings Methods
  void toggleAutoConnect(bool value) {
    _autoConnect = value;
    // TODO: Implement persistent storage
    notifyListeners();
  }

  void setProtocol(String protocol) {
    if (_selectedProtocol != protocol) {
      _selectedProtocol = protocol;
      // TODO: Implement persistent storage
      notifyListeners();
    }
  }

  // Add method to check VPN permissions
  Future<bool> checkVpnPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await const MethodChannel('vpn_channel')
            .invokeMethod<bool>('checkVPNPermission');
        debugPrint('VPN permission check result: $result');
        // If permission is not granted, we'll still return true because the permission request
        // has been initiated and we'll handle the result in onActivityResult
        return true;
      }
      // iOS always returns true as permissions are handled through profiles
      return true;
    } catch (e) {
      debugPrint('Error checking VPN permission: $e');
      // Return true to allow the connection attempt
      return true;
    }
  }

  Future<void> _handleConnectionError() async {
    debugPrint('Handling connection error...');
    _isConnecting = false;
    _isConnected = false;
    _connectionTimer?.cancel();
    
    if (_retryAttempts < maxRetryAttempts) {
      _retryAttempts++;
      debugPrint('Retrying connection (attempt $_retryAttempts of $maxRetryAttempts)');
      _isRecovering = true;
      notifyListeners();
      
      // Increased exponential backoff
      final delay = Duration(seconds: pow(2, _retryAttempts + 1).toInt());
      debugPrint('Waiting ${delay.inSeconds} seconds before retry...');
      
      // Cancel any existing retry timer
      _retryTimer?.cancel();
      
      // Start new retry timer
      _retryTimer = Timer(delay, () async {
        _isRecovering = false;

        // More thorough disconnect
        try {
          _openVPN.disconnect();
        } catch (e) {
          debugPrint('Disconnect error (ignorable): $e');
        }
        
        await Future.delayed(const Duration(seconds: 3));
        
        // Re-initialize OpenVPN before retry
        _initializeOpenVPN();
        await Future.delayed(const Duration(seconds: 1));

        if (_selectedServer != null) {
          debugPrint('Attempting to reconnect...');
          await toggleConnection();
        }
      });
      
    } else {
      debugPrint('Max retries reached, giving up');
      _retryAttempts = 0;
      _hasError = true;
      await _performDisconnect();
      _statusMessage = 'Connection failed after $maxRetryAttempts attempts';
    }
    
    notifyListeners();
  }

  // Add connection timer method
  void _startConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer(Duration(seconds: _connectionTimeout), () {
      if (_isConnecting) {
        debugPrint('Connection timeout reached');
        _handleConnectionError();
      }
    });
  }

  // Add this method to check OpenVPN installation
  Future<bool> _checkOpenVPNInstallation() async {
    try {
      if (Platform.isAndroid) {
        try {
          final result = await const MethodChannel('vpn_channel')
              .invokeMethod<bool>('checkOpenVPNInstallation');
          debugPrint('OpenVPN Installation Check Result: $result');
          return result ?? false;
        } on MissingPluginException {
          debugPrint('OpenVPN installation check method not implemented');
          return true; // Default to true to allow connection attempts
        }
      }
      return true; // iOS or other platforms
    } catch (e) {
      debugPrint('Error checking OpenVPN installation: $e');
      return true; // Fallback to allowing connection
    }
  }

  void _handleStageChange(VPNStage stage, String message) {
    try {
      debugPrint('Processing VPN stage change: $stage, Message: $message');
      
      switch (stage) {
        case VPNStage.prepare:
          _currentStage = stage;
          _statusMessage = 'Preparing VPN...';
          break;

        case VPNStage.connecting:
          _currentStage = stage;
          _statusMessage = 'Connecting...';
          break;

        case VPNStage.tcp_connect:
          _currentStage = stage;
          _statusMessage = 'Establishing TCP connection...';
          _isConnecting = true;
          // Reset connection timer when TCP connection starts
          _startConnectionTimer();
          break;

        case VPNStage.authenticating:
          _currentStage = stage;
          _statusMessage = 'Authenticating...';
          break;

        case VPNStage.wait_connection:
          _currentStage = stage;
          _statusMessage = 'Waiting for connection...';
          break;

        case VPNStage.get_config:
          _currentStage = stage;
          _statusMessage = 'Retrieving configuration...';
          break;

        case VPNStage.assign_ip:
          _currentStage = stage;
          _statusMessage = 'Assigning IP address...';
          break;

        case VPNStage.connected:
          _currentStage = stage;
          _statusMessage = 'Connected';
          _isConnected = true;
          _isConnecting = false;
          _connectionRetries = 0;
          break;

        case VPNStage.disconnected:
          _currentStage = stage;
          _statusMessage = 'Disconnected';
          _isConnected = false;
          _isConnecting = false;
          break;

        case VPNStage.exiting:
          _currentStage = stage;
          _statusMessage = 'Disconnecting...';
          break;

        case VPNStage.resolve:
          _currentStage = stage;
          _statusMessage = 'Resolving server address...';
          break;

        case VPNStage.vpn_generate_config:
          _currentStage = stage;
          _statusMessage = 'Generating VPN config...';
          break;

        case VPNStage.unknown:
          if (message.toLowerCase() == 'reconnect') {
            _statusMessage = 'VPN reconnecting...';
            _isConnecting = true;
            _startConnectionTimer();
          } else if (message.toLowerCase() == 'noprocess') {
            _statusMessage = 'OpenVPN process not running';
            _errorMessage = 'OpenVPN process not running';
            _handleConnectionError();
          } else if (message.toLowerCase() == 'no_connection') {
            _statusMessage = 'Connection failed';
            _errorMessage = 'Connection failed';
            _handleConnectionError();
          }
          break;

        default:
          debugPrint('Unhandled VPN stage: $stage');
          break;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error processing VPN stage change: $e');
      _errorMessage = 'Error processing VPN stage: $e';
      _handleConnectionError();
    }
  }

  // Add method to reset error state
  void resetError() {
    _hasError = false;
    _errorMessage = '';
    _retryAttempts = 0;
    _isRecovering = false;
    _retryTimer?.cancel();
    notifyListeners();
  }

  // Add method to change protocol
  Future<void> changeProtocol(VpnProtocolType protocol) async {
    if (_currentProtocol != protocol) {
      _currentProtocol = protocol;
      if (_isConnected) {
        await toggleConnection(); // Disconnect
        await toggleConnection(); // Reconnect with new protocol
      }
      notifyListeners();
    }
  }

  // Add method to update speed history
  void _updateSpeedHistory(double download, double upload) {
    _downloadSpeedHistory.add(download);
    _uploadSpeedHistory.add(upload);

    if (_downloadSpeedHistory.length > _maxHistoryPoints) {
      _downloadSpeedHistory.removeAt(0);
      _uploadSpeedHistory.removeAt(0);
    }
    notifyListeners();
  }

  double _calculateMaxSpeed() {
    final maxDownload = _downloadSpeedHistory.isEmpty
        ? 1.0
        : _downloadSpeedHistory.reduce((max, speed) => speed > max ? speed : max);
    final maxUpload = _uploadSpeedHistory.isEmpty
        ? 1.0
        : _uploadSpeedHistory.reduce((max, speed) => speed > max ? speed : max);
    return (max(maxDownload, maxUpload) * 1.2).ceilToDouble();
  }

  // Update your existing traffic monitoring
  void _handleTrafficUpdate(TrafficStats stats) {
    _currentTrafficStats = stats;
    _updateSpeedHistory(
      stats.downloadSpeed,
      stats.uploadSpeed,
    );
    _updateTotalDataUsed(stats.bytesIn, stats.bytesOut);
    _updateConnectionDuration(stats.duration);
    _updatePing(stats.ping);
    notifyListeners();
  }

  // Add methods to update usage type
  void setStreamingMode(bool value) {
    _isStreaming = value;
    notifyListeners();
  }

  void setGamingMode(bool value) {
    _isGaming = value;
    notifyListeners();
  }

  void setSecurityPriority(bool value) {
    _isSecurityPriority = value;
    notifyListeners();
  }

  // Update ping
  void _updatePing(int ping) {
    _currentPing = ping;
    notifyListeners();
  }

  // Update connection duration
  void _updateConnectionDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    _connectionDuration = '$hours:$minutes:$seconds';
    notifyListeners();
  }

  // Update total data used
  void _updateTotalDataUsed(int bytesIn, int bytesOut) {
    final totalBytes = bytesIn + bytesOut;
    if (totalBytes < 1024 * 1024) {
      _totalDataUsed = '${(totalBytes / 1024).toStringAsFixed(2)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      _totalDataUsed = '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      _totalDataUsed = '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    notifyListeners();
  }

  // Example method to update traffic stats
  void updateTrafficStats({
    required double downloadSpeed,
    required double uploadSpeed,
    required int bytesIn,
    required int bytesOut,
    required Duration duration,
    required int ping,
  }) {
    _currentTrafficStats = TrafficStats.fromData(
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      bytesIn: bytesIn,
      bytesOut: bytesOut,
      duration: duration,
      ping: ping,
    );
    _handleTrafficUpdate(_currentTrafficStats);
  }

  // Add new methods for obfuscation settings
  Future<void> configureObfuscation(ObfuscationConfig config) async {
    try {
      // Use the obfuscation service for configuration
      if (config.isEnabled) {
        final isSupported = await _obfuscationService.isObfuscationTypeSupported(
          _selectedServer?.hostname ?? '',
          config.type,
        );
        
        if (!isSupported) {
          throw Exception('Selected obfuscation type is not supported by the server');
        }
      }

      _isObfuscationEnabled = config.isEnabled;
      _obfuscationType = config.type;
      _obfuscationDomain = config.domain;
      
      // Save settings to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('obfuscation_enabled', config.isEnabled);
      await prefs.setString('obfuscation_type', config.type.toString());
      await prefs.setString('obfuscation_domain', config.domain);
      
      if (_isConnected) {
        // Reconnect to apply new settings
        await toggleConnection(); // Disconnect
        await toggleConnection(); // Reconnect
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error configuring obfuscation: $e');
      throw Exception('Failed to configure obfuscation: $e');
    }
  }

  // Add new getters
  double get connectionSuccessRate => 
      _totalConnectionAttempts > 0 ? _successfulConnections / _totalConnectionAttempts : 0;
  
  DateTime? get lastSuccessfulConnection => _lastSuccessfulConnection;
  
  Map<String, int> get errorFrequency => Map.unmodifiable(_errorFrequency);

  // Add to connection logic
  void _startQualityMonitoring() {
    _qualityCheckTimer?.cancel();
    _qualityCheckTimer = Timer.periodic(
      const Duration(seconds: _qualityCheckInterval),
      (_) => _checkConnectionQuality(),
    );
  }

  Future<void> _checkConnectionQuality() async {
    if (!_isConnected || _selectedServer == null) return;

    final ping = await _measureServerPing(_selectedServer!.hostname);
    _recentPings.add(ping);
    if (_recentPings.length > _maxPingHistory) {
      _recentPings.removeAt(0);
    }

    // Calculate quality based on ping stability and speed
    final avgPing = _recentPings.reduce((a, b) => a + b) / _recentPings.length;
    final pingVariance = _recentPings
        .map((p) => pow(p - avgPing, 2))
        .reduce((a, b) => a + b) / _recentPings.length;
    
    // Factor in current speeds
    final speedQuality = min(
      1.0,
      (_currentTrafficStats.downloadSpeed / 1000000) // Normalize to Mbps
    );

    // Combine factors
    _connectionQuality = max(0.0, min(1.0,
      (1.0 - (avgPing / 1000)) * 0.4 + // Ping factor
      (1.0 - (pingVariance / 10000)) * 0.3 + // Stability factor
      speedQuality * 0.3 // Speed factor
    ));

    notifyListeners();
  }

  // Add getter
  double get connectionQuality => _connectionQuality;
} 