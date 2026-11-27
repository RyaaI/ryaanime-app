import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TempestStore {
  static const String _usersKey = 'ryaanime_users_v2';
  static const String _activeUserKey = 'ryaanime_active_user_v2';
  static const String _specialCodeHash = '9d51dda51a985c123f8fcd34f5b3581ac6a740df5965817feb12adf7524a8d6a';
  static const String exclusiveTitle = 'MilimNava';
  static const String exclusiveBorderId = 'Milim Starlight Wing';
  static const String exclusiveCommentBgId = 'Abyssal Gaze';
  static const List<String> specialCodeTitles = [exclusiveTitle];

  static String hashText(String raw) => sha256.convert(utf8.encode(raw.trim())).toString();
  static bool verifySpecialCode(String code) => code.trim().isNotEmpty && hashText(code.trim()) == _specialCodeHash;

  static Future<Map<String, dynamic>> _loadUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    try { final d = jsonDecode(raw); if (d is Map<String, dynamic>) return d; } catch (_) {}
    return {};
  }

  static Future<void> _saveUsers(SharedPreferences prefs, Map<String, dynamic> users) async =>
      prefs.setString(_usersKey, jsonEncode(users));

  static Future<Map<String, dynamic>?> getActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final k = prefs.getString(_activeUserKey);
    if (k == null || k.isEmpty) return null;
    final raw = (await _loadUsers(prefs))[k];
    return raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : null;
  }

  static Future<String?> register({required String username, required String password, String specialCode = ''}) async {
    final u = username.trim(), p = password.trim();
    if (u.length < 3) return 'Username minimal 3 karakter.';
    if (p.length < 4) return 'Password minimal 4 karakter.';
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    final key = u.toLowerCase();
    if (users.containsKey(key)) return 'Username "$u" sudah terdaftar. Silakan login.';
    final hasSpecial = verifySpecialCode(specialCode);
    final data = <String, dynamic>{
      'username': u, 'passHash': hashText(p), 'hasSpecialCode': hasSpecial, 'exp': 0, 'avatarPath': '',
      'activeBorder': hasSpecial ? exclusiveBorderId : 'Slime Cyan',
      'activeCommentBg': hasSpecial ? exclusiveCommentBgId : 'Tempest Cyan',
      'unlockedBorders': <String>['Slime Cyan', if (hasSpecial) exclusiveBorderId],
      'unlockedCommentBgs': <String>['Tempest Cyan', if (hasSpecial) exclusiveCommentBgId],
    };
    users[key] = data;
    await _saveUsers(prefs, users);
    await prefs.setString(_activeUserKey, key);
    await _syncLegacyPrefs(prefs, data);
    return null;
  }

  static Future<String?> login({required String username, required String password, String specialCode = ''}) async {
    final u = username.trim(), p = password.trim();
    if (u.isEmpty || p.isEmpty) return 'Masukkan username dan password.';
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    final key = u.toLowerCase();
    final raw = users[key];
    if (raw is! Map<String, dynamic>) return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
    final rec = Map<String, dynamic>.from(raw);
    if (rec['passHash'] != hashText(p)) return 'Password salah.';
    if (verifySpecialCode(specialCode)) {
      rec['hasSpecialCode'] = true;
      rec['activeBorder'] = exclusiveBorderId;
      rec['activeCommentBg'] = exclusiveCommentBgId;
    }
    users[key] = rec;
    await _saveUsers(prefs, users);
    await prefs.setString(_activeUserKey, key);
    await _syncLegacyPrefs(prefs, rec);
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserKey);
    await prefs.remove('username');
    await prefs.remove('has_special_code');
  }

  static Future<void> updateActiveUser(Map<String, dynamic> updated) async {
    final prefs = await SharedPreferences.getInstance();
    final k = prefs.getString(_activeUserKey);
    if (k == null || k.isEmpty) return;
    final users = await _loadUsers(prefs);
    users[k] = updated;
    await _saveUsers(prefs, users);
    await _syncLegacyPrefs(prefs, updated);
  }

  static Future<void> _syncLegacyPrefs(SharedPreferences prefs, Map<String, dynamic> u) async {
    final sp = u['hasSpecialCode'] == true;
    await prefs.setString('username', (u['username'] ?? 'Warga Tempest').toString());
    await prefs.setBool('has_special_code', sp);
    await prefs.setInt('exp', (u['exp'] as int?) ?? 0);
    await prefs.setString('active_border', (u['activeBorder'] ?? (sp ? exclusiveBorderId : 'Slime Cyan')).toString());
    await prefs.setString('active_comment_bg', (u['activeCommentBg'] ?? (sp ? exclusiveCommentBgId : 'Tempest Cyan')).toString());
  }

  static int levelFromExp(int exp) => exp < 0 ? 1 : (exp ~/ 100) + 1;
  static double progressInCurrentLevel(int exp) => exp < 0 ? 0.0 : (exp % 100) / 100.0;
  static String autoTitleFromLevel(int level, {bool preferSpecial = false}) =>
      preferSpecial ? exclusiveTitle : (level >= 50 ? 'Awakened Demon Lord' : level >= 10 ? 'Kijin Commander' : 'Slime of Jura');
}
