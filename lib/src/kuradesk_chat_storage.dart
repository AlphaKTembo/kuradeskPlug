import 'package:shared_preferences/shared_preferences.dart';

class KuradeskChatStorage {
  KuradeskChatStorage(this._widgetKey);

  final String _widgetKey;

  String get _prefix => 'kd_chat_${_widgetKey}_';

  Future<String?> readName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefix}name');
  }

  Future<void> writeName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}name', value);
  }

  Future<String?> readPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefix}phone');
  }

  Future<void> writePhone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}phone', value);
  }

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
