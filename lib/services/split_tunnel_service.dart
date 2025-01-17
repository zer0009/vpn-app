import 'dart:io';
import '../models/application_info.dart';

class SplitTunnelService {
  final Set<String> _excludedApps = {};
  final Set<String> _excludedIps = {};
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;
  Set<String> get excludedApps => _excludedApps;
  Set<String> get excludedIps => _excludedIps;

  Future<void> toggleSplitTunneling(bool enabled) async {
    _isEnabled = enabled;
    if (enabled) {
      await _applyRouting();
    } else {
      await _resetRouting();
    }
  }

  Future<void> addExcludedApp(String packageName) async {
    _excludedApps.add(packageName);
    if (_isEnabled) {
      await _updateRoutingRules();
    }
  }

  Future<void> removeExcludedApp(String packageName) async {
    _excludedApps.remove(packageName);
    if (_isEnabled) {
      await _updateRoutingRules();
    }
  }

  Future<void> addExcludedIp(String ip) async {
    if (_isValidIp(ip)) {
      _excludedIps.add(ip);
      if (_isEnabled) {
        await _updateRoutingRules();
      }
    }
  }

  Future<List<ApplicationInfo>> getInstalledApps() async {
    // Implementation would require platform-specific code
    // to get list of installed applications
    return [];
  }

  bool _isValidIp(String ip) {
    try {
      InternetAddress(ip);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyRouting() async {
    // Implementation would require platform-specific code
    // to configure routing rules
  }

  Future<void> _resetRouting() async {
    // Implementation would require platform-specific code
    // to reset routing rules
  }

  Future<void> _updateRoutingRules() async {
    // Implementation would require platform-specific code
    // to update routing rules
  }
} 