import 'package:flutter/material.dart';

import 'kuradesk_chat_client.dart';
import 'kuradesk_chat_theme.dart';
import 'kuradesk_chat_view.dart';

/// Floating launcher + chat panel, similar to the web embed.
class KuradeskChatLauncher extends StatefulWidget {
  const KuradeskChatLauncher({
    super.key,
    required this.child,
    required this.apiBaseUrl,
    required this.widgetKey,
    this.logoUrl,
    this.initialPhone,
    this.initialName,
    this.panelWidth = 392,
    this.panelHeight = 620,
  });

  final Widget child;
  final String apiBaseUrl;
  final String widgetKey;
  final String? logoUrl;
  final String? initialPhone;
  final String? initialName;
  final double panelWidth;
  final double panelHeight;

  @override
  State<KuradeskChatLauncher> createState() => _KuradeskChatLauncherState();
}

class _KuradeskChatLauncherState extends State<KuradeskChatLauncher>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _pulse;
  late final KuradeskChatClient _client;
  KuradeskChatConfig? _config;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _client = KuradeskChatClient(
      apiBaseUrl: widget.apiBaseUrl,
      widgetKey: widget.widgetKey,
    );
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _client.fetchConfig();
      if (mounted) setState(() => _config = config);
    } catch (_) {
      if (mounted)
        setState(() => _config = KuradeskChatConfig(name: 'KuraDesk'));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _client.dispose();
    super.dispose();
  }

  String get _logoUrl {
    if (widget.logoUrl != null && widget.logoUrl!.isNotEmpty) {
      return widget.logoUrl!;
    }
    final fromServer = _config?.logoUrl;
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;
    final base = widget.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/kuradesk.png';
  }

  String get _launcherTitle => _config?.launcherTitle?.trim().isNotEmpty == true
      ? _config!.launcherTitle!.trim()
      : 'Chat with us';

  String get _launcherSubtitle =>
      _config?.launcherSubtitle?.trim().isNotEmpty == true
          ? _config!.launcherSubtitle!.trim()
          : 'We typically reply in minutes';

  @override
  Widget build(BuildContext context) {
    final palette = KuradeskChatPalette.resolve(
      context,
      primaryColorHex: _config?.primaryColor,
    );
    final media = MediaQuery.sizeOf(context);
    final panelWidth =
        widget.panelWidth.clamp(280, media.width - 24).toDouble();
    final panelHeight =
        widget.panelHeight.clamp(420, media.height - 120).toDouble();

    return Stack(
      children: [
        widget.child,
        if (!_open)
          Positioned(
            right: 20,
            bottom: 102,
            child: _HintBubble(
              palette: palette,
              title: _launcherTitle,
              subtitle: _launcherSubtitle,
              onTap: () => setState(() => _open = true),
            ),
          ),
        if (_open)
          Positioned(
            right: 20,
            bottom: 92,
            width: panelWidth,
            height: panelHeight,
            child: KuradeskChatView(
              apiBaseUrl: widget.apiBaseUrl,
              widgetKey: widget.widgetKey,
              logoUrl: widget.logoUrl,
              initialPhone: widget.initialPhone,
              initialName: widget.initialName,
              showCloseButton: true,
              onClose: () => setState(() => _open = false),
            ),
          ),
        Positioned(
          right: 20,
          bottom: 20,
          child: _LauncherButton(
            palette: palette,
            logoUrl: _logoUrl,
            open: _open,
            pulse: _pulse,
            onTap: () => setState(() => _open = !_open),
          ),
        ),
      ],
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final KuradeskChatPalette palette;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(6),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.hintBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(6),
            ),
            border: Border.all(
              color: palette.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : palette.headerBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: palette.isDark ? 0.32 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: palette.sendGradient,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 14,
                    color: Color(0xFF04110E),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LauncherButton extends StatelessWidget {
  const _LauncherButton({
    required this.palette,
    required this.logoUrl,
    required this.open,
    required this.pulse,
    required this.onTap,
  });

  final KuradeskChatPalette palette;
  final String logoUrl;
  final bool open;
  final AnimationController pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!open)
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) {
                final scale = 0.92 + pulse.value * 0.26;
                final opacity = (1 - pulse.value) * 0.6;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.accentLight.withValues(alpha: opacity),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          Material(
            color: palette.launcherBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            elevation: 8,
            shadowColor: palette.accent.withValues(alpha: 0.32),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 68,
                height: 68,
                child: open
                    ? Icon(Icons.close_rounded, color: palette.textPrimary)
                    : Padding(
                        padding: const EdgeInsets.all(13),
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.support_agent_rounded,
                            color: palette.accentLight,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
