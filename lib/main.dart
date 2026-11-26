import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const RyaaNimeApp());

class RyaaNimeApp extends StatelessWidget {
  const RyaaNimeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RyaaNime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF38BDF8), secondary: Color(0xFFFBBF24)),
      ),
      home: const AuthGate(),
    );
  }
}


class TempestStore {
  static const String ownerHash = '5e585855e1deef5d0cf7ec5351a2e25852e8123999cd74c450d3434a39589df2';

  static String hashCodeText(String raw) {
    return sha256.convert(utf8.encode(raw.trim())).toString();
  }

  static bool verifyOwnerSecret(String input) {
    return hashCodeText(input) == ownerHash;
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
  };

  static Widget buildAvatar(String path, String borderId, {double radius = 22, bool isOwner = false}) {
    final b = borders[isOwner && borderId == 'b_owner' ? 'b_owner' : borderId] ?? borders['b_slime']!;
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
        Container(
          padding: const EdgeInsets.all(2.6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [c1, c2]),
            boxShadow: glow ? [BoxShadow(color: c1.withOpacity(0.55), blurRadius: 8, spreadRadius: 1)] : [],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFF0B1120),
            backgroundImage: img,
            child: img == null ? Icon(Icons.water_drop, size: radius, color: c1) : null,
          ),
        ),
        if (isOwner)
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(6)),
              child: const Text('OWNER', style: TextStyle(color: Color(0xFF0B1120), fontSize: 7, fontWeight: FontWeight.w900)),
            ),
          ),
      ],
    );
  }
}

class RankHelper {
  static Map<String, dynamic> getRank(int exp, bool isOwner) {
    if (isOwner) return {'lvl': '∞', 'title': '[BOUNDLESS] Origin Sovereign', 'color': const Color(0xFFFBBF24), 'prog': 1.0};
    int lvl = (exp ~/ 100) + 1;
    double prog = (exp % 100) / 100.0;
    String title = 'Unique Slime';
    Color col = const Color(0xFF7DD3FC);
    if (lvl >= 100) { title = 'Supreme Deity • Ciel & Rimuru'; col = const Color(0xFFFBBF24); }
    else if (lvl >= 80) { title = 'Ultimate True Dragon'; col = const Color(0xFF22D3EE); }
    else if (lvl >= 60) { title = 'Octagram Council'; col = const Color(0xFFFACC15); }
    else if (lvl >= 40) { title = 'Awakened Demon Lord'; col = const Color(0xFFF59E0B); }
    else if (lvl >= 25) { title = 'Demon Lord Seed'; col = const Color(0xFFC084FC); }
    else if (lvl >= 15) { title = 'Tempest Executive'; col = const Color(0xFF38BDF8); }
    else if (lvl >= 10) { title = 'Kijin Commander'; col = const Color(0xFFF87171); }
    else if (lvl >= 6) { title = 'Hobgoblin Vanguard'; col = const Color(0xFF34D399); }
    else if (lvl >= 3) { title = 'Tempest Citizen'; col = const Color(0xFF60A5FA); }
    return {'lvl': '$lvl', 'title': title, 'color': col, 'prog': prog};
  }
}

class AniService {
  static Future<List<Map<String, dynamic>>> queryMedia(String q, Map<String, dynamic> vars) async {
    final res = await http.post(
      Uri.https('graphql.anilist.co', '/'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'query': q, 'variables': vars}),
    ).timeout(const Duration(seconds: 15));
    final list = jsonDecode(res.body)['data']?['Page']?['media'] as List? ?? [];
    return list.map<Map<String, dynamic>>((m) => {
      'id': m['id'] ?? 0,
      'title': m['title']?['romaji'] ?? m['title']?['english'] ?? 'Anime',
      'score': m['averageScore'] != null ? (m['averageScore'] / 10).toStringAsFixed(1) : 'N/A',
      'synopsis': (m['description'] ?? 'Tidak ada sinopsis.').toString().replaceAll(RegExp(r'<[^>]*>'), ''),
      'episodes': m['episodes'] ?? (m['nextAiringEpisode']?['episode'] ?? 12),
      'nextEp': m['nextAiringEpisode']?['episode'],
      'img': m['coverImage']?['large'] ?? '',
    }).toList();
  }
}


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loading = true;
  bool loggedIn = false;
  bool isRegister = false;
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final secretCtrl = TextEditingController();
  String avatarPath = '';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      loggedIn = p.getString('current_user') != null;
      loading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      setState(() => avatarPath = x.path);
    }
  }

  Future<void> _submit() async {
    final u = userCtrl.text.trim();
    final pw = passCtrl.text.trim();
    if (u.length < 3 || pw.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username min. 3 huruf & Password min. 4 karakter')));
      return;
    }
    final p = await SharedPreferences.getInstance();
    final rawAccounts = p.getString('accounts_db') ?? '{}';
    final Map<String, dynamic> db = jsonDecode(rawAccounts);
    final pwHash = TempestStore.hashCodeText(pw);
    final isOwner = TempestStore.verifyOwnerSecret(secretCtrl.text);

    if (isRegister) {
      if (db.containsKey(u)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username sudah terdaftar, silakan Masuk')));
        return;
      }
      db[u] = {'pw': pwHash, 'owner': isOwner, 'avatar': avatarPath};
      await p.setString('accounts_db', jsonEncode(db));
    } else {
      if (!db.containsKey(u) || db[u]['pw'] != pwHash) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username atau Password salah!')));
        return;
      }
      if (isOwner) db[u]['owner'] = true;
      if (avatarPath.isNotEmpty) db[u]['avatar'] = avatarPath;
      await p.setString('accounts_db', jsonEncode(db));
    }

    final acc = db[u];
    final finalOwner = acc['owner'] == true;
    await p.setString('current_user', u);
    await p.setString('userName', u);
    await p.setBool('userOwner', finalOwner);
    if ((acc['avatar'] ?? '').toString().isNotEmpty) {
      await p.setString('userAvatar', acc['avatar']);
    }
    if (finalOwner) {
      await p.setString('activeBorder', 'b_owner');
      await p.setString('activeBg', 'bg_owner');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('👑 Status OWNER Terverifikasi!')));
    }
    setState(() => loggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: Color(0xFF0B1120), body: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))));
    if (loggedIn) return const MainNav();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TempestStore.buildAvatar('', 'b_slime', radius: 34),
                  const SizedBox(height: 6),
                  Text(isRegister ? 'Daftar Warga Tempest' : 'Masuk ke RyaaNime', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline, color: Color(0xFF38BDF8))),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF38BDF8))),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: secretCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Kode Khusus (Opsional)', prefixIcon: Icon(Icons.vpn_key_outlined, color: Color(0xFFFBBF24))),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: const Color(0xFF0B1120), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _submit,
                      child: Text(isRegister ? 'Daftar & Masuk' : 'Masuk', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => isRegister = !isRegister),
                    child: Text(isRegister ? 'Sudah punya akun? Masuk di sini' : 'Belum punya akun? Daftar sekarang', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [const HomeTab(), const ScheduleTab(), const HistoryTab(), const SearchTab()];
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: idx,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.blueGrey,
        onTap: (v) => setState(() => idx = v),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop_rounded), label: 'Tempest'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Cari'),
        ],
      ),
    );
  }
}
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String userName = 'Warga Tempest';
  String userAvatar = '';
  bool userOwner = false;
  List<dynamic> favList = [];

  String activeBorder = 'b_slime';
  String activeTitle = '';
  String activeBg = 'bg_slate';
  int watchCount = 0;
  int commentCount = 0;
  List<String> claimedQuests = [];

  Future<void> _syncTempestData() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      userName = p.getString('userName') ?? p.getString('current_user') ?? 'Warga Tempest';
      userAvatar = p.getString('userAvatar') ?? '';
      userOwner = p.getBool('userOwner') ?? false;
      activeBorder = p.getString('activeBorder') ?? (userOwner ? 'b_owner' : 'b_slime');
      activeBg = p.getString('activeBg') ?? (userOwner ? 'bg_owner' : 'bg_slate');
      watchCount = p.getInt('watchCount') ?? 0;
      commentCount = p.getInt('commentCount') ?? 0;
      claimedQuests = p.getStringList('claimedQuests') ?? [];
    });
  }

  void _openTempestHub() {
    _syncTempestData();
    final secretCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DefaultTabController(
          length: 3,
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.82,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                const TabBar(
                  labelColor: Color(0xFF38BDF8),
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Color(0xFF38BDF8),
                  tabs: [Tab(text: 'Profil'), Tab(text: 'Quest (7)'), Tab(text: 'Koleksi')],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Center(child: TempestStore.buildAvatar(userAvatar, activeBorder, radius: 38, isOwner: userOwner)),
                          const SizedBox(height: 8),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final x = await ImagePicker().pickImage(source: ImageSource.gallery);
                                if (x != null) {
                                  final p = await SharedPreferences.getInstance();
                                  await p.setString('userAvatar', x.path);
                                  setState(() => userAvatar = x.path);
                                  setModal(() {});
                                }
                              },
                              icon: const Icon(Icons.photo_library, size: 16),
                              label: const Text('Ganti Foto / GIF dari Galeri'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!userOwner) ...[
                            TextField(controller: secretCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Aktivasi Kode Rahasia', border: OutlineInputBorder())),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBBF24), foregroundColor: Colors.black),
                              onPressed: () async {
                                if (TempestStore.verifyOwnerSecret(secretCtrl.text)) {
                                  final p = await SharedPreferences.getInstance();
                                  await p.setBool('userOwner', true);
                                  await p.setString('activeBorder', 'b_owner');
                                  await p.setString('activeBg', 'bg_owner');
                                  setState(() { userOwner = true; activeBorder = 'b_owner'; activeBg = 'bg_owner'; });
                                  setModal(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('👑 Set Eksklusif Owner Aktif!')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode tidak valid!')));
                                }
                              },
                              child: const Text('Verifikasi Kode', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                            onPressed: () async {
                              final p = await SharedPreferences.getInstance();
                              await p.remove('current_user');
                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthGate()), (_) => false);
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Keluar Akun (Logout)'),
                          ),
                        ],
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: TempestStore.quests.length,
                        itemBuilder: (_, i) {
                          final q = TempestStore.quests[i];
                          final id = q['id'] as String;
                          final target = q['target'] as int;
                          final prog = q['type'] == 'comment' ? commentCount : (q['type'] == 'fav' ? favList.length : watchCount);
                          final done = prog >= target;
                          final claimed = claimedQuests.contains(id);
                          return Card(
                            color: const Color(0xFF1E293B),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text('[${q['rank']}] ${q['title']}', style: TextStyle(color: Color(q['color'] as int), fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${q['desc']} ($prog/$target)\nHadiah: +${q['exp']} EXP + Border & BG', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              trailing: ElevatedButton(
                                onPressed: (done && !claimed) ? () async {
                                  final p = await SharedPreferences.getInstance();
                                  claimedQuests.add(id);
                                  await p.setStringList('claimedQuests', claimedQuests);
                                  await p.setInt('userExp', (p.getInt('userExp') ?? 0) + (q['exp'] as int));
                                  setState(() {});
                                  setModal(() {});
                                } : null,
                                child: Text(claimed ? 'Diklaim' : (done ? 'Klaim' : 'Proses'), style: const TextStyle(fontSize: 11)),
                              ),
                            ),
                          );
                        },
                      ),
                      ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          const Text('Pilih Border Avatar (Equip / Unequip)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...TempestStore.borders.entries.map((e) {
                            final isOwnerItem = e.key == 'b_owner';
                            final unlocked = isOwnerItem ? userOwner : (e.key == 'b_slime' || TempestStore.quests.any((q) => q['border'] == e.key && claimedQuests.contains(q['id'])));
                            return ListTile(
                              leading: TempestStore.buildAvatar(userAvatar, e.key, radius: 18, isOwner: isOwnerItem),
                              title: Text(e.value['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                              trailing: unlocked
                                  ? Radio<String>(value: e.key, groupValue: activeBorder, onChanged: (v) async {
                                      final p = await SharedPreferences.getInstance();
                                      await p.setString('activeBorder', v!);
                                      setState(() => activeBorder = v);
                                      setModal(() {});
                                    })
                                  : const Icon(Icons.lock, size: 16, color: Colors.white38),
                            );
                          }),
                          const Divider(color: Colors.white24),
                          const Text('Pilih Background Komentar (Equip / Unequip)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...TempestStore.backgrounds.entries.map((e) {
                            final isOwnerItem = e.key == 'bg_owner';
                            final unlocked = isOwnerItem ? userOwner : (e.key == 'bg_slate' || TempestStore.quests.any((q) => q['bg'] == e.key && claimedQuests.contains(q['id'])));
                            return ListTile(
                              tileColor: Color(e.value['c1'] as int),
                              title: Text(e.value['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                              trailing: unlocked
                                  ? Radio<String>(value: e.key, groupValue: activeBg, onChanged: (v) async {
                                      final p = await SharedPreferences.getInstance();
                                      await p.setString('activeBg', v!);
                                      setState(() => activeBg = v);
                                      setModal(() {});
                                    })
                                  : const Icon(Icons.lock, size: 16, color: Colors.white38),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String name = 'Warga Tempest';
  String avatarUrl = '';
  int exp = 0;
  bool isOwner = false;
  late Future<List<List<Map<String, dynamic>>>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = loadAll();
    loadProfile();
  }

  Future<List<List<Map<String, dynamic>>>> loadAll() => Future.wait([
    AniService.queryMedia('query { Page(perPage: 15) { media(type: ANIME, status: RELEASING, sort: POPULARITY_DESC) { id title { romaji english } averageScore description episodes nextAiringEpisode { episode } coverImage { large } } } }', {}),
    AniService.queryMedia('query { Page(perPage: 24) { media(type: ANIME, sort: TRENDING_DESC) { id title { romaji english } averageScore description episodes nextAiringEpisode { episode } coverImage { large } } } }', {}),
  ]);

  Future<void> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      name = p.getString('name') ?? 'Warga Tempest';
      avatarUrl = p.getString('avatar') ?? '';
      exp = p.getInt('exp') ?? 0;
      isOwner = p.getBool('owner') ?? false;
    });
  }

  void openProfileDialog() {
    final nameCtrl = TextEditingController(text: name);
    final codeCtrl = TextEditingController();
    int tabIdx = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 14),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.72,
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ChoiceChip(label: const Center(child: Text('Profil')), selected: tabIdx == 0, onSelected: (_) => setModal(() => tabIdx = 0), selectedColor: const Color(0xFF38BDF8))),
                      const SizedBox(width: 6),
                      Expanded(child: ChoiceChip(label: const Center(child: Text('Quest')), selected: tabIdx == 1, onSelected: (_) => setModal(() => tabIdx = 1), selectedColor: const Color(0xFF38BDF8))),
                      const SizedBox(width: 6),
                      Expanded(child: ChoiceChip(label: const Center(child: Text('Koleksi')), selected: tabIdx == 2, onSelected: (_) => setModal(() => tabIdx = 2), selectedColor: const Color(0xFF38BDF8))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: tabIdx == 0
                        ? ListView(
                            children: [
                              Center(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      final p = await SharedPreferences.getInstance();
                                      await p.setString('avatar', picked.path);
                                      await p.setString('userAvatar', picked.path);
                                      setState(() => avatarUrl = picked.path);
                                      setModal(() {});
                                    }
                                  },
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      TempestStore.buildAvatar(avatarUrl, activeBorder, radius: 42),
                                      Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle), child: const Icon(Icons.photo_library_rounded, size: 16, color: Colors.black)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Center(child: Text('Ketuk avatar untuk pilih Foto / GIF dari Galeri', style: TextStyle(color: Colors.white60, fontSize: 11))),
                              const SizedBox(height: 12),
                              TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nama Pengguna', labelStyle: TextStyle(color: Colors.white70))),
                              const SizedBox(height: 8),
                              TextField(controller: codeCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Kode Rahasia (Opsional)', labelStyle: TextStyle(color: Colors.white70))),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black),
                                onPressed: () async {
                                  final p = await SharedPreferences.getInstance();
                                  final newName = nameCtrl.text.trim().isEmpty ? name : nameCtrl.text.trim();
                                  final rawCode = codeCtrl.text.trim();
                                  final ownerActive = isOwner || TempestStore.verifyOwnerSecret(rawCode) || rawCode == 'lontelah12';
                                  await p.setString('name', newName);
                                  await p.setString('userName', newName);
                                  await p.setBool('owner', ownerActive);
                                  await p.setBool('userOwner', ownerActive);
                                  setState(() { name = newName; isOwner = ownerActive; });
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                                onPressed: () async {
                                  final p = await SharedPreferences.getInstance();
                                  await p.remove('current_user');
                                  await p.setBool('logged_in', false);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthGate()), (_) => false);
                                },
                                icon: const Icon(Icons.logout_rounded, size: 18),
                                label: const Text('Keluar Akun (Logout)'),
                              ),
                            ],
                          )
                        : tabIdx == 1
                            ? ListView(
                                children: TempestStore.quests.map((q) {
                                  final id = q['id'] as String;
                                  final claimed = claimedQuests.contains(id);
                                  final progress = (q['type'] == 'comment') ? commentCount : watchCount;
                                  final target = q['target'] as int;
                                  final done = isOwner || progress >= target;
                                  return Card(
                                    color: const Color(0xFF1E293B),
                                    child: ListTile(
                                      leading: CircleAvatar(backgroundColor: const Color(0xFF38BDF8).withOpacity(0.2), child: Text(q['rank'] as String, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12))),
                                      title: Text(q['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                      subtitle: Text('${q['desc']} (${isOwner ? target : progress}/$target)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      trailing: claimed
                                          ? const Text('Diklaim', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 11))
                                          : ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: done ? const Color(0xFFFBBF24) : Colors.white12, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                              onPressed: !done ? null : () async {
                                                final p = await SharedPreferences.getInstance();
                                                claimedQuests.add(id);
                                                await p.setStringList('claimedQuests', claimedQuests);
                                                final nextExp = exp + (q['xp'] as int);
                                                await p.setInt('exp', nextExp);
                                                setState(() => exp = nextExp);
                                                setModal(() {});
                                              },
                                              child: Text(done ? 'Klaim' : 'Terkunci', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : ListView(
                                children: [
                                  const Text('Pilih Border Avatar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  ...TempestStore.borders.entries.map((e) {
                                    final unlocked = isOwner || e.key == 'b_slime' || TempestStore.quests.any((q) => q['border'] == e.key && claimedQuests.contains(q['id']));
                                    return ListTile(
                                      title: Text(e.value['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      trailing: unlocked
                                          ? Radio<String>(value: e.key, groupValue: activeBorder, onChanged: (v) async {
                                              final p = await SharedPreferences.getInstance();
                                              await p.setString('activeBorder', v!);
                                              setState(() => activeBorder = v);
                                              setModal(() {});
                                            })
                                          : const Icon(Icons.lock, size: 16, color: Colors.white38),
                                    );
                                  }),
                                  const Divider(color: Colors.white24),
                                  const Text('Pilih Background Kartu Komentar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  ...TempestStore.backgrounds.entries.map((e) {
                                    final unlocked = isOwner || e.key == 'bg_slate' || TempestStore.quests.any((q) => q['bg'] == e.key && claimedQuests.contains(q['id']));
                                    return ListTile(
                                      tileColor: Color(e.value['c1'] as int),
                                      title: Text(e.value['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      trailing: unlocked
                                          ? Radio<String>(value: e.key, groupValue: activeBg, onChanged: (v) async {
                                              final p = await SharedPreferences.getInstance();
                                              await p.setString('activeBg', v!);
                                              setState(() => activeBg = v);
                                              setModal(() {});
                                            })
                                          : const Icon(Icons.lock, size: 16, color: Colors.white38),
                                    );
                                  }),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = RankHelper.getRank(exp, isOwner);
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: r['color'], width: 1.4),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: openProfileDialog,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF38BDF8),
                    backgroundImage: avatarUrl.startsWith('http') ? NetworkImage(avatarUrl) : null,
                    child: !avatarUrl.startsWith('http') ? const Icon(Icons.water_drop, color: Color(0xFF0B1120)) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: openProfileDialog,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (isOwner) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.workspace_premium, color: Color(0xFFFBBF24), size: 17)),
                        ]),
                        Text('Lvl. ${r['lvl']} • ${r['title']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: r['color'])),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(value: r['prog'], backgroundColor: Colors.white12, color: r['color'], minHeight: 4),
                      ],
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.refresh, color: Color(0xFFFBBF24)), onPressed: () => setState(() { futureData = loadAll(); })),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<List<Map<String, dynamic>>>>(
              future: futureData,
              builder: (c, s) {
                if (s.hasError) return Center(child: Text('Error: ${s.error}', style: const TextStyle(color: Colors.redAccent)));
                if (!s.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                final ongoing = s.data![0];
                final trending = s.data![1];
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧪 Versi Demo RyaaNime • Federasi Tempest', style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Aplikasi ini masih tahap demo uji coba. Laporkan bug atau gabung komunitas lewat tautan di bawah:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF38BDF8), side: const BorderSide(color: Color(0xFF38BDF8))),
                        onPressed: () => launchUrl(Uri.parse('mailto:ryaaeulah12@gmail.com?subject=Bug%20Report%20RyaaNime'), mode: LaunchMode.externalApplication),
                        child: const Text('🐞 Lapor Bug', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.black),
                        onPressed: () => launchUrl(Uri.parse('https://chat.whatsapp.com/Jm3MgGSBiCJFO2PgQfMjMg'), mode: LaunchMode.externalApplication),
                        child: const Text('💬 Grup WA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Sedang Tayang (Ongoing)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                    ),
                    SizedBox(
                      height: 175,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: ongoing.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) => SizedBox(width: 105, child: AnimeCard(item: ongoing[i], badge: 'ONGOING', onWatch: loadProfile)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Populer Musim Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: trending.length,
                      itemBuilder: (ctx, i) => AnimeCard(item: trending[i], onWatch: loadProfile),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});
  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  int selectedDay = DateTime.now().weekday % 7;
  final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  late Future<List<Map<String, dynamic>>> futureSched;

  @override
  void initState() {
    super.initState();
    futureSched = fetchWeek();
  }

  Future<List<Map<String, dynamic>>> fetchWeek() async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(Duration(days: now.weekday % 7)).millisecondsSinceEpoch ~/ 1000;
    final end = start + (7 * 86400);
    final res = await http.post(
      Uri.https('graphql.anilist.co', '/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': 'query (\$s: Int, \$e: Int) { Page(perPage: 50) { airingSchedules(airingAt_greater: \$s, airingAt_lesser: \$e, sort: TIME) { airingAt episode media { id title { romaji english } averageScore description episodes coverImage { large } isAdult } } } }',
        'variables': {'s': start, 'e': end},
      }),
    );
    final list = jsonDecode(res.body)['data']?['Page']?['airingSchedules'] as List? ?? [];
    return list.where((x) => x['media']?['isAdult'] != true).map<Map<String, dynamic>>((x) {
      final m = x['media'];
      final dt = DateTime.fromMillisecondsSinceEpoch((x['airingAt'] as int) * 1000, isUtc: true).add(const Duration(hours: 7));
      return {
        'day': dt.weekday % 7,
        'time': '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB',
        'ep': x['episode'] ?? 1,
        'id': m['id'] ?? 0,
        'title': m['title']?['romaji'] ?? m['title']?['english'] ?? 'Anime',
        'score': m['averageScore'] != null ? (m['averageScore'] / 10).toStringAsFixed(1) : 'N/A',
        'synopsis': (m['description'] ?? 'Tidak ada sinopsis.').toString().replaceAll(RegExp(r'<[^>]*>'), ''),
        'episodes': m['episodes'] ?? (x['episode'] ?? 12),
        'img': m['coverImage']?['large'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Rilis • RyaaNime'), backgroundColor: const Color(0xFF0F172A)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final active = selectedDay == i;
                return GestureDetector(
                  onTap: () => setState(() => selectedDay = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(color: active ? const Color(0xFF38BDF8) : const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                    child: Text(days[i], style: TextStyle(fontWeight: FontWeight.bold, color: active ? const Color(0xFF0B1120) : Colors.white70)),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: futureSched,
              builder: (c, s) {
                if (!s.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                final items = s.data!.where((e) => e['day'] == selectedDay).toList();
                if (items.isEmpty) return const Center(child: Text('Tidak ada jadwal di hari ini.', style: TextStyle(color: Colors.white60)));
                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final it = items[i];
                    return ListTile(
                      tileColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF1E3A5F))),
                      leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(it['img'], width: 45, height: 65, fit: BoxFit.cover)),
                      title: Text(it['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Episode ${it['ep']} • ${it['time']}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                      trailing: const Icon(Icons.play_circle_fill, color: Color(0xFFFBBF24)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(item: it))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  bool showFav = false;
  List<Map<String, dynamic>> list = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(showFav ? 'favs' : 'history') ?? [];
    setState(() => list = raw.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: !showFav ? const Color(0xFF38BDF8) : const Color(0xFF0F172A)),
                    onPressed: () { showFav = false; load(); },
                    child: Text('Riwayat', style: TextStyle(color: !showFav ? const Color(0xFF0B1120) : Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: showFav ? const Color(0xFFFBBF24) : const Color(0xFF0F172A)),
                    onPressed: () { showFav = true; load(); },
                    child: Text('Favorit', style: TextStyle(color: showFav ? const Color(0xFF0B1120) : Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text(showFav ? 'Belum ada anime favorit.' : 'Belum ada riwayat tontonan.', style: const TextStyle(color: Colors.white60)))
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final it = list[i];
                      return ListTile(
                        tileColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(it['img'] ?? '', width: 45, height: 65, fit: BoxFit.cover)),
                        title: Text(it['title'] ?? 'Anime', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(it['lastEp'] != null ? 'Terakhir: Episode ${it['lastEp']}' : '★ ${it['score'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(item: it))).then((_) => load()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  List<Map<String, dynamic>> results = [];
  bool loading = false;
  final genres = [
    'Action', 'Adventure', 'Comedy', 'Drama', 'Ecchi', 'Fantasy',
    'Horror', 'Isekai', 'Magic', 'Mecha', 'Music', 'Mystery',
    'Psychological', 'Romance', 'Sci-Fi', 'Slice of Life',
    'Sports', 'Supernatural', 'Thriller'
  ];

  @override
  void initState() {
    super.initState();
    search();
  }

  void search({String? q, String? genre}) async {
    setState(() => loading = true);
    final data = await AniService.queryMedia(
      'query (\$s: String, \$g: String) { Page(perPage: 24) { media(type: ANIME, search: \$s, genre: \$g, sort: POPULARITY_DESC) { id title { romaji english } averageScore description episodes nextAiringEpisode { episode } coverImage { large } } } }',
      {if (q != null && q.trim().isNotEmpty) 's': q.trim(), if (genre != null) 'g': genre},
    );
    setState(() { results = data; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onSubmitted: (v) => search(q: v),
              decoration: InputDecoration(
                hintText: 'Great Sage: Cari Anime...',
                filled: true,
                fillColor: const Color(0xFF0F172A),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: genres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) => ActionChip(
                backgroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFF38BDF8)),
                label: Text(genres[i], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                onPressed: () => search(genre: genres[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))) : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: results.length,
              itemBuilder: (ctx, i) => AnimeCard(item: results[i]),
            ),
          ),
        ],
      ),
    );
  }
}
class AnimeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? badge;
  final VoidCallback? onWatch;
  const AnimeCard({super.key, required this.item, this.badge, this.onWatch});
  @override
  Widget build(BuildContext context) {
    final img = item['img'] ?? '';
    final title = item['title'] ?? 'Anime';
    final score = item['score'] ?? 'N/A';
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(item: item)));
        if (onWatch != null) onWatch!();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFF1E3A5F))),
              child: Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img, width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
                  Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xCC0B1120), borderRadius: BorderRadius.circular(4)), child: Text('★ $score', style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold)))),
                  if (badge != null) Positioned(bottom: 4, right: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xDD0284C7), borderRadius: BorderRadius.circular(4)), child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const DetailPage({super.key, required this.item});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool isFav = false;
  @override
  void initState() {
    super.initState();
    checkFav();
  }

  Future<void> checkFav() async {
    final p = await SharedPreferences.getInstance();
    final favs = p.getStringList('favs') ?? [];
    setState(() => isFav = favs.any((e) => jsonDecode(e)['title'] == widget.item['title']));
  }

  Future<void> toggleFav() async {
    final p = await SharedPreferences.getInstance();
    final favs = p.getStringList('favs') ?? [];
    favs.removeWhere((e) => jsonDecode(e)['title'] == widget.item['title']);
    if (!isFav) favs.insert(0, jsonEncode(widget.item));
    await p.setStringList('favs', favs);
    setState(() => isFav = !isFav);
  }

  Future<void> openEp(int epNum) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('exp', (p.getInt('exp') ?? 0) + 25);
    final hist = p.getStringList('history') ?? [];
    hist.removeWhere((e) => jsonDecode(e)['title'] == widget.item['title']);
    final entry = Map<String, dynamic>.from(widget.item)..['lastEp'] = epNum;
    hist.insert(0, jsonEncode(entry));
    await p.setStringList('history', hist.take(40).toList());
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(item: widget.item, ep: epNum)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item['title'] ?? 'Anime';
    final syn = widget.item['synopsis'] ?? 'Tidak ada sinopsis.';
    final int eps = (widget.item['episodes'] is int && widget.item['episodes'] > 0) ? widget.item['episodes'] : 12;
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 15)), backgroundColor: const Color(0xFF0F172A)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)), icon: const Icon(Icons.play_arrow, color: Color(0xFF0B1120)), label: const Text('Mulai Tonton Ep 1', style: TextStyle(color: Color(0xFF0B1120), fontWeight: FontWeight.bold)), onPressed: () => openEp(1))),
              const SizedBox(width: 8),
              OutlinedButton.icon(style: OutlinedButton.styleFrom(side: BorderSide(color: isFav ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8))), icon: Icon(isFav ? Icons.bookmark : Icons.bookmark_border, color: isFav ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8)), label: Text(isFav ? 'Favorit' : 'Subscribe', style: TextStyle(color: isFav ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8))), onPressed: toggleFav),
            ],
          ),
          const SizedBox(height: 12),
          Text(syn, maxLines: 5, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          const Text('Pilih Episode (+25 EXP):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(eps > 50 ? 50 : eps, (i) => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), side: const BorderSide(color: Color(0xFF38BDF8))),
              onPressed: () => openEp(i + 1),
              child: Text('Ep ${i + 1}', style: const TextStyle(color: Color(0xFF38BDF8))),
            )),
          ),
        ],
      ),
    );
  }
}


class PlayerPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int ep;
  const PlayerPage({super.key, required this.item, required this.ep});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  Timer? _exp24Timer;
  bool _epExpAwarded = false;

  void _startExp24Timer() {
    _exp24Timer?.cancel();
    _exp24Timer = Timer.periodic(const Duration(minutes: 24), (_) async {
      if (!mounted) return;
      final p = await SharedPreferences.getInstance();
      final nextExp = (p.getInt('exp') ?? 0) + 15;
      await p.setInt('exp', nextExp);
    });
  }

  Future<void> _awardEpisodeCompleteExp() async {
    if (_epExpAwarded || !mounted) return;
    _epExpAwarded = true;
    final p = await SharedPreferences.getInstance();
    final nextExp = (p.getInt('exp') ?? 0) + 25;
    await p.setInt('exp', nextExp);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      vp?.pause();
      webCtrl?.runJavaScript("document.querySelectorAll('video,audio').forEach(v=>{v.pause();v.muted=true;});");
    } else if (state == AppLifecycleState.resumed) {
      webCtrl?.runJavaScript("document.querySelectorAll('video').forEach(v=>{ if(false)if(v.duration>300)v.muted=false;});");
    }
  }
  String _allowedHost = '';
  static const String streamApiBase = 'http://191.222.39.242:3001';
  final List<String> servers = ['Server 1', 'Server 2', 'Server 3', 'Server 4'];
  final List<String> qualities = ['360p', '480p', '720p', '1080p'];
  final List<double> speeds = [1.0, 1.25, 1.5, 2.0];

  late int currentEp;
  VideoPlayerController? vp;
  WebViewController? webCtrl;
  bool useWebView = false;
  bool ready = false;
  bool showCtrl = true;
  bool locked = false;
  bool fullscreen = false;
  bool autonext = true;
  bool isNavigatingEp = false;

  String server = 'Server 1';
  String serverLabel = 'Server 1';
  String quality = '480p';
  double speed = 1.0;
  double bright = 0.85;
  double vol = 0.85;

  String userName = 'Warga Tempest';
  String userAvatar = '';
  int userExp = 0;
  bool userOwner = false;
  String activeBorder = 'b_slime';
  String activeBg = 'bg_slate';

  String statusMsg = 'Menyiapkan pemutar Tempest...';
  int loadToken = 0;
  final TextEditingController commentCtrl = TextEditingController();
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startExp24Timer();
    currentEp = widget.ep;
    loadUser();
    loadComments();
    initVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exp24Timer?.cancel();
    loadToken++;
    commentCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    vp?.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userName = p.getString('name') ?? 'Warga Tempest';
      userAvatar = p.getString('avatar') ?? '';
      userExp = p.getInt('exp') ?? 0;
      userOwner = p.getBool('owner') ?? false;
    });
  }

  String get _commentKey => 'comments_${widget.item['title']}_ep_$currentEp';

  Future<void> loadComments() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_commentKey) ?? [];
    if (!mounted) return;
    setState(() => comments = raw.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList());
  }

  Future<void> postComment() async {
    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;
    final r = RankHelper.getRank(userExp, userOwner);
    final entry = {
      'name': userName,
      'avatar': userAvatar,
      'lvl': r['lvl'],
      'title': r['title'],
      'isOwner': userOwner,
        'border': activeBorder,
        'bg': activeBg,
      'text': text,
      'time': 'Baru saja',
    };
    final p = await SharedPreferences.getInstance();
    final updated = [entry, ...comments];
    await p.setStringList(_commentKey, updated.map((e) => jsonEncode(e)).toList());
    commentCtrl.clear();
    if (!mounted) return;
    setState(() => comments = updated);
  }

  String _fmtDuration(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  bool _isDirectVideo(String url) {
    final u = url.toLowerCase();
    return u.contains('.mp4') || u.contains('.m3u8') || u.contains('.webm');
  }

  Future<Map<String, String>?> _fetchStream(String targetServer, int token) async {
    final base = streamApiBase.trim().replaceAll(RegExp(r'/+$'), '');
    final title = (widget.item['title'] ?? '').toString().trim();
    final srvIdx = servers.indexOf(targetServer).clamp(0, 3);

    Future<Map<String, dynamic>?> getJson(Uri u) async {
      try {
        final r = await http.get(u).timeout(const Duration(seconds: 15));
        if (!mounted || token != loadToken || r.statusCode != 200) return null;
        final j = jsonDecode(r.body);
        return j is Map<String, dynamic> ? j : null;
      } catch (_) {
        return null;
      }
    }

    try {
      final tMap = widget.item['title'] is Map ? widget.item['title'] as Map : {};
      final romajiTitle = (tMap['romaji'] ?? title).toString().trim();
      final engTitle = (tMap['english'] ?? '').toString().trim();
      final cleanRomaji = romajiTitle.replaceAll(RegExp(r'(\d+(st|nd|rd|th)\s*Season|Season\s*\d+|Part\s*\d+|[:!\-?])', caseSensitive: false), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      final cleanEng = engTitle.replaceAll(RegExp(r'(\d+(st|nd|rd|th)\s*Season|Season\s*\d+|Part\s*\d+|[:!\-?])', caseSensitive: false), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      final shortWords = cleanRomaji.split(' ').take(3).join(' ');
      final queries = <String>{title, romajiTitle, engTitle, cleanRomaji, cleanEng, shortWords}.where((q) => q.length >= 3).toList();
      final seasonMatch = RegExp(r'(\d+)(?:st|nd|rd|th)?\s*Season|Season\s*(\d+)', caseSensitive: false).firstMatch(romajiTitle);
      final targetSeason = seasonMatch?.group(1) ?? seasonMatch?.group(2) ?? '';

      String animeId = '';
      for (final qStr in queries) {
        final searchJson = await getJson(Uri.parse('$base/otakudesu/search?q=${Uri.encodeComponent(qStr)}'));
        final list = searchJson?['data']?['animeList'];
        if (list is List && list.isNotEmpty) {
          Map? bestMatch;
          for (final entry in list) {
            if (entry is Map) {
              final eTitle = (entry['title'] ?? '').toString().toLowerCase();
              if (targetSeason.isNotEmpty && (eTitle.contains('season $targetSeason') || eTitle.contains('s$targetSeason'))) {
                bestMatch = entry;
                break;
              }
              bestMatch ??= entry;
            }
          }
          animeId = (bestMatch?['animeId'] ?? '').toString().trim();
          if (animeId.isNotEmpty) break;
        }
      }
      if (animeId.isEmpty) return null;

      final animeJson = await getJson(Uri.parse('$base/otakudesu/anime/${Uri.encodeComponent(animeId)}'));
      final epList = animeJson?['data']?['details']?['episodeList'];
      if (epList is! List || epList.isEmpty) return null;

      String episodeId = '';
      final targetStr = currentEp.toString();
      for (final epItem in epList) {
        if (epItem is Map) {
          final epTitle = (epItem['title'] ?? '').toString().trim();
          final eid = (epItem['episodeId'] ?? '').toString().trim();
          if (eid.isNotEmpty && (epTitle == targetStr || RegExp(r'(?:^|\D)' + RegExp.escape(targetStr) + r'(?:$|\D)').hasMatch(epTitle))) {
            episodeId = eid;
            break;
          }
        }
      }
      if (episodeId.isEmpty) {
        final revIdx = (epList.length - currentEp).clamp(0, epList.length - 1);
        episodeId = (epList[revIdx]['episodeId'] ?? '').toString().trim();
      }
      if (episodeId.isEmpty) return null;

      final epJson = await getJson(Uri.parse('$base/otakudesu/episode/${Uri.encodeComponent(episodeId)}'));
      final epDetails = epJson?['data']?['details'];
      if (epDetails is! Map) return null;

      final qList = epDetails['server']?['qualityList'];
      if (qList is List && qList.isNotEmpty) {
        Map? chosenQual;
        final qClean = quality.replaceAll('p', '');
        for (final qItem in qList) {
          if (qItem is Map && (qItem['title'] ?? '').toString().contains(qClean)) {
            chosenQual = qItem;
            break;
          }
        }
        chosenQual ??= qList.first is Map ? qList.first as Map : null;

        final srvList = chosenQual?['serverList'];
        if (srvList is List && srvList.isNotEmpty) {
          final picked = srvList[srvIdx < srvList.length ? srvIdx : 0];
          if (picked is Map) {
            final serverId = (picked['serverId'] ?? '').toString().trim();
            final mName = (picked['title'] ?? targetServer).toString().trim();
            if (serverId.isNotEmpty) {
              final srvJson = await getJson(Uri.parse('$base/otakudesu/server/${Uri.encodeComponent(serverId)}'));
              final url = (srvJson?['data']?['details']?['url'] ?? '').toString().trim();
              if (url.startsWith('http')) return {'url': url, 'label': '$targetServer ($mName)'};
            }
          }
        }
      }
      final defUrl = (epDetails['defaultStreamingUrl'] ?? '').toString().trim();
      if (defUrl.startsWith('http')) return {'url': defUrl, 'label': '$targetServer (Default)'};
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> initVideo() async {
    final int token = ++loadToken;
    final String title = (widget.item['title'] ?? 'Anime').toString();

    setState(() {
      ready = false;
      useWebView = false;
      statusMsg = 'Memuat $server ($quality) • $title Ep $currentEp...';
    });

    final result = await _fetchStream(server, token);
    if (!mounted || token != loadToken) return;

    if (result == null || (result['url'] ?? '').isEmpty) {
      setState(() {
        statusMsg = 'Stream tidak tersedia pada $server (Ep $currentEp • $quality)';
      });
      return;
    }

    final chosenUrl = result['url']!;
    final chosenLabel = result['label'] ?? server;

    if (!_isDirectVideo(chosenUrl)) {
      await vp?.dispose();
      vp = null;
      final baseHost = Uri.tryParse(chosenUrl)?.host ?? '';
    final wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          final u = req.url.toLowerCase();
          const bad = ['dewaboss', 'slot', 'gacor', 'togel', 'casino', 'sbobet', 'maxwin', 'zeus', 'pragmatic', 'judol', 'undian', 'betting'];
          if (bad.any((b) => u.contains(b))) return NavigationDecision.prevent;
          final h = Uri.tryParse(req.url)?.host ?? '';
          if (baseHost.isNotEmpty && h.isNotEmpty && !h.contains(baseHost) && !u.contains('vidhide') && !u.contains('filemoon') && !u.contains('streamwish') && !u.contains('mp4upload') && !u.contains('blogger') && !u.contains('googlevideo')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (_) {
          webCtrl?.runJavaScript('''
            setInterval(function(){
              document.querySelectorAll('a[target="_blank"],[id*="ads"],[class*="ads"],[class*="popup"],[class*="overlay"],iframe[src*="ads"]').forEach(e=>e.remove());
              document.querySelectorAll('video').forEach(v=>{
                if(v.duration > 0 && v.duration < 90 && v.currentTime < v.duration - 0.5){
                  v.muted = true;
                  v.currentTime = v.duration;
                }
              });
            }, 800);
          ''');
        },
      ))
      ..loadRequest(Uri.parse(chosenUrl));
      if (!mounted || token != loadToken) return;
      setState(() {
        webCtrl = wc;
        useWebView = true;
        serverLabel = chosenLabel;
        ready = true;
      });
      return;
    }

    final oldController = vp;
    final newController = VideoPlayerController.networkUrl(Uri.parse(chosenUrl));
    try {
      await newController.initialize();
      if (!mounted || token != loadToken) {
        await newController.dispose();
        return;
      }
      await oldController?.dispose();
      vp = newController;
      webCtrl = null;
      useWebView = false;
      await vp!.setVolume(vol);
      await vp!.setPlaybackSpeed(speed);
      await vp!.play();

      vp!.addListener(() {
        if (!mounted || token != loadToken || vp == null) return;
        final val = vp!.value;
        if (ready && autonext && !isNavigatingEp && val.duration > Duration.zero && val.position >= val.duration) {
          final maxEp = (widget.item['episodes'] is int) ? widget.item['episodes'] as int : 12;
          if (currentEp < maxEp) {
            isNavigatingEp = true;
            _switchEpisode(currentEp + 1);
          }
        }
        if (mounted) setState(() {});
      });

      setState(() {
        serverLabel = chosenLabel;
        ready = true;
      });
    } catch (_) {
      await newController.dispose();
      if (!mounted || token != loadToken) return;
      final baseHost = Uri.tryParse(chosenUrl)?.host ?? '';
    final wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          final u = req.url.toLowerCase();
          const bad = ['dewaboss', 'slot', 'gacor', 'togel', 'casino', 'sbobet', 'maxwin', 'zeus', 'pragmatic', 'judol', 'undian', 'betting'];
          if (bad.any((b) => u.contains(b))) return NavigationDecision.prevent;
          final h = Uri.tryParse(req.url)?.host ?? '';
          if (baseHost.isNotEmpty && h.isNotEmpty && !h.contains(baseHost) && !u.contains('vidhide') && !u.contains('filemoon') && !u.contains('streamwish') && !u.contains('mp4upload') && !u.contains('blogger') && !u.contains('googlevideo')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (_) {
          webCtrl?.runJavaScript('''
            setInterval(function(){
              document.querySelectorAll('a[target="_blank"],[id*="ads"],[class*="ads"],[class*="popup"],[class*="overlay"],iframe[src*="ads"]').forEach(e=>e.remove());
              document.querySelectorAll('video').forEach(v=>{
                if(v.duration > 0 && v.duration < 90 && v.currentTime < v.duration - 0.5){
                  v.muted = true;
                  v.currentTime = v.duration;
                }
              });
            }, 800);
          ''');
        },
      ))
      ..loadRequest(Uri.parse(chosenUrl));
      setState(() {
        webCtrl = wc;
        useWebView = true;
        serverLabel = chosenLabel;
        ready = true;
      });
    }
  }

  Future<void> _switchEpisode(int nextEp) async {
    if (!mounted || nextEp == currentEp) return;
    await vp?.pause();
    final p = await SharedPreferences.getInstance();
    await p.setInt('exp', (p.getInt('exp') ?? 0) + 25);
    final hist = p.getStringList('history') ?? [];
    hist.removeWhere((e) => jsonDecode(e)['title'] == widget.item['title']);
    final entry = Map<String, dynamic>.from(widget.item)..['lastEp'] = nextEp;
    hist.insert(0, jsonEncode(entry));
    await p.setStringList('history', hist.take(40).toList());
    if (!mounted) return;
    setState(() {
      currentEp = nextEp;
      isNavigatingEp = false;
      userExp += 25;
    });
    await loadComments();
    await initVideo();
  }

  Future<void> _seekBy(int seconds) async {
    if (vp == null || !ready || useWebView) return;
    final dur = vp!.value.duration;
    final target = vp!.value.position + Duration(seconds: seconds);
    final clamped = target < Duration.zero ? Duration.zero : (target > dur ? dur : target);
    await vp!.seekTo(clamped);
  }

  Future<void> _toggleFullscreen() async {
    final next = !fullscreen;
    setState(() => fullscreen = next);
    if (next) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Widget _buildPlayerBox(String title, int maxEp) {
    final pos = vp?.value.position ?? Duration.zero;
    final dur = vp?.value.duration ?? Duration.zero;
    final isPlaying = vp?.value.isPlaying ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => showCtrl = !showCtrl),
      onVerticalDragUpdate: locked ? null : (details) {
        final width = MediaQuery.of(context).size.width;
        final delta = -(details.primaryDelta ?? 0) / 220.0;
        if (details.globalPosition.dx < width * 0.45) {
          setState(() => bright = (bright + delta).clamp(0.15, 1.0));
        } else if (details.globalPosition.dx > width * 0.55) {
          final nextVol = (vol + delta).clamp(0.0, 1.0);
          setState(() => vol = nextVol);
          vp?.setVolume(nextVol);
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: ready
                  ? (useWebView && webCtrl != null
                      ? WebViewWidget(controller: webCtrl!)
                      : (vp != null ? AspectRatio(aspectRatio: vp!.value.aspectRatio > 0 ? vp!.value.aspectRatio : 16 / 9, child: VideoPlayer(vp!)) : const SizedBox()))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF38BDF8)),
                          const SizedBox(height: 10),
                          Text(statusMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
            ),
            IgnorePointer(child: Container(color: Colors.black.withOpacity((1.0 - bright) * 0.75))),
            if (showCtrl)
              Positioned(
                top: 4, right: 4,
                child: IconButton(
                  icon: Icon(locked ? Icons.lock : Icons.lock_open, color: locked ? const Color(0xFFFBBF24) : Colors.white, size: 20),
                  onPressed: () => setState(() => locked = !locked),
                ),
              ),

            if (showCtrl && !locked) ...[
              Positioned(
                top: 4, left: 4, right: 48,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => fullscreen ? _toggleFullscreen() : Navigator.pop(context)),
                    Expanded(child: Text('$title • Ep $currentEp ($quality)', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              if (ready && !useWebView)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(iconSize: 28, icon: const Icon(Icons.replay_10, color: Colors.white), onPressed: () => _seekBy(-10)),
                      const SizedBox(width: 12),
                      IconButton(iconSize: 42, icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFF38BDF8)), onPressed: () async { if (vp == null) return; isPlaying ? await vp!.pause() : await vp!.play(); if (mounted) setState(() {}); }),
                      const SizedBox(width: 12),
                      IconButton(iconSize: 28, icon: const Icon(Icons.forward_10, color: Colors.white), onPressed: () => _seekBy(10)),
                    ],
                  ),
                ),
              Positioned(
                left: 8, right: 8, bottom: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ready && !useWebView && vp != null)
                      VideoProgressIndicator(vp!, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 2), colors: VideoProgressColors(playedColor: const Color(0xFF38BDF8), bufferedColor: Colors.white38, backgroundColor: Colors.white12)),
                    Row(
                      children: [
                        Text(useWebView ? serverLabel : '${_fmtDuration(pos)} / ${_fmtDuration(dur)}', style: TextStyle(color: useWebView ? const Color(0xFF38BDF8) : Colors.white, fontSize: 11)),
                        const Spacer(),
                        GestureDetector(onTap: () async { final u = await webCtrl?.currentUrl(); final link = u ?? ''; if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(link.isNotEmpty ? 'Link stream: $link' : 'Link belum siap'))); }, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.download, size: 16, color: Color(0xFFFFBBF2)))), const SizedBox(width: 4), DropdownButton<String>(value: server, isDense: true, dropdownColor: const Color(0xFF0F172A), underline: const SizedBox(), style: const TextStyle(color: Colors.white, fontSize: 11), items: servers.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (val) { if (val != null) { setState(() => server = val); initVideo(); } }),
                          const SizedBox(width: 6),
                          DropdownButton<String>(value: quality, isDense: true, dropdownColor: const Color(0xFF0F172A), underline: const SizedBox(), style: const TextStyle(color: Color(0xFFFFBBF2), fontSize: 11, fontWeight: FontWeight.bold), items: qualities.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(), onChanged: (val) { if (val != null) { setState(() => quality = val); initVideo(); } }),
                          const SizedBox(width: 4),
                          DropdownButton<double>(value: speed, isDense: true, dropdownColor: const Color(0xFF0F172A), underline: const SizedBox(), style: const TextStyle(color: Colors.white, fontSize: 11), items: speeds.map((sp) => DropdownMenuItem(value: sp, child: Text('${sp}x'))).toList(), onChanged: (val) { if (val != null) { setState(() => speed = val); vp?.setPlaybackSpeed(val); } }),
                        ]),
                        )),
                          ],
                        ))),
                        },
                          const SizedBox(width: 6),
                        }
                        ]]
