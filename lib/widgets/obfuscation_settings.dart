import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/vpn_provider.dart';
import '../constants/app_colors.dart';
import '../models/obfuscation_types.dart';
import '../services/obfuscation_service.dart';
import 'dart:developer';
import 'apply_button.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class ObfuscationSettings extends StatefulWidget {
  const ObfuscationSettings({super.key});

  @override
  State<ObfuscationSettings> createState() => _ObfuscationSettingsState();
}

class _ObfuscationSettingsState extends State<ObfuscationSettings> {
  final _domainController = TextEditingController();
  bool _isEnabled = false;
  ObfuscationType _selectedType = ObfuscationType.none;
  String? _errorMessage;
  bool _isLoading = false;
  List<ObfuscationType> _supportedTypes = [];
  bool _isCheckingCompatibility = false;
  Map<String, TextEditingController> _additionalParamsControllers = {};
  bool _isApplying = false;
  String? _httpStatus;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _checkServerCompatibility();
    _checkHttpStatus();
  }

  void _initializeSettings() {
    final provider = context.read<VpnProvider>();
    _isEnabled = provider.isObfuscationEnabled;
    _selectedType = provider.obfuscationType;
    _domainController.text = provider.obfuscationDomain;
    _initializeAdditionalParams();
  }

  void _initializeAdditionalParams() {
    switch (_selectedType) {
      case ObfuscationType.shadowsocks:
        _additionalParamsControllers = {
          'port': TextEditingController(text: '8388'),
          'password': TextEditingController(),
          'method': TextEditingController(text: 'aes-256-gcm'),
        };
        break;
      case ObfuscationType.stunnel:
        _additionalParamsControllers = {
          'cert': TextEditingController(),
        };
        break;
      default:
        _additionalParamsControllers = {};
    }
  }

  @override
  void dispose() {
    _domainController.dispose();
    for (var controller in _additionalParamsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkServerCompatibility() async {
    setState(() {
      _isCheckingCompatibility = true;
    });

    try {
      final provider = context.read<VpnProvider>();
      final server = provider.selectedServer;
      
      if (server != null) {
        final obfuscationService = ObfuscationService();
        _supportedTypes = await obfuscationService.getSupportedObfuscationTypes(
          server.hostname,
        );
      }
    } catch (e) {
      debugPrint('Error checking compatibility: $e');
    } finally {
      setState(() {
        _isCheckingCompatibility = false;
      });
    }
  }

  Future<void> _updateSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<VpnProvider>();
      
      final config = ObfuscationConfig(
        type: _selectedType,
        domain: _domainController.text.trim(),
        isEnabled: _isEnabled,
        additionalParams: Map.fromEntries(
          _additionalParamsControllers.entries.map(
            (e) => MapEntry(e.key, e.value.text),
          ),
        ),
      );

      await provider.configureObfuscation(config);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkHttpStatus() async {
    try {
      setState(() {
        _httpStatus = 'Checking HTTP status...';
      });

      final provider = context.read<VpnProvider>();
      final server = provider.selectedServer;
      
      if (server != null) {
        final result = await http.get(
          Uri.parse('http://${server.hostname}'),
        ).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Connection timed out');
          },
        );
        
        setState(() {
          _httpStatus = 'HTTP Status: ${result.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() {
        _httpStatus = 'HTTP Status: Timeout (Server might be busy)';
      });
    } catch (e) {
      setState(() {
        _httpStatus = 'HTTP Status: Not available';
      });
    }
  }

  Future<void> _applyChanges() async {
    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });

    try {
      await _updateSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes applied successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isApplying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _errorMessage != null 
              ? Colors.red.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Traffic Obfuscation',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                    if (!value) {
                      _selectedType = ObfuscationType.none;
                    }
                  });
                  _updateSettings();
                },
                activeColor: AppColors.accent2,
              ),
            ],
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 16),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildDomainInput(),
            _buildAdvancedSettings(),
          ],
          if (_httpStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _httpStatus!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          Center(
            child: ApplyButton(
              onPressed: _applyChanges,
              isLoading: _isApplying,
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    if (_isCheckingCompatibility) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Simplified obfuscation types
    final availableTypes = [
      ObfuscationType.none,
      ObfuscationType.http,
      ObfuscationType.tls,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Obfuscation Type',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTypes
              .map((type) => _buildTypeOption(
                    type,
                    _getObfuscationLabel(type),
                  ))
              .toList(),
        ),
      ],
    );
  }

  String _getObfuscationLabel(ObfuscationType type) {
    switch (type) {
      case ObfuscationType.none:
        return 'NONE';
      case ObfuscationType.http:
        return 'HTTP';
      case ObfuscationType.tls:
        return 'TLS';
      default:
        return type.toString().split('.').last.toUpperCase();
    }
  }

  Widget _buildTypeOption(ObfuscationType type, String label) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        _updateSettings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent2.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.accent2
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.accent2
                : Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDomainInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Domain',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _domainController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter domain (e.g., example.com)',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.accent2,
              ),
            ),
          ),
          onChanged: (_) => _updateSettings(),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    if (!_isEnabled || _selectedType == ObfuscationType.none) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Advanced Settings',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._buildAdditionalParamsFields(),
      ],
    );
  }

  List<Widget> _buildAdditionalParamsFields() {
    return _additionalParamsControllers.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: entry.value,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: entry.key.toUpperCase(),
            labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
            // ... rest of the decoration properties
          ),
          onChanged: (_) => _updateSettings(),
        ),
      );
    }).toList();
  }
} 