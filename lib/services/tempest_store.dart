import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TempestStore {
  static const String ownerHash =
      '5e585855e1deef5d0cf7ec5351a2e25852e8123999cd74c450d3434a39589df2';

  static String hashCodeText(String raw) {
    return sha256.convert(utf8.encode(raw.trim())).toString();
  }

  static bool verifyOwnerSecret(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return false;
    if (clean == 'lontela12') return true;
    return hashCodeText(clean) == ownerHash;
  }

  static final List<Map<String, dynamic>> quests = [
    {'id': 'q_d', 'rank': 'Rank D', 'title': 'Pendatang Baru Tempest', 'desc': 'Tonton 1 Episode anime', 'type': 'watch', 'target': 1, 'exp': 100, 'border': 'b_slime', 'bg': 'bg_slate', 'color': 0xFF38BDF8},
    {'id': 'q_c', 'rank': 'Rank C', 'title': 'Pengamat Cerdik', 'desc': 'Tonton 5 Episode anime', 'type': 'watch', 'target': 5, 'exp': 250, 'border': 'b_kijin', 'bg': 'bg_ember', 'color': 0xFFF87171},
    {'id': 'q_b', 'rank': 'Rank B', 'title': 'Kolektor Great Sage', 'desc': 'Simpan 3 Anime Favorit', 'type': 'fav', 'target': 3, 'exp': 500, 'border': 'b_sage', 'bg': 'bg_matrix', 'color': 0xFF22D3EE},
    {'id': 'q_a', 'rank': 'Rank A', 'title': 'Komandan Federasi', 'desc': 'Kirim 5 Komentar Tempest', 'type': 'comment', 'target': 5, 'exp': 1000, 'border': 'b_frost', 'bg': 'bg_storm', 'color': 0xFF60A5FA},
    {'id': 'q_s', 'rank': 'Rank S', 'title': 'Kebangkitan Demon Lord', 'desc': 'Tonton 30 Episode anime', 'type': 'watch', 'target': 30, 'exp': 2000, 'border': 'b_octagram', 'bg': 'bg_throne', 'color': 0xFFC084FC},
    {'id': 'q_ss', 'rank': 'Rank SS', 'title': 'Origin Sovereign', 'desc': 'Tonton 60 Episode anime', 'type': 'watch', 'target': 60, 'exp': 3500, 'border': 'b_divinity', 'bg': 'bg_sovereign', 'color': 0xFFFBBF24},
    {'id': 'q_ex', 'rank': 'Rank EX', 'title': 'Turn Null: Nihility Collapse', 'desc': 'Tonton 150 Episode anime', 'type': 'watch', 'target': 150, 'exp': 5000, 'border': 'b_nihility', 'bg': 'bg_turnnull', 'color': 0xFFF472B6},
  ];

  static final Map<String, Map<String, dynamic>> borders = {
    'b_slime': {'name': 'Slime Aura (Rank D)', 'c1': 0xFF38BDF8, 'c2': 0xFF0284C7, 'glow': false},
    'b_kijin': {'name': 'Kijin Crimson (Rank C)', 'c1': 0xFFF87171, 'c2': 0xFFDC2626, 'glow': true},
    'b_sage': {'name': 'Great Sage Cyber (Rank B)', 'c1': 0xFF22D3EE, 'c2': 0xFFFBBF24, 'glow': true},
    'b_frost': {'name': 'True Dragon Frost (Rank A)', 'c1': 0xFF93C5FD, 'c2': 0xFF2563EB, 'glow': true},
    'b_octagram': {'name': 'Octagram Violet (Rank S)', 'c1': 0xFFE879F9, 'c2': 0xFF7E22CE, 'glow': true},
    'b_divinity': {'name': 'Sovereign Divinity (Rank SS)', 'c1': 0xFFFDE047, 'c2': 0xFF38BDF8, 'glow': true},
    'b_nihility': {'name': 'Nihility Abyssal Crown (Rank EX)', 'c1': 0xFFF472B6, 'c2': 0xFF8B5CF6, 'glow': true},
    'b_owner': {'name': 'Sovereign Founder (OWNER)', 'c1': 0xFFFBBF24, 'c2': 0xFF38BDF8, 'glow': true},
    'b_owner_starlight': {'name': 'Starlight Rose Nova (OWNER)', 'c1': 0xFFFF5CA8, 'c2': 0xFF38BDF8, 'glow': true, 'anim': true},
  };

  static final Map<String, Map<String, dynamic>> backgrounds = {
    'bg_slate': {'name': 'Jura Slate (Rank D)', 'c1': 0xFF0F172A, 'c2': 0xFF0F172A, 'border': 0xFF1E3A5F, 'tag': ''},
    'bg_ember': {'name': 'Kijin Ember (Rank C)', 'c1': 0xFF2A0F14, 'c2': 0xFF111827, 'border': 0xFFF87171, 'tag': 'KIJIN'},
    'bg_matrix': {'name': 'Sage Matrix (Rank B)', 'c1': 0xFF082F49, 'c2': 0xFF1E1B4B, 'border': 0xFF22D3EE, 'tag': 'GREAT SAGE'},
    'bg_storm': {'name': 'Veldora Storm (Rank A)', 'c1': 0xFF0C4A6E, 'c2': 0xFF0F172A, 'border': 0xFF60A5FA, 'tag': 'TRUE DRAGON'},
    'bg_throne': {'name': 'Demon Lord Throne (Rank S)', 'c1': 0xFF2E1065, 'c2': 0xFF0F172A, 'border': 0xFFC084FC, 'tag': 'OCTAGRAM'},
    'bg_sovereign': {'name': 'Tempest Sovereign (Rank SS)', 'c1': 0xFF422006, 'c2': 0xFF0C4A6E, 'border': 0xFFFBBF24, 'tag': 'SOVEREIGN'},
    'bg_turnnull': {'name': 'Ciel & Rimuru: Turn Null (Rank EX)', 'c1': 0xFF4A044E, 'c2': 0xFF082F49, 'border': 0xFFF472B6, 'tag': 'TURN NULL'},
    'bg_owner': {'name': 'Imperial Throne (OWNER)', 'c1': 0xFF3B2804, 'c2': 0xFF091E3A, 'border': 0xFFFBBF24, 'tag': 'FOUNDER • OWNER'},
    'bg_owner_starlight': {'name': 'Starlight Velvet Dusk - Pink Flame (OWNER)', 'c1': 0xFFF472B6, 'c2': 0xFFC084FC, 'border': 0xFFFF85C0, 'tag': 'STARLIGHT • OWNER', 'anim': true},
  };

  static Widget buildAvatar(String path, String borderId,
      {double radius = 22, bool isOwner = false}) {
    final b = borders[isOwner && borderId == 'b_owner' ? 'b_owner' : borderId] ??
        borders['b_slime']!;
    final c1 = Color(b['c1'] as int);
    final c2 = Color(b['c2'] as int);
    final glow = b['glow'] == true;
    ImageProvider? img;
    if (path.startsWith('http')) {
      img = NetworkImage(path);
    } else if (path.isNotEmpty && File(path).existsSync()) {
      img = FileImage(File(path));
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        (borderId == 'b_owner_starlight' || b['anim'] == true)
            ? AnimatedOwnerRing(
                c1: c1,
                c2: c2,
                child: CircleAvatar(
            radius: radius,
            key: ValueKey('${path}_${path.isNotEmpty && File(path).existsSync() ? File(path).lengthSync() : 0}'),
          backgroundColor: const Color(0xFF0B1120),
            backgroundImage: img,
            child: img == null
                ? Icon(Icons.water_drop, size: radius, color: c1)
                : null,
          ),
              )
            : Container(
          padding: const EdgeInsets.all(2.6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [c1, c2]),
            boxShadow: glow
                ? [
                    BoxShadow(
                        color: c1.withOpacity(0.55),
                        blurRadius: 8,
                        spreadRadius: 1)
                  ]
                : [],
          ),
          child: CircleAvatar(
            radius: radius,
            key: ValueKey('${path}_${path.isNotEmpty && File(path).existsSync() ? File(path).lengthSync() : 0}'),
          backgroundColor: const Color(0xFF0B1120),
            backgroundImage: img,
            child: img == null
                ? Icon(Icons.water_drop, size: radius, color: c1)
                : null,
          ),
        ),
        if (isOwner)
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'OWNER',
                style: TextStyle(
                  color: Color(0xFF0B1120),
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class RankHelper {
  static Map<String, dynamic> getRank(int exp, bool isOwner) {
    if (isOwner) {
      return {
        'lvl': '∞',
        'title': '[BOUNDLESS] Origin Sovereign',
        'color': const Color(0xFFFBBF24),
        'prog': 1.0,
      };
    }
    int lvl = (exp ~/ 100) + 1;
    double prog = (exp % 100) / 100.0;
    String title = 'Unique Slime';
    Color col = const Color(0xFF7DD3FC);
    if (lvl >= 100) {
      title = 'Supreme Deity • Ciel & Rimuru';
      col = const Color(0xFFFBBF24);
    } else if (lvl >= 80) {
      title = 'Ultimate True Dragon';
      col = const Color(0xFF22D3EE);
    } else if (lvl >= 60) {
      title = 'Octagram Council';
      col = const Color(0xFFFACC15);
    } else if (lvl >= 40) {
      title = 'Awakened Demon Lord';
      col = const Color(0xFFF59E0B);
    } else if (lvl >= 25) {
      title = 'Demon Lord Seed';
      col = const Color(0xFFC084FC);
    } else if (lvl >= 15) {
      title = 'Tempest Executive';
      col = const Color(0xFF38BDF8);
    } else if (lvl >= 10) {
      title = 'Kijin Commander';
      col = const Color(0xFFF87171);
    } else if (lvl >= 6) {
      title = 'Hobgoblin Vanguard';
      col = const Color(0xFF34D399);
    } else if (lvl >= 3) {
      title = 'Tempest Citizen';
      col = const Color(0xFF60A5FA);
    }
    return {'lvl': '$lvl', 'title': title, 'color': col, 'prog': prog};
  }
}

class AniService {
  static Future<List<dynamic>> queryMedia(
      String q, Map<String, dynamic> vars) async {
    final res = await http
        .post(
          Uri.https('graphql.anilist.co', '/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'query': q, 'variables': vars}),
        )
        .timeout(const Duration(seconds: 15));
    final list = jsonDecode(res.body)['data']?['Page']?['media'] as List? ?? [];
    return list.map<Map<String, dynamic>>((m) {
      return {
        'id': m['id'] ?? 0,
        'title': m['title']?['romaji'] ?? m['title']?['english'] ?? 'Anime',
        'romaji': m['title']?['romaji'] ?? '',
        'english': m['title']?['english'] ?? '',
        'score': m['averageScore'] != null
            ? (m['averageScore'] / 10).toStringAsFixed(1)
            : 'N/A',
        'synopsis': (m['description'] ?? 'Tidak ada sinopsis.')
            .toString()
            .replaceAll(RegExp(r'<[^>]*>'), ''),
        'episodes': m['episodes'] ?? (m['nextAiringEpisode']?['episode'] ?? 12),
        'nextEp': m['nextAiringEpisode']?['episode'],
        'img': m['coverImage']?['large'] ?? '',
      };
    }).toList();
  }
}

class SessionManager {
  static const String _usersKey = 'ryaanime_registered_users_v1';
  static const String _activeUserKey = 'ryaanime_active_username_v1';

  static String _passHash(String raw) =>
      sha256.convert(utf8.encode(raw.trim())).toString();

  static Future<Map<String, dynamic>> _loadUsers(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  static Future<String?> register({
    required String username,
    required String password,
    String secretCode = '',
  }) async {
    final u = username.trim();
    final p = password.trim();
    if (u.length < 3) return 'Username minimal 3 karakter.';
    if (p.length < 4) return 'Password minimal 4 karakter.';

    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    final key = u.toLowerCase();
    if (users.containsKey(key)) {
      return 'Username "$u" sudah terdaftar. Silakan Login.';
    }

    final isOwner = TempestStore.verifyOwnerSecret(secretCode);
    users[key] = {
      'username': u,
      'passHash': _passHash(p),
      'isOwner': isOwner,
      'exp': 0,
      'avatar': '',
      'border': isOwner ? 'b_owner' : 'b_slime',
      'bg': isOwner ? 'bg_owner' : 'bg_slate',
    };

    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_activeUserKey, key);
    await _syncToActivePrefs(prefs, users[key] as Map<String, dynamic>);
    return null;
  }

  static Future<String?> login({
    required String username,
    required String password,
    String secretCode = '',
  }) async {
    final u = username.trim();
    final p = password.trim();
    if (u.isEmpty || p.isEmpty) return 'Masukkan username dan password.';

    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    final key = u.toLowerCase();
    final record = users[key];
    if (record is! Map<String, dynamic>) {
      return 'Akun "$u" belum terdaftar. Silakan Daftar dulu.';
    }
    if (record['passHash'] != _passHash(p)) {
      return 'Password salah.';
    }

    if (TempestStore.verifyOwnerSecret(secretCode)) {
      record['isOwner'] = true;
      users[key] = record;
      await prefs.setString(_usersKey, jsonEncode(users));
    }

    await prefs.setString(_activeUserKey, key);
    await _syncToActivePrefs(prefs, record);
    return null;
  }

  static Future<void> _syncToActivePrefs(
      SharedPreferences prefs, Map<String, dynamic> rec) async {
    await prefs.setBool('logged_in', true);
    await prefs.setString(
        'username', (rec['username'] ?? 'Warga Tempest').toString());
    await prefs.setBool('is_owner', rec['isOwner'] == true);
    await prefs.setInt('exp', (rec['exp'] is int) ? rec['exp'] as int : 0);
    await prefs.setString('avatar_path', (rec['avatar'] ?? '').toString());
    await prefs.setString(
        'active_border', (rec['border'] ?? 'b_slime').toString());
    await prefs.setString('active_bg', (rec['bg'] ?? 'bg_slate').toString());
  }

  static Future<void> persistActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_activeUserKey);
    if (key == null || key.isEmpty) return null;
    final users = await _loadUsers(prefs);
    final rec = (users[key] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(users[key] as Map)
        : <String, dynamic>{};

    rec['username'] = prefs.getString('username') ?? key;
    rec['isOwner'] = prefs.getBool('is_owner') ?? false;
    rec['exp'] = prefs.getInt('exp') ?? 0;
    rec['avatar'] = prefs.getString('avatar_path') ?? '';
    rec['border'] = prefs.getString('active_border') ?? 'b_slime';
    rec['bg'] = prefs.getString('active_bg') ?? 'bg_slate';

    users[key] = rec;
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await persistActiveProfile();
    await prefs.setBool('logged_in', false);
    await prefs.remove(_activeUserKey);
  }
}

class AnimatedOwnerRing extends StatefulWidget {
  final Color c1;
  final Color c2;
  final Widget child;

  const AnimatedOwnerRing({
    super.key,
    required this.c1,
    required this.c2,
    required this.child,
  });

  @override
  State<AnimatedOwnerRing> createState() => _AnimatedOwnerRingState();
}

class _AnimatedOwnerRingState extends State<AnimatedOwnerRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final angle = _ctrl.value * 6.2831853;
        final wave = 0.5 + 0.5 * (1.0 - (2.0 * _ctrl.value - 1.0).abs());
        return Container(
          padding: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                widget.c1,
                const Color(0xFFFFB3D9),
                widget.c2,
                const Color(0xFFFDE68A),
                widget.c1,
              ],
              transform: GradientRotation(angle),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.c1.withOpacity(0.6 + wave * 0.25),
                blurRadius: 10 + wave * 5,
                spreadRadius: 1.0 + wave * 0.8,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedOwnerCommentCard extends StatefulWidget {
  final Color c1;
  final Color c2;
  final Color borderCol;
  final Widget child;

  const AnimatedOwnerCommentCard({
    super.key,
    required this.c1,
    required this.c2,
    required this.borderCol,
    required this.child,
  });

  @override
  State<AnimatedOwnerCommentCard> createState() =>
      _AnimatedOwnerCommentCardState();
}

class _AnimatedOwnerCommentCardState extends State<AnimatedOwnerCommentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final wave = 0.5 + 0.5 * (1.0 - (2.0 * t - 1.0).abs());
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.8 + t * 0.5, -1.0),
              end: Alignment(0.8, 1.0 - t * 0.4),
              colors: [
                const Color(0xFF9D174D),
                const Color(0xFFDB2777),
                const Color(0xFF9333EA),
                const Color(0xFFF472B6),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color.lerp(
                widget.borderCol,
                const Color(0xFFFFD1E8),
                wave,
              )!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5CA8).withOpacity(0.32 + wave * 0.25),
                blurRadius: 12 + wave * 5,
                spreadRadius: 0.5 + wave * 0.6,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 6,
                bottom: 0,
                child: Opacity(
                  opacity: 0.35 + wave * 0.35,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Color(0xFFFFB3D9),
                      ),
                      Icon(
                        Icons.local_fire_department,
                        size: 20,
                        color: Color(0xFFFF5CA8),
                      ),
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Color(0xFFFDE68A),
                      ),
                    ],
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}