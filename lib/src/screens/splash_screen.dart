import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/cbd_colors.dart';
import '../theme/smooth_page_route.dart';
import 'model_bank_gateway_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      _navigateToGateway();
    });
  }

  void _navigateToGateway() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      SmoothPageRoute(
        page: const ModelBankGatewayScreen(),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CbdColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Model Bank Emblem
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: BankColors.bannerNavy,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: BankColors.limeGreen,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // App Title
                const Text(
                  'Model Bank Gateway',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: BankColors.bannerNavy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Open Finance AE • OAuth Authorization Gateway',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: CbdColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 44),
                // Loading spinner in CBD Teal
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(CbdColors.darkLime),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
