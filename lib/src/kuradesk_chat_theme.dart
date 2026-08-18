import 'package:flutter/material.dart';

class KuradeskChatConfig {
  KuradeskChatConfig({
    required this.name,
    this.welcomeMessage,
    this.primaryColor,
    this.requirePhone = false,
    this.bridgeToWhatsApp = false,
    this.logoUrl,
    this.showPoweredBy = true,
    this.headerTitle,
    this.headerSubtitle,
    this.launcherTitle,
    this.launcherSubtitle,
    this.poweredByText,
  });

  final String name;
  final String? welcomeMessage;
  final String? primaryColor;
  final bool requirePhone;
  final bool bridgeToWhatsApp;
  final String? logoUrl;
  final bool showPoweredBy;
  final String? headerTitle;
  final String? headerSubtitle;
  final String? launcherTitle;
  final String? launcherSubtitle;
  final String? poweredByText;

  factory KuradeskChatConfig.fromJson(Map<String, dynamic> json) {
    return KuradeskChatConfig(
      name: (json['name'] as String?) ?? 'KuraDesk',
      welcomeMessage: json['welcomeMessage'] as String?,
      primaryColor: json['primaryColor'] as String?,
      requirePhone:
          json['requirePhone'] == true || json['bridgeToWhatsApp'] == true,
      bridgeToWhatsApp: json['bridgeToWhatsApp'] == true,
      logoUrl: json['logoUrl'] as String?,
      showPoweredBy: json['showPoweredBy'] != false,
      headerTitle: json['headerTitle'] as String?,
      headerSubtitle: json['headerSubtitle'] as String?,
      launcherTitle: json['launcherTitle'] as String?,
      launcherSubtitle: json['launcherSubtitle'] as String?,
      poweredByText: json['poweredByText'] as String?,
    );
  }
}

class KuradeskChatPalette {
  const KuradeskChatPalette({
    required this.accent,
    required this.accentLight,
    required this.panelTop,
    required this.panelMid,
    required this.panelBottom,
    required this.headerTint,
    required this.headerBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusedBorder,
    required this.focusRing,
    required this.welcomeBackground,
    required this.welcomeBorder,
    required this.agentBubble,
    required this.agentBubbleBorder,
    required this.customerBubbleStart,
    required this.customerBubbleEnd,
    required this.customerText,
    required this.composerBackground,
    required this.composerBorder,
    required this.footerText,
    required this.onlineDot,
    required this.error,
    required this.markBackground,
    required this.launcherBackground,
    required this.hintBackground,
    required this.sendGradientStart,
    required this.sendGradientEnd,
    required this.isDark,
  });

  final Color accent;
  final Color accentLight;
  final Color panelTop;
  final Color panelMid;
  final Color panelBottom;
  final Color headerTint;
  final Color headerBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusedBorder;
  final Color focusRing;
  final Color welcomeBackground;
  final Color welcomeBorder;
  final Color agentBubble;
  final Color agentBubbleBorder;
  final Color customerBubbleStart;
  final Color customerBubbleEnd;
  final Color customerText;
  final Color composerBackground;
  final Color composerBorder;
  final Color footerText;
  final Color onlineDot;
  final Color error;
  final Color markBackground;
  final Color launcherBackground;
  final Color hintBackground;
  final Color sendGradientStart;
  final Color sendGradientEnd;
  final bool isDark;

  static KuradeskChatPalette resolve(
    BuildContext context, {
    String? primaryColorHex,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        _parseHex(primaryColorHex, fallback: const Color(0xFF0D9488));
    final accentLight = Color.lerp(accent, const Color(0xFF5EEAD4), 0.45)!;

    if (isDark) {
      return KuradeskChatPalette(
        accent: accent,
        accentLight: accentLight,
        panelTop: const Color(0xFF121A28),
        panelMid: const Color(0xFF0B1018),
        panelBottom: const Color(0xFF070B12),
        headerTint: accent.withValues(alpha: 0.28),
        headerBorder: Colors.white.withValues(alpha: 0.06),
        textPrimary: const Color(0xFFF4F7FB),
        textSecondary: const Color(0xFF8B97A8),
        inputBackground: const Color(0xFF121826),
        inputBorder: Colors.white.withValues(alpha: 0.08),
        inputFocusedBorder: accent,
        focusRing: accent.withValues(alpha: 0.22),
        welcomeBackground: Colors.white.withValues(alpha: 0.04),
        welcomeBorder: Colors.white.withValues(alpha: 0.06),
        agentBubble: const Color(0xFF162033),
        agentBubbleBorder: Colors.white.withValues(alpha: 0.06),
        customerBubbleStart: const Color(0xFF5EEAD4),
        customerBubbleEnd: accent,
        customerText: const Color(0xFF04110E),
        composerBackground: const Color(0xB8070B12),
        composerBorder: Colors.white.withValues(alpha: 0.06),
        footerText: const Color(0xFF6E7A8A),
        onlineDot: const Color(0xFF34D399),
        error: const Color(0xFFFB7185),
        markBackground: const Color(0xFF070B12),
        launcherBackground: const Color(0xFF070B12),
        hintBackground: const Color(0xFF121A28),
        sendGradientStart: const Color(0xFF34D399),
        sendGradientEnd: accent,
        isDark: true,
      );
    }

    return KuradeskChatPalette(
      accent: accent,
      accentLight: accentLight,
      panelTop: const Color(0xFFF8FAFC),
      panelMid: const Color(0xFFF1F5F9),
      panelBottom: const Color(0xFFE2E8F0),
      headerTint: accent.withValues(alpha: 0.12),
      headerBorder: const Color(0xFFE2E8F0),
      textPrimary: const Color(0xFF0F172A),
      textSecondary: const Color(0xFF64748B),
      inputBackground: Colors.white,
      inputBorder: const Color(0xFFCBD5E1),
      inputFocusedBorder: accent,
      focusRing: accent.withValues(alpha: 0.18),
      welcomeBackground: Colors.white,
      welcomeBorder: const Color(0xFFE2E8F0),
      agentBubble: Colors.white,
      agentBubbleBorder: const Color(0xFFE2E8F0),
      customerBubbleStart: accentLight,
      customerBubbleEnd: accent,
      customerText: const Color(0xFF04110E),
      composerBackground: Colors.white.withValues(alpha: 0.92),
      composerBorder: const Color(0xFFE2E8F0),
      footerText: const Color(0xFF94A3B8),
      onlineDot: const Color(0xFF10B981),
      error: const Color(0xFFE11D48),
      markBackground: Colors.white,
      launcherBackground: const Color(0xFF0F172A),
      hintBackground: Colors.white,
      sendGradientStart: accentLight,
      sendGradientEnd: accent,
      isDark: false,
    );
  }

  LinearGradient get panelGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [panelTop, panelMid, panelBottom],
      );

  LinearGradient get headerGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          headerTint,
          accentLight.withValues(alpha: 0.08),
          Colors.transparent
        ],
      );

  LinearGradient get customerBubbleGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [customerBubbleStart, customerBubbleEnd],
      );

  LinearGradient get sendGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [sendGradientStart, sendGradientEnd],
      );

  static Color _parseHex(String? raw, {required Color fallback}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    var value = raw.trim().replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return fallback;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }
}
