import 'package:flutter/material.dart';

/// Model Bank Design & Color Coding System.
class BankColors {
  BankColors._();

  /// Vibrant Chartreuse / Lime Green - accent tone
  static const Color limeGreen = Color(0xFFA6D92A);

  /// Mid Lime - rich transition tone in the gradient
  static const Color midLime = Color(0xFF6CBD35);

  /// Dark Lime - deep primary brand tone
  static const Color darkLime = Color(0xFF388022);

  /// Deep Forest Lime - high-contrast text and border tone
  static const Color deepLime = Color(0xFF235F18);

  /// Light Lime Tint - background tint for active tiles, cards, tags, banners
  static const Color limeLight = Color(0xFFF2F9EC);

  /// Primary Ocean Blue - hallmark blue for secondary accents
  static const Color oceanBlue = Color(0xFF1678B9);

  /// Deep Navy Blue - corporate navy
  static const Color deepNavy = Color(0xFF0C4D78);

  /// Deep Midnight Navy Blue - prestigious color for banner & cards
  static const Color bannerNavy = Color(0xFF0C2B48);

  /// Bright Ocean / Sky Blue
  static const Color brightBlue = Color(0xFF1A90E7);

  /// Marine Teal - transition tone between lime green and ocean blue
  static const Color marineTeal = Color(0xFF148A96);

  /// Light Ice Blue / Tint
  static const Color iceBlueLight = Color(0xFFEBF5FB);

  /// Subtle Ice Blue
  static const Color iceBlueSubtle = Color(0xFFF2F8FC);

  /// Refined Light Ocean Blue Palette for Dashboard Cards & Banners
  static const Color lightOceanStart = Color(0xFFEBF6FC);
  static const Color lightOceanEnd = Color(0xFFDAEEFB);
  static const Color lightOceanBorder = Color(0xFFBCE0F7);
  static const Color oceanNavyText = Color(0xFF0B2942);
  static const Color oceanSlateText = Color(0xFF4C6E88);

  /// Light Ocean Blue subtle gradient for dashboard cards
  static const LinearGradient lightOceanGradient = LinearGradient(
    colors: [lightOceanStart, lightOceanEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Clean White Background - default background for all screens
  static const Color background = Color(0xFFF7F9FC);

  /// Modern FinTech Mockup Palette Tokens
  static const Color fintechBg = Color(0xFFF7F9FC);
  static const Color fintechCardLime = Color(0xFF4BD877);
  static const Color fintechCardBlue = Color(0xFF1B8DEB);

  /// Hero Balance Card Signature Gradient: Fresh Lime Green -> Ocean Cyan Blue
  static const LinearGradient fintechHeroGradient = LinearGradient(
    colors: [Color(0xFF4BD877), Color(0xFF1B8DEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Green 3D Card Gradient
  static const LinearGradient fintechGreenCardGradient = LinearGradient(
    colors: [Color(0xFF8ED83F), Color(0xFF67BD2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Blue 3D Card Gradient
  static const LinearGradient fintechBlueCardGradient = LinearGradient(
    colors: [Color(0xFF2B82EA), Color(0xFF166ACC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Modern Typography Colors
  static const Color fintechTextPrimary = Color(0xFF0F172A);
  static const Color fintechTextSecondary = Color(0xFF64748B);
  static const Color fintechTextMuted = Color(0xFF94A3B8);
  static const Color fintechPillGreen = Color(0xFF389B48);

  /// FinTech Ambient Box Shadow for Cards
  static const BoxShadow fintechShadow = BoxShadow(
    color: Color(0x0C000000),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  /// Pure White Surface - for elevated cards and sheets
  static const Color surface = Colors.white;

  /// Secondary / Muted Text - for subtitles, captions, descriptions
  static const Color textMuted = Color(0xFF5A7260);

  /// Primary Dark Text - for titles and body text
  static const Color textDark = Color(0xFF142E18);

  /// Border Color - subtle outline for cards and inputs
  static const Color border = Color(0xFFDCEAD8);

  // Backward-compatible aliases
  static const Color primaryTeal = darkLime;
  static const Color deepTeal = deepLime;
  static const Color vibrantCyan = oceanBlue;
  static const Color mintLight = limeLight;

  /// Signature Lime to Dark Lime Gradient (Header, Banner)
  static const LinearGradient limeGradient = LinearGradient(
    colors: [
      Color(0xFFA6D92A),
      Color(0xFF6CBD35),
      Color(0xFF388022),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Primary Header & Banner Gradient: Lime to Dark Lime
  static const LinearGradient primaryGradient = limeGradient;

  /// Spectrum Gradient: Lime Green -> Marine Teal -> Royal Ocean Blue
  static const LinearGradient posterGradient = LinearGradient(
    colors: [limeGreen, marineTeal, oceanBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ocean to Sky Blue Gradient
  static const LinearGradient blueToSkyGradient = LinearGradient(
    colors: [oceanBlue, brightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Teal to Cyan Gradient
  static const LinearGradient tealToCyanGradient = LinearGradient(
    colors: [marineTeal, oceanBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Brand Mark Gradient: Cyan to Lime Green
  static const LinearGradient cyanToLimeGradient = LinearGradient(
    colors: [brightBlue, limeGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

typedef CbdColors = BankColors;
