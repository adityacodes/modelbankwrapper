import 'package:flutter/material.dart';

import 'src/model_bank/model_bank_gateway_service.dart';
import 'src/screens/splash_screen.dart';
import 'src/theme/cbd_colors.dart';
import 'src/theme/smooth_page_route.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ModelBankGatewayService().init();
  runApp(const ModelBankGatewayApp());
}

class ModelBankGatewayApp extends StatelessWidget {
  const ModelBankGatewayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Model Bank Gateway',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: CbdColors.background,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SmoothPageTransitionsBuilder(),
            TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
            TargetPlatform.windows: SmoothPageTransitionsBuilder(),
            TargetPlatform.linux: SmoothPageTransitionsBuilder(),
            TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
            TargetPlatform.fuchsia: SmoothPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: CbdColors.darkLime,
          primary: CbdColors.darkLime,
          secondary: CbdColors.limeGreen,
          tertiary: CbdColors.oceanBlue,
          surface: CbdColors.surface,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: CbdColors.darkLime,
          foregroundColor: Colors.white,
          elevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: CbdColors.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: CbdColors.border, width: 0.8),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
