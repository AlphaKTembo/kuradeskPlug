import 'package:shared_preferences/shared_preferences.dart';

/// Persists visitor details between sessions, namespaced per widget key.
class KuradeskChatStorage {
  /// Creates storage scoped to [_widgetKey].
  KuradeskChatStorage(this._widgetKey);

  final String _widgetKey;

  String get _prefix => 'kd_chat_${_widgetKey}_';

  /// Returns the saved visitor name, or `null` if none was stored.
  Future<String?> readName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefix}name');
  }

  /// Saves the visitor name.
  Future<void> writeName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}name', value);
  }

  /// Returns the saved phone number, or `null` if none was stored.
  Future<String?> readPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefix}phone');
  }

  /// Saves the phone number.
  Future<void> writePhone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}phone', value);
  }

  /// Returns a stable anonymous visitor id, generating one on first use.
  Future<String> readOrCreateVisitorId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('${_prefix}visitor');
    if (existing != null && existing.length >= 8) return existing;
    final created =
        'flutter_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
    await prefs.setString('${_prefix}visitor', created);
    return created;
  }
}
