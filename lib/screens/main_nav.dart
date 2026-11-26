import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tempest_store.dart';
import 'anime_card.dart';
import 'auth_gate.dart';
import 'detail_page.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _tabIndex = 0;

  // State profil global yang sinkron di header, modal profil, dan komentar
  String _username = 'Warga Tempest';
  String _avatarPath = '';
  String _borderId = 'b_slime';
  String _bgId = 'bg_slate';
  bool _isOwner = false;
  int _exp = 0;
  int _watchedCount = 0;
  int _favCount = 0;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  Future<void> _reloadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString('username') ?? 'Warga Tempest';
      _avatarPath = prefs.getString('avatar_path') ?? '';
      _borderId = prefs.getString('active_border') ?? 'b_slime';
      _bgId = prefs.getString('active_bg') ?? 'bg_slate';
      _isOwner = prefs.getBool('is_owner') ?? false;
      _exp = prefs.getInt('exp') ?? 0;
      _watchedCount = prefs.getInt('watched_episodes_count') ?? 0;
      _favCount = prefs.getInt('fav_count') ?? 0;
      _commentCount = prefs.getInt('comment_count') ?? 0;
    });
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          item: item,
          onProfileUpdated: _reloadProfile,
        ),
      ),
    ).then((_) => _reloadProfile());
  }

  void _openProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProfileModal(
        username: _username,
        avatarPath: _avatarPath,
        borderId: _borderId,
        bgId: _bgId,
        isOwner: _isOwner,
        exp: _exp,
        watchedCount: _watchedCount,
        favCount: _favCount,
        commentCount: _commentCount,
        onChanged: _reloadProfile,
        onLogout: () async {
          await SessionManager.logout();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AuthGate(onAuthenticated: () => const MainNav()),
            ),
            (_) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rank = RankHelper.getRank(_exp, _isOwner);
    final rankTitle = rank['title'].toString();
    final rankLvl = rank['lvl'].toString();
    final rankColor = rank['color'] as Color;
    final rankProg = (rank['prog'] as double).clamp(0.0, 1.0);

    final pages = [
      _HomeTab(onOpenDetail: _openDetail),
      _ScheduleTab(onOpenDetail: _openDetail),
      _HistoryTab(onOpenDetail: _openDetail),
      _SearchTab(onOpenDetail: _openDetail),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header Warga Tempest
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _openProfileModal,
                    child: TempestStore.buildAvatar(
                      _avatarPath,
                      _borderId,
                      radius: 22,
                      isOwner: _isOwner,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openProfileModal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: rankColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: rankColor),
                                ),
                                child: Text(
                                  'Lv.$rankLvl',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: rankColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rankTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: rankColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: rankProg,
                              minHeight: 4,
                              backgroundColor: const Color(0xFF1E293B),
                              valueColor: AlwaysStoppedAnimation(rankColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded,
                        color: Color(0xFF38BDF8)),
                    onPressed: _openProfileModal,
                  ),
                ],
              ),
            ),
            // Banner Versi Demo + Lapor Bug + Grup WA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF111827),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 15, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Versi Demo RyaaNime • Lapor bug / gabung komunitas:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(
                          'mailto:ryaaeulah12@gmail.com?subject=Bug%20Report%20RyaaNime'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text(
                      'Lapor',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF87171),
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(
                          'https://chat.whatsapp.com/Jm3MgGSBiCJFO2PgQfMjMg'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text(
                      'Grup WA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: pages[_tabIndex]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFF38BDF8).withOpacity(0.22),
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop, color: Color(0xFF38BDF8)),
            label: 'Tempest',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF38BDF8)),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF38BDF8)),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: Color(0xFF38BDF8)),
            label: 'Cari',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final void Function(Map<String, dynamic>) onOpenDetail;
  const _HomeTab({required this.onOpenDetail});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late Future<List<dynamic>> _futureTrending;

  @override
  void initState() {
    super.initState();
    _futureTrending = _load();
  }

  Future<List<dynamic>> _load() {
    const q = r'''
      query {
        Page(page: 1, perPage: 24) {
          media(type: ANIME, sort: TRENDING_DESC, isAdult: false) {
            id
            title { romaji english }
            averageScore
            description
            episodes
            nextAiringEpisode { episode }
            coverImage { large }
          }
        }
      }
    ''';
    return AniService.queryMedia(q, {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _futureTrending,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: ElevatedButton(
              onPressed: () => setState(() => _futureTrending = _load()),
              child: const Text('Muat Ulang Katalog'),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() => _futureTrending = _load()),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (_, i) => AnimeCard(
              item: list[i],
              onTap: () => widget.onOpenDetail(list[i]),
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleTab extends StatefulWidget {
  final void Function(Map<String, dynamic>) onOpenDetail;
  const _ScheduleTab({required this.onOpenDetail});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  int _selectedDay = DateTime.now().weekday % 7;
  late Future<List<dynamic>> _futureWeek;
  static const _days = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu'
  ];

  @override
  void initState() {
    super.initState();
    _futureWeek = _fetchWeek();
  }

  Future<List<dynamic>> _fetchWeek() async {
    final now = DateTime.now().toUtc();
    final start =
        now.subtract(Duration(days: now.weekday % 7)).millisecondsSinceEpoch ~/
            1000;
    final end = start + (7 * 86400);
    final res = await http.post(
      Uri.parse('https://graphql.anilist.co/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query':
            r'query ($s: Int, $e: Int) { Page(perPage: 50) { airingSchedules(airingAt_greater: $s, airingAt_lesser: $e, sort: TIME) { airingAt episode media { id title { romaji english } averageScore description episodes coverImage { large } isAdult } } } }',
        'variables': {'s': start, 'e': end},
      }),
    );
    final list =
        jsonDecode(res.body)['data']?['Page']?['airingSchedules'] as List? ?? [];
    return list.where((x) => x['media']?['isAdult'] != true).map((x) {
      final m = x['media'];
      final dt = DateTime.fromMillisecondsSinceEpoch(
              (x['airingAt'] as int) * 1000,
              isUtc: true)
          .add(const Duration(hours: 7));
      return <String, dynamic>{
        'day': dt.weekday % 7,
        'time':
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB',
        'ep': x['episode'] ?? 1,
        'id': m['id'] ?? 0,
        'title': m['title']?['romaji'] ?? m['title']?['english'] ?? 'Anime',
        'score': m['averageScore'] != null
            ? (m['averageScore'] / 10).toStringAsFixed(1)
            : 'N/A',
        'synopsis': (m['description'] ?? 'Tidak ada sinopsis.')
            .toString()
            .replaceAll(RegExp(r'<[^>]*>'), ''),
        'episodes': m['episodes'] ?? (x['episode'] ?? 12),
        'img': m['coverImage']?['large'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final active = _selectedDay == i;
              return ChoiceChip(
                label: Text(_days[i]),
                selected: active,
                onSelected: (_) => setState(() => _selectedDay = i),
              );
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _futureWeek,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                );
              }
              final items = (snap.data ?? [])
                  .where((e) => e['day'] == _selectedDay)
                  .toList();
              if (items.isEmpty) {
                return const Center(
                  child: Text('Belum ada jadwal rilis hari ini.',
                      style: TextStyle(color: Colors.white60)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final it = items[i];
                  return ListTile(
                    tileColor: const Color(0xFF111827),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF1E3A5F)),
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        it['img'].toString(),
                        width: 46,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.movie, color: Colors.white38),
                      ),
                    ),
                    title: Text(
                      it['title'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Episode ${it['ep']} • ${it['time']}',
                      style: const TextStyle(
                          color: Color(0xFF38BDF8), fontSize: 12),
                    ),
                    onTap: () => widget.onOpenDetail(it),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatefulWidget {
  final void Function(Map<String, dynamic>) onOpenDetail;
  const _HistoryTab({required this.onOpenDetail});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> parseList(String key) {
      try {
        final raw = prefs.getString(key) ?? '[]';
        return (jsonDecode(raw) as List)
            .whereType()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } catch (_) {
        return [];
      }
    }

    if (!mounted) return;
    setState(() {
      _history = parseList('tempest_history_v1');
      _favorites = parseList('tempest_favorites_v1');
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadLists,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Koleksi Favorit',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          if (_favorites.isEmpty)
            const Text('Belum ada anime favorit tersimpan.',
                style: TextStyle(color: Colors.white54))
          else
            SizedBox(
              height: 195,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => SizedBox(
                  width: 125,
                  child: AnimeCard(
                    item: _favorites[i],
                    onTap: () => widget.onOpenDetail(_favorites[i]),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Riwayat Tontonan',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            const Text('Belum ada riwayat tontonan.',
                style: TextStyle(color: Colors.white54))
          else
            for (final h in _history)
              Card(
                color: const Color(0xFF111827),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      (h['img'] ?? '').toString(),
                      width: 44,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.movie, color: Colors.white38),
                    ),
                  ),
                  title: Text(
                    (h['title'] ?? 'Anime').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Terakhir ditonton: Episode ${h['lastEp'] ?? 1}',
                    style: const TextStyle(color: Color(0xFF38BDF8)),
                  ),
                  onTap: () => widget.onOpenDetail(h),
                ),
              ),
        ],
      ),
    );
  }
}

class _SearchTab extends StatefulWidget {
  final void Function(Map<String, dynamic>) onOpenDetail;
  const _SearchTab({required this.onOpenDetail});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _searchCtrl = TextEditingController();
  String _selectedGenre = '';
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  static const List<String> _genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Ecchi',
    'Fantasy',
    'Horror',
    'Mahou Shoujo',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ];

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final kw = _searchCtrl.text.trim();
    const q = r'''
      query ($search: String, $genre: String) {
        Page(page: 1, perPage: 24) {
          media(type: ANIME, search: $search, genre: $genre, sort: POPULARITY_DESC, isAdult: false) {
            id
            title { romaji english }
            averageScore
            description
            episodes
            nextAiringEpisode { episode }
            coverImage { large }
          }
        }
      }
    ''';
    final vars = <String, dynamic>{};
    if (kw.isNotEmpty) vars['search'] = kw;
    if (_selectedGenre.isNotEmpty) vars['genre'] = _selectedGenre;

    try {
      final res = await AniService.queryMedia(q, vars);
      if (!mounted) return;
      setState(() {
        _results = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _runSearch(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cari judul anime...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded,
                    color: Color(0xFF38BDF8)),
                onPressed: _runSearch,
              ),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _genres.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, idx) {
              final g = idx == 0 ? '' : _genres[idx - 1];
              final label = idx == 0 ? 'Semua Genre' : g;
              final active = _selectedGenre == g;
              return ChoiceChip(
                label: Text(label),
                selected: active,
                onSelected: (_) {
                  setState(() => _selectedGenre = g);
                  _runSearch();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _results.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (_, i) => AnimeCard(
                    item: _results[i],
                    onTap: () => widget.onOpenDetail(_results[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProfileModal extends StatefulWidget {
  final String username;
  final String avatarPath;
  final String borderId;
  final String bgId;
  final bool isOwner;
  final int exp;
  final int watchedCount;
  final int favCount;
  final int commentCount;
  final Future<void> Function() onChanged;
  final VoidCallback onLogout;

  const _ProfileModal({
    required this.username,
    required this.avatarPath,
    required this.borderId,
    required this.bgId,
    required this.isOwner,
    required this.exp,
    required this.watchedCount,
    required this.favCount,
    required this.commentCount,
    required this.onChanged,
    required this.onLogout,
  });

  @override
  State<_ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<_ProfileModal> {
  late String _avatar;
  late String _border;
  late String _bg;
  late bool _owner;
  late int _exp;
  final _secretCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _avatar = widget.avatarPath;
    _border = widget.borderId;
    _bg = widget.bgId;
    _owner = widget.isOwner;
    _exp = widget.exp;
  }

  @override
  void dispose() {
    _secretCtrl.dispose();
    super.dispose();
  }

  /// Pilih foto atau GIF dari galeri dan salin ke folder permanen aplikasi
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final docDir = Directory('/data/user/0/com.ryaai.ryaanime/files');
    if (!docDir.existsSync()) docDir.createSync(recursive: true);
    final ext = picked.path.split('.').last;
    final destPath =
        '${docDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(picked.path).copy(destPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_path', destPath);
    await SessionManager.persistActiveProfile();
    await widget.onChanged();
    await _reloadProfile();

    if (!mounted) return;
    setState(() => _avatar = destPath);
  }

  int _requiredLevelForKey(String key) {
    if (key.contains('nihility') || key.contains('turnnull')) return 40;
    if (key.contains('divinity') || key.contains('sovereign')) return 25;
    if (key.contains('octagram') || key.contains('throne')) return 15;
    if (key.contains('frost') || key.contains('storm')) return 10;
    if (key.contains('sage') || key.contains('matrix')) return 6;
    if (key.contains('kijin') || key.contains('ember')) return 3;
    return 1;
  }

  bool _isCosmeticUnlocked(dynamic meta, [dynamic key = '']) {
    if (_owner) return true;
    final k = key.toString();
    if (k.contains('owner')) return false;
    int reqLevel = 0;
    int? reqExp;
    if (meta is Map) {
      final rawReq = meta['minLevel'] ?? meta['level'] ?? meta['reqLevel'] ?? meta['lv'] ?? 0;
      reqLevel = rawReq is int ? rawReq : int.tryParse(rawReq.toString()) ?? 0;
      final rawExp = meta['minExp'] ?? meta['exp'] ?? meta['reqExp'];
      if (rawExp != null) {
        reqExp = rawExp is int ? rawExp : int.tryParse(rawExp.toString()) ?? 0;
      }
    }
    final curLevel = (widget.exp ~/ 100) + 1;
    if (reqExp != null && widget.exp < reqExp) return false;
    return curLevel >= reqLevel;
  }

  Future<void> _selectBorder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_border', id);
    await SessionManager.persistActiveProfile();
    await widget.onChanged();
    await _reloadProfile();
    if (!mounted) return;
    setState(() => _border = id);
  }

  Future<void> _selectBg(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_bg', id);
    await SessionManager.persistActiveProfile();
    await widget.onChanged();
    await _reloadProfile();
    if (!mounted) return;
    setState(() => _bg = id);
  }

  Future<void> _activateSecret() async {
    if (TempestStore.verifyOwnerSecret(_secretCtrl.text)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_owner', true);
      await prefs.setString('active_border', 'b_owner');
      await prefs.setString('active_bg', 'bg_owner');
      await SessionManager.persistActiveProfile();
      await widget.onChanged();
    await _reloadProfile();
      if (!mounted) return;
      setState(() {
        _owner = true;
        _border = 'b_owner';
        _bg = 'bg_owner';
      });
      _secretCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode Rahasia aktif! Status Sovereign Founder dibuka.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode Rahasia tidak valid.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = RankHelper.getRank(_exp, _owner);
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                TempestStore.buildAvatar(_avatar, _border,
                    radius: 42, isOwner: _owner),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Color(0xFF0A0E1A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              widget.username,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
          Center(
            child: Text(
              '${rank['title']} • $_exp EXP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rank['color'] as Color,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Border Avatar',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TempestStore.borders.entries.map((e) {
              if (e.key == 'b_owner' && !_owner) {
                return const SizedBox.shrink();
              }
              final selected = _border == e.key;
              return ChoiceChip(
                label: Text(e.value['name'].toString()),
                selected: selected,
                onSelected: _isCosmeticUnlocked(e.value, e.key.toString()) ? (_) => _selectBorder(e.key) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Background Kartu Komentar',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TempestStore.backgrounds.entries.map((e) {
              if (e.key == 'bg_owner' && !_owner) {
                return const SizedBox.shrink();
              }
              final selected = _bg == e.key;
              return ChoiceChip(
                label: Text(e.value['name'].toString()),
                selected: selected,
                onSelected: _isCosmeticUnlocked(e.value, e.key.toString()) ? (_) => _selectBg(e.key) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Quest Federasi Tempest',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          for (final q in TempestStore.quests)
            Builder(builder: (_) {
              final type = q['type'];
              final target = q['target'] as int;
              int cur = widget.watchedCount;
              if (type == 'fav') cur = widget.favCount;
              if (type == 'comment') cur = widget.commentCount;
              final done = cur >= target || _owner;
              return Card(
                color: const Color(0xFF0F172A),
                child: ListTile(
                  title: Text(
                    '${q['rank']} • ${q['title']}',
                    style: TextStyle(
                      color: Color(q['color'] as int),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${q['desc']} ($cur/$target) • +${q['exp']} EXP',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? const Color(0xFF34D399) : Colors.white38,
                  ),
                ),
              );
            }),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _secretCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Aktivasi Kode Rahasia',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _activateSecret,
                child: const Text('Aktifkan'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
            label: const Text(
              'Keluar Akun (Logout)',
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        ],
      ),
    );
  }
}
