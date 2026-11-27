import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TempestStore {
  static const String _usersKey = 'ryaanime_users_v2';
  static const String _activeUserKey = 'ryaanime_active_user_v2';

  // Ganti hash SHA-256 ini sesuai kode khusus versimu bila perlu
  static const String _specialCodeHash =
      '5e585855e1deef5d0cf7ec5351a2e25852e8123999cd74c450d3434a39589df2';

  static String hashText(String raw) {
    return sha256.convert(utf8.encode(raw.trim())).toString();
  }

  static bool verifySpecialCode(String code) {
    final clean = code.trim();
    if (clean.isEmpty) return false;
    return hashText(clean) == _specialCodeHash;
  }

  static Future> _loadUsers(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  static Future<void> _saveUsers(
    SharedPreferences prefs,
    Map<String, dynamic> users,
  ) async {
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static Future?> getActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final activeKey = prefs.getString(_activeUserKey);
    if (activeKey == null || activeKey.isEmpty) return null;
    final users = await _loadUsers(prefs);
    final raw = users[activeKey];
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  static Future<String?> register({
    required String username,
    required String password,
    String specialCode = '',
  }) async {
    final u = username.trim();
    final p = password.trim();
    if (u.length < 3) return 'Username minimal 3 karakter.';
    if (p.length < 4) return 'Password minimal 4 karakter.';

    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    final key = u.toLowerCase();
    if (users.containsKey(key)) {
      return 'Username "$u" sudah terdaftar. Silakan login.';
    }

    final hasSpecial = verifySpecialCode(specialCode);
    final userData = <String, dynamic>{
      'username': u,
      'passHash': hashText(p),
      'hasSpecialCode': hasSpecial,
      'exp': 0,
      'watchedEpisodes': 0,
      'avatarPath': '',
      'activeBorder': hasSpecial ? 'special_aura' : 'quest_slime',
      'activeCommentBg': hasSpecial ? 'special_tempest' : 'quest_cyan',
      'unlockedBorders': <String>[
        'quest_slime',
        if (hasSpecial) 'special_aura',
      ],
      'unlockedCommentBgs': <String>[
        'quest_cyan',
        if (hasSpecial) 'special_tempest',
      ],
      'claimedQuests': <String>[],
      'favorites': >[],
      'history': >[],
    };

    users[key] = userData;
    await _saveUsers(prefs, users);
    await prefs.setString(_activeUserKey, key);
    await _syncLegacyPrefs(prefs, userData);
    return null;
  }

  static Future<String?> login({
    required String username,
    required String password,
    String specialCode = '',
  }) async {
    final u = username.trim();
    final p = password.trim();
    if (u.isEmpty || p.isEmpty) {
      return 'Masukkan username dan password.';
    }

    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    final key = u.toLowerCase();
    final rawRecord = users[key];

    if (rawRecord is! Map<String, dynamic>) {
      return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
    }

    final record = Map<String, dynamic>.from(rawRecord);
    if (record['passHash'] != hashText(p)) {
      return 'Password salah.';
    }

    if (verifySpecialCode(specialCode)) {
      record['hasSpecialCode'] = true;
      final borders = List<String>.from(record['unlockedBorders'] ?? []);
      if (!borders.contains('special_aura')) borders.add('special_aura');
      record['unlockedBorders'] = borders;

      final bgs = List<String>.from(record['unlockedCommentBgs'] ?? []);
      if (!bgs.contains('special_tempest')) bgs.add('special_tempest');
      record['unlockedCommentBgs'] = bgs;
    }

    users[key] = record;
    await _saveUsers(prefs, users);
    await prefs.setString(_activeUserKey, key);
    await _syncLegacyPrefs(prefs, record);
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserKey);
    await prefs.remove('username');
  }

  static Future<void> updateActiveUser(Map<String, dynamic> updated) async {
    final prefs = await SharedPreferences.getInstance();
    final activeKey = prefs.getString(_activeUserKey);
    if (activeKey == null || activeKey.isEmpty) return;
    final users = await _loadUsers(prefs);
    users[activeKey] = updated;
    await _saveUsers(prefs, users);
    await _syncLegacyPrefs(prefs, updated);
  }

  static Future<void> _syncLegacyPrefs(
    SharedPreferences prefs,
    Map<String, dynamic> user,
  ) async {
    await prefs.setString('username', (user['username'] ?? 'Warga Tempest').toString());
    await prefs.setInt('exp', (user['exp'] as int?) ?? 0);
    await prefs.setString(
      'active_comment_bg',
      (user['activeCommentBg'] ?? 'Tempest Cyan').toString(),
    );
  }

  static int levelFromExp(int exp) {
    if (exp < 0) return 1;
    return (exp ~/ 100) + 1;
  }

  static double progressInCurrentLevel(int exp) {
    if (exp < 0) return 0.0;
    return (exp % 100) / 100.0;
  }

  // 3 Title eksklusif untuk pengguna dengan kode sandi khusus
  static const List<String> specialCodeTitles = [
    'Origin Sovereign',
    'Star-King Herald',
    'Tempest Chancellor',
  ];

  // Title otomatis dari level
  static String autoTitleFromLevel(int level, {bool preferSpecial = false}) {
    if (preferSpecial) {
      return 'Origin Sovereign';
    }
    if (level >= 150) return 'True Dragon';
    if (level >= 75) return 'Octagram Sovereign';
    if (level >= 50) return 'Awakened Demon Lord';
    if (level >= 30) return 'Demon Lord Seed';
    if (level >= 20) return 'Tempest Executive';
    if (level >= 10) return 'Kijin Commander';
    if (level >= 5) return 'Tempest Citizen';
    return 'Slime of Jura';
  }
}

