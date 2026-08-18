import 'dart:async';

import 'package:flutter/material.dart';

import 'kuradesk_chat_client.dart';
import 'kuradesk_chat_storage.dart';
import 'kuradesk_chat_theme.dart';

class KuradeskChatView extends StatefulWidget {
  const KuradeskChatView({
    super.key,
    required this.apiBaseUrl,
    required this.widgetKey,
    this.initialPhone,
    this.initialName,
    this.logoUrl,
    this.showCloseButton = false,
    this.onClose,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final String apiBaseUrl;
  final String widgetKey;
  final String? initialPhone;
  final String? initialName;
  final String? logoUrl;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final BorderRadius borderRadius;

  @override
  State<KuradeskChatView> createState() => _KuradeskChatViewState();
}

class _KuradeskChatViewState extends State<KuradeskChatView> {
  late final KuradeskChatClient _client;
  late final KuradeskChatStorage _storage;
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  KuradeskChatConfig? _config;
  KuradeskChatSession? _session;
  List<KuradeskChatMessage> _messages = [];
  List<KuradeskChatTypingUser> _typing = [];
  String? _error;
  bool _busy = false;
  bool _loadingConfig = true;
  Timer? _pollTimer;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _client = KuradeskChatClient(
      apiBaseUrl: widget.apiBaseUrl,
      widgetKey: widget.widgetKey,
    );
    _storage = KuradeskChatStorage(widget.widgetKey);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final savedName = widget.initialName ?? await _storage.readName() ?? '';
    final savedPhone = widget.initialPhone ?? await _storage.readPhone() ?? '';
    if (mounted) {
      _nameCtrl.text = savedName;
      _phoneCtrl.text = savedPhone;
    }
    try {
      final config = await _client.fetchConfig();
      if (mounted) setState(() => _config = config);
    } catch (_) {
      if (mounted) {
        setState(() {
          _config = KuradeskChatConfig(name: 'KuraDesk');
        });
      }
    } finally {
      if (mounted) setState(() => _loadingConfig = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _client.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  KuradeskChatConfig get _branding {
    if (_session != null) return _session!.config;
    return _config ?? KuradeskChatConfig(name: 'KuraDesk');
  }

  String get _logoUrl {
    if (widget.logoUrl != null && widget.logoUrl!.isNotEmpty) {
      return widget.logoUrl!;
    }
    final fromServer = _branding.logoUrl;
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;
    final base = widget.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/kuradesk.png';
  }

  String get _kuradeskLogoUrl {
    final base = widget.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/kuradesk.png';
  }

  String? get _primaryColorHex => _branding.primaryColor;

  bool get _requiresPhone => _branding.requirePhone;

  String get _welcomeText {
    final value = _branding.welcomeMessage;
    if (value != null && value.trim().isNotEmpty) return value.trim();
    if (_requiresPhone) {
      return 'Enter your WhatsApp number to start chatting with support.';
    }
    return 'Hi — drop a message and the team will pick it up here.';
  }

  String get _headerTitle => _branding.headerTitle?.trim().isNotEmpty == true
      ? _branding.headerTitle!.trim()
      : 'Chat with us';

  String get _headerSubtitle =>
      _branding.headerSubtitle?.trim().isNotEmpty == true
          ? _branding.headerSubtitle!.trim()
          : 'Typically replies in minutes';

  bool get _showPoweredBy => true;

  String get _poweredByText => 'Powered by KuraDesk';

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      if (_requiresPhone && !RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone)) {
        throw Exception('Use international format, e.g. +2637…');
      }
      final visitorId = await _storage.readOrCreateVisitorId();
      final session = await _client.startSession(
        phone: phone.isEmpty ? null : phone,
        name: name.isEmpty ? null : name,
        visitorId: visitorId,
      );
      if (name.isNotEmpty) await _storage.writeName(name);
      if (phone.isNotEmpty) await _storage.writePhone(phone);
      _session = session;
      if (mounted) setState(() => _config = session.config);
      await _refresh();
      _startPolling();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
    _typingTimer = Timer.periodic(
        const Duration(milliseconds: 1500), (_) => _refreshTyping());
  }

  Future<void> _refresh() async {
    if (_session == null) return;
    try {
      final list = await _client.listMessages();
      if (!mounted) return;
      setState(() => _messages = list);
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _refreshTyping() async {
    if (_session == null) return;
    try {
      final list = await _client.listTyping();
      if (!mounted) return;
      setState(() => _typing = list);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await _client.sendMessage(text);
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = KuradeskChatPalette.resolve(
      context,
      primaryColorHex: _primaryColorHex,
    );

    if (_loadingConfig) {
      return _PanelShell(
        palette: palette,
        borderRadius: widget.borderRadius,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return _PanelShell(
        palette: palette,
        borderRadius: widget.borderRadius,
        header: _Header(
          palette: palette,
          logoUrl: _logoUrl,
          title: _headerTitle,
          subtitle: _headerSubtitle,
          showClose: widget.showCloseButton,
          onClose: widget.onClose,
        ),
        footer: _showPoweredBy
            ? _PoweredByFooter(
                palette: palette,
                logoUrl: _kuradeskLogoUrl,
                label: _poweredByText,
              )
            : null,
        child: _GateView(
          palette: palette,
          welcomeText: _welcomeText,
          requiresPhone: _requiresPhone,
          nameController: _nameCtrl,
          phoneController: _phoneCtrl,
          error: _error,
          busy: _busy,
          onStart: _start,
        ),
      );
    }

    return _PanelShell(
      palette: palette,
      borderRadius: widget.borderRadius,
      header: _Header(
        palette: palette,
        logoUrl: _logoUrl,
        title: _headerTitle,
        subtitle: _headerSubtitle,
        showClose: widget.showCloseButton,
        onClose: widget.onClose,
      ),
      footer: _showPoweredBy
          ? _PoweredByFooter(
              palette: palette,
              logoUrl: _kuradeskLogoUrl,
              label: _poweredByText,
            )
          : null,
      composer: _Composer(
        palette: palette,
        controller: _msgCtrl,
        onSend: _send,
      ),
      typing:
          _typing.isEmpty ? null : _TypingBar(palette: palette, users: _typing),
      child: _MessageList(
        palette: palette,
        messages: _messages,
        welcomeText: _welcomeText,
        scrollController: _scrollCtrl,
        error: _error,
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.palette,
    required this.borderRadius,
    required this.child,
    this.header,
    this.footer,
    this.composer,
    this.typing,
  });

  final KuradeskChatPalette palette;
  final BorderRadius borderRadius;
  final Widget child;
  final Widget? header;
  final Widget? footer;
  final Widget? composer;
  final Widget? typing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: palette.panelGradient,
          border: Border.all(
            color: palette.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : palette.headerBorder,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: palette.isDark ? 0.45 : 0.12),
              blurRadius: palette.isDark ? 40 : 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              if (header != null) header!,
              Expanded(child: child),
              if (typing != null) typing!,
              if (composer != null) composer!,
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    required this.logoUrl,
    required this.title,
    required this.subtitle,
    required this.showClose,
    this.onClose,
  });

  final KuradeskChatPalette palette;
  final String logoUrl;
  final String title;
  final String subtitle;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: palette.headerGradient,
        border: Border(bottom: BorderSide(color: palette.headerBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
        child: Row(
          children: [
            _BrandMark(palette: palette, logoUrl: logoUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: palette.onlineDot,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.onlineDot.withValues(alpha: 0.8),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showClose)
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: palette.textSecondary),
                style: IconButton.styleFrom(
                  backgroundColor: palette.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
                  minimumSize: const Size(32, 32),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.palette,
    required this.logoUrl,
    this.size = 48,
  });

  final KuradeskChatPalette palette;
  final String logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.markBackground,
        borderRadius: BorderRadius.circular(size * 0.33),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : palette.headerBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.support_agent_rounded,
            color: palette.accent,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _GateView extends StatelessWidget {
  const _GateView({
    required this.palette,
    required this.welcomeText,
    required this.requiresPhone,
    required this.nameController,
    required this.phoneController,
    required this.error,
    required this.busy,
    required this.onStart,
  });

  final KuradeskChatPalette palette;
  final String welcomeText;
  final bool requiresPhone;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String? error;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WelcomeCard(palette: palette, text: welcomeText),
        const SizedBox(height: 12),
        _FieldLabel(palette: palette, label: 'Your name'),
        const SizedBox(height: 6),
        _StyledField(
          palette: palette,
          controller: nameController,
          hintText: 'Jane',
          textInputAction: TextInputAction.next,
        ),
        if (requiresPhone) ...[
          const SizedBox(height: 12),
          _FieldLabel(palette: palette, label: 'WhatsApp number'),
          const SizedBox(height: 6),
          _StyledField(
            palette: palette,
            controller: phoneController,
            hintText: '+2637…',
            keyboardType: TextInputType.phone,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: TextStyle(color: palette.error, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        _PrimaryButton(
          palette: palette,
          label: busy ? 'Starting…' : 'Start conversation',
          onPressed: busy ? null : onStart,
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.palette,
    required this.messages,
    required this.welcomeText,
    required this.scrollController,
    this.error,
  });

  final KuradeskChatPalette palette;
  final List<KuradeskChatMessage> messages;
  final String welcomeText;
  final ScrollController scrollController;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          if (welcomeText.isNotEmpty)
            _WelcomeCard(palette: palette, text: welcomeText),
          const SizedBox(height: 24),
          Column(
            children: [
              Text(
                "You're in",
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Send a message below to start chatting with support. We typically reply in a few minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error!, style: TextStyle(color: palette.error, fontSize: 12)),
          ],
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final message = messages[index];
        return _MessageBubble(palette: palette, message: message);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.palette, required this.message});

  final KuradeskChatPalette palette;
  final KuradeskChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isFromCustomer;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          gradient: mine ? palette.customerBubbleGradient : null,
          color: mine ? null : palette.agentBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 6),
            bottomRight: Radius.circular(mine ? 6 : 16),
          ),
          border: mine ? null : Border.all(color: palette.agentBubbleBorder),
        ),
        child: Text(
          message.body ?? '',
          style: TextStyle(
            color: mine ? palette.customerText : palette.textPrimary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _TypingBar extends StatelessWidget {
  const _TypingBar({required this.palette, required this.users});

  final KuradeskChatPalette palette;
  final List<KuradeskChatTypingUser> users;

  String _label() {
    final names =
        users.map((u) => u.name.trim().split(RegExp(r'\s+')).first).toList();
    if (names.length == 1) return '${names.first} is typing…';
    if (names.length == 2) return '${names.first} and ${names[1]} are typing…';
    return '${names.first} and ${names.length - 1} others are typing…';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _TypingDots(color: palette.onlineDot),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _label(),
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final phase = (_controller.value + index * 0.15) % 1.0;
              final active = phase > 0.2 && phase < 0.6;
              return Transform.translate(
                offset: Offset(0, active ? -3 : 0),
                child: Opacity(
                  opacity: active ? 1 : 0.25,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.palette,
    required this.controller,
    required this.onSend,
  });

  final KuradeskChatPalette palette;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.composerBackground,
        border: Border(top: BorderSide(color: palette.composerBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _StyledField(
                  palette: palette,
                  controller: controller,
                  hintText: 'Write a message…',
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: palette.sendGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSend,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF04110E),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoweredByFooter extends StatelessWidget {
  const _PoweredByFooter({
    required this.palette,
    required this.logoUrl,
    required this.label,
  });

  final KuradeskChatPalette palette;
  final String logoUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            logoUrl,
            width: 14,
            height: 14,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.circle, size: 10, color: palette.footerText),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.footerText,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.palette, required this.text});

  final KuradeskChatPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.welcomeBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(6),
        ),
        border: Border.all(color: palette.welcomeBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: palette.isDark ? const Color(0xFFD7DEE8) : palette.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.palette, required this.label});

  final KuradeskChatPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.palette,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final KuradeskChatPalette palette;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(color: palette.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: palette.textSecondary),
        filled: true,
        fillColor: palette.inputBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.inputFocusedBorder, width: 1.2),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.palette,
    required this.label,
    required this.onPressed,
  });

  final KuradeskChatPalette palette;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: palette.sendGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Opacity(
            opacity: onPressed == null ? 0.55 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF04110E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
