import 'dart:convert';

import 'package:http/http.dart' as http;

import 'kuradesk_chat_theme.dart';

class KuradeskChatMessage {
  KuradeskChatMessage({
    required this.id,
    required this.body,
    required this.direction,
    required this.createdAt,
  });

  final String id;
  final String? body;
  final String direction;
  final DateTime createdAt;

  bool get isFromCustomer => direction == 'INBOUND';

  factory KuradeskChatMessage.fromJson(Map<String, dynamic> json) {
    return KuradeskChatMessage(
      id: json['id'] as String,
      body: json['body'] as String?,
      direction: json['direction'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class KuradeskChatTypingUser {
  KuradeskChatTypingUser({required this.name});

  final String name;

  factory KuradeskChatTypingUser.fromJson(Map<String, dynamic> json) {
    return KuradeskChatTypingUser(name: (json['name'] as String?) ?? 'Support');
  }
}

class KuradeskChatSession {
  KuradeskChatSession({
    required this.accessToken,
    required this.conversationId,
    required this.config,
  });

  final String accessToken;
  final String conversationId;
  final KuradeskChatConfig config;

  String get widgetName => config.name;
  String? get welcomeMessage => config.welcomeMessage;
  String? get primaryColor => config.primaryColor;
}

class KuradeskChatClient {
  KuradeskChatClient({
    required this.apiBaseUrl,
    required this.widgetKey,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiBaseUrl;
  final String widgetKey;
  final http.Client _http;

  String? _token;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

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
    final data = (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return data.map(KuradeskChatMessage.fromJson).toList();
  }

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
    final data = (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return data.map(KuradeskChatTypingUser.fromJson).toList();
  }

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

  void restoreToken(String token) => _token = token;

  void _ensureToken() {
    if (_token == null) {
      throw StateError('Call startSession() first');
    }
  }

  void dispose() => _http.close();
}
