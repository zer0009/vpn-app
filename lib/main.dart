import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/vpn_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'constants/app_colors.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VpnProvider(),
      child: MaterialApp(
        title: 'VPN Shield',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        home: const OnboardingWrapper(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time') ?? true;
    
    if (mounted) {
      setState(() {
        _showOnboarding = isFirstTime;
      });
    }

    if (isFirstTime) {
      await prefs.setBool('first_time', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showOnboarding ? const OnboardingScreen() : const SplashScreen();
  }
}