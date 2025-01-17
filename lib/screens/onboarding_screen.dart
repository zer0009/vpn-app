import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Secure & Private',
      description: 'Browse the internet safely and privately with our VPN service',
      image: 'assets/images/onboarding_security.png',
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Lightning Fast',
      description: 'Experience high-speed connections with servers worldwide',
      image: 'assets/images/onboarding_speed.png',
      color: AppColors.accent1,
    ),
    OnboardingPage(
      title: 'Unlimited Access',
      description: 'Access any content from anywhere in the world',
      image: 'assets/images/onboarding_access.png',
      color: AppColors.accent2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDotIndicator(index),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _currentPage == _pages.length - 1
                      ? _buildGetStartedButton()
                      : _buildNextButton(),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () => _navigateToHome(),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: page.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForPage(page.title),
            size: 80,
            color: page.color,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          page.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForPage(String title) {
    switch (title) {
      case 'Secure & Private':
        return Icons.security;
      case 'Lightning Fast':
        return Icons.speed;
      case 'Unlimited Access':
        return Icons.public;
      default:
        return Icons.vpn_lock;
    }
  }

  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _pages[_currentPage].color
            : _pages[_currentPage].color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _pages[_currentPage].color,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Next',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: _navigateToHome,
      style: ElevatedButton.styleFrom(
        backgroundColor: _pages[_currentPage].color,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Started',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
} 