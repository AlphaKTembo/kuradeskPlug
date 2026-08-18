import 'dart:convert';

import 'package:http/http.dart' as http;

import 'kuradesk_chat_theme.dart';

/// A single message in a KuraDesk conversation.
class KuradeskChatMessage {
  /// Creates a message.
  KuradeskChatMessage({
    required this.id,
    required this.body,
    required this.direction,
    required this.createdAt,
  });

  /// Server-assigned unique identifier.
  final String id;

  /// Text content, or `null` for messages without a text body.
  final String? body;

  /// Either `INBOUND` (sent by the customer) or `OUTBOUND` (sent by an agent).
  final String direction;

  /// When the message was created, as reported by the server.
  final DateTime createdAt;

  /// Whether this message was sent by the customer rather than an agent.
  bool get isFromCustomer => direction == 'INBOUND';

  /// Creates a message from a decoded JSON object.
  factory KuradeskChatMessage.fromJson(Map<String, dynamic> json) {
    return KuradeskChatMessage(
      id: json['id'] as String,
      body: json['body'] as String?,
      direction: json['direction'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// An agent currently typing a reply.
class KuradeskChatTypingUser {
  /// Creates a typing indicator entry.
  KuradeskChatTypingUser({required this.name});

  /// Display name of the agent, defaulting to `Support`.
  final String name;

  /// Creates a typing indicator entry from a decoded JSON object.
  factory KuradeskChatTypingUser.fromJson(Map<String, dynamic> json) {
    return KuradeskChatTypingUser(name: (json['name'] as String?) ?? 'Support');
  }
}

/// An authenticated chat session returned by [KuradeskChatClient.startSession].
class KuradeskChatSession {
  /// Creates a session.
  KuradeskChatSession({
    required this.accessToken,
    required this.conversationId,
    required this.config,
  });

  /// Bearer token used to authorize subsequent message requests.
  final String accessToken;

  /// Identifier of the conversation this session is bound to.
  final String conversationId;

  /// Branding and behaviour configuration for the widget.
  final KuradeskChatConfig config;

  /// Display name of the widget, from [config].
  String get widgetName => config.name;

  /// Greeting shown before the first message, from [config].
  String? get welcomeMessage => config.welcomeMessage;

  /// Accent color as a hex string, from [config].
  String? get primaryColor => config.primaryColor;
}

/// HTTP client for the KuraDesk chat plugin API.
///
/// Call [startSession] before [listMessages], [listTyping] or [sendMessage];
/// those methods throw a [StateError] without a session token. Call [dispose]
/// when finished to release the underlying HTTP client.
class KuradeskChatClient {
  /// Creates a client targeting [apiBaseUrl] for the widget [widgetKey].
  ///
  /// Pass [httpClient] to supply your own transport, e.g. in tests.
  KuradeskChatClient({
    required this.apiBaseUrl,
    required this.widgetKey,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Root URL of the KuraDesk deployment, without a trailing slash.
  final String apiBaseUrl;

  /// Public widget key from KuraDesk settings.
  final String widgetKey;
  final http.Client _http;

  String? _token;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  /// Fetches server-driven branding for [widgetKey].
  ///
  /// Throws an [Exception] if the server rejects the request.
  Future<KuradeskChatConfig> fetchConfig() async {
    final res = await _http.get(
      _uri('/api/plugin/v1/config/${Uri.encodeComponent(widgetKey)}'),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Failed to load widget config');
    }
    return KuradeskChatConfig.fromJson(body);
  }

  /// Opens a conversation and stores the returned access token.
  ///
  /// Supply [phone] when the widget requires a phone number; otherwise a
  /// [visitorId] is used to identify the anonymous visitor. [name] is optional
  /// and shown to agents. Throws an [Exception] if the server rejects the
  /// request.
  Future<KuradeskChatSession> startSession({
    String? phone,
    String? name,
    String? visitorId,
  }) async {
    final payload = <String, dynamic>{
      'widgetKey': widgetKey,
      if (name != null && name.isNotEmpty) 'name': name,
    };
    if (phone != null && phone.isNotEmpty) {
      payload['phone'] = phone;
    } else {
      payload['visitorId'] =
          visitorId ?? 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    }
    final res = await _http.post(
      _uri('/api/plugin/v1/session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Failed to start session');
    }
    _token = body['accessToken'] as String;
    final widget = (body['widget'] as Map<String, dynamic>?) ?? {};
    return KuradeskChatSession(
      accessToken: _token!,
      conversationId: body['conversationId'] as String,
      config: KuradeskChatConfig.fromJson(widget),
    );
  }

  /// Loads up to [limit] recent messages for the active session.
  Future<List<KuradeskChatMessage>> listMessages({int limit = 50}) async {
    _ensureToken();
    final res = await _http.get(
      _uri('/api/plugin/v1/messages', {'limit': '$limit'}),
      headers: {'Authorization': 'Bearer $_token'},
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Failed to load messages');
    }
    final data =
        (body['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return data.map(KuradeskChatMessage.fromJson).toList();
  }

  /// Returns agents currently typing, or an empty list on failure.
  Future<List<KuradeskChatTypingUser>> listTyping() async {
    _ensureToken();
    final res = await _http.get(
      _uri('/api/plugin/v1/typing'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      return const [];
    }
    final data =
        (body['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return data.map(KuradeskChatTypingUser.fromJson).toList();
  }

  /// Sends [text] to the conversation and returns the created message.
  Future<KuradeskChatMessage> sendMessage(String text) async {
    _ensureToken();
    final res = await _http.post(
      _uri('/api/plugin/v1/messages'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'body': text,
        'clientMessageId': 'flutter_${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Failed to send');
    }
    return KuradeskChatMessage.fromJson(body);
  }

  /// Reuses a previously issued [token] instead of starting a new session.
  void restoreToken(String token) => _token = token;

  void _ensureToken() {
    if (_token == null) {
      throw StateError('Call startSession() first');
    }
  }

  /// Closes the underlying HTTP client.
  void dispose() => _http.close();
}
