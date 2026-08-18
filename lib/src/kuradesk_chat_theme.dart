import 'package:flutter/material.dart';

/// Server-driven branding and behaviour for a chat widget.
///
/// Fetched from `GET /api/plugin/v1/config/:widgetKey` so appearance can be
/// changed in KuraDesk without rebuilding the app.
class KuradeskChatConfig {
  /// Creates a configuration.
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

  /// Widget name, defaulting to `KuraDesk`.
  final String name;

  /// Greeting shown above the first message.
  final String? welcomeMessage;

  /// Accent color as a hex string, e.g. `#0D9488`.
  final String? primaryColor;

  /// Whether a phone number is required before starting a conversation.
  final bool requirePhone;

  /// Whether replies are bridged to WhatsApp, which implies [requirePhone].
  final bool bridgeToWhatsApp;

  /// Logo shown in the header and launcher button.
  final String? logoUrl;

  /// Whether to show the "Powered by KuraDesk" footer.
  final bool showPoweredBy;

  /// Header title, defaulting to `Chat with us`.
  final String? headerTitle;

  /// Header subtitle, defaulting to a typical reply time.
  final String? headerSubtitle;

  /// Title of the launcher hint bubble.
  final String? launcherTitle;

  /// Subtitle of the launcher hint bubble.
  final String? launcherSubtitle;

  /// Overrides the default footer label.
  final String? poweredByText;

  /// Creates a configuration from a decoded JSON object, applying defaults for
  /// missing fields.
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

/// Resolved colors for the chat UI.
///
/// Obtain one with [resolve], which adapts to the ambient [Brightness] and the
/// widget's accent color.
class KuradeskChatPalette {
  /// Creates a palette with explicit colors.
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

  /// Primary accent color.
  final Color accent;

  /// Lighter accent used for highlights and gradients.
  final Color accentLight;

  /// Top color of the panel background gradient.
  final Color panelTop;

  /// Middle color of the panel background gradient.
  final Color panelMid;

  /// Bottom color of the panel background gradient.
  final Color panelBottom;

  /// Accent wash behind the header.
  final Color headerTint;

  /// Divider below the header and around the panel.
  final Color headerBorder;

  /// Color for titles and message text.
  final Color textPrimary;

  /// Color for subtitles and hints.
  final Color textSecondary;

  /// Fill color of text fields.
  final Color inputBackground;

  /// Border of unfocused text fields.
  final Color inputBorder;

  /// Border of focused text fields.
  final Color inputFocusedBorder;

  /// Glow drawn around a focused field.
  final Color focusRing;

  /// Background of the welcome card.
  final Color welcomeBackground;

  /// Border of the welcome card.
  final Color welcomeBorder;

  /// Background of agent message bubbles.
  final Color agentBubble;

  /// Border of agent message bubbles.
  final Color agentBubbleBorder;

  /// Start color of the customer bubble gradient.
  final Color customerBubbleStart;

  /// End color of the customer bubble gradient.
  final Color customerBubbleEnd;

  /// Text color inside customer bubbles.
  final Color customerText;

  /// Background of the message composer.
  final Color composerBackground;

  /// Divider above the message composer.
  final Color composerBorder;

  /// Color of the footer label.
  final Color footerText;

  /// Color of the online status dot.
  final Color onlineDot;

  /// Color used for error messages.
  final Color error;

  /// Background behind the logo mark.
  final Color markBackground;

  /// Background of the floating launcher button.
  final Color launcherBackground;

  /// Background of the launcher hint bubble.
  final Color hintBackground;

  /// Start color of the send button gradient.
  final Color sendGradientStart;

  /// End color of the send button gradient.
  final Color sendGradientEnd;

  /// Whether this palette was built for a dark theme.
  final bool isDark;

  /// Builds a palette for the current theme.
  ///
  /// Follows the ambient [Brightness] from [context] and derives accents from
  /// [primaryColorHex], falling back to teal when it is null or malformed.
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

  /// Vertical gradient painted behind the whole panel.
  LinearGradient get panelGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [panelTop, panelMid, panelBottom],
      );

  /// Accent wash painted behind the header.
  LinearGradient get headerGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          headerTint,
          accentLight.withValues(alpha: 0.08),
          Colors.transparent
        ],
      );

  /// Gradient filling the customer's own message bubbles.
  LinearGradient get customerBubbleGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [customerBubbleStart, customerBubbleEnd],
      );

  /// Gradient used for the send button and other primary actions.
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
