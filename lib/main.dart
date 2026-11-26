import 'dart:convert';
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
      home: const MainNav(),
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
    final imgCtrl = TextEditingController(text: avatarUrl);
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Profil & Rank Tempest', style: TextStyle(color: Color(0xFF38BDF8))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Link Foto / GIF Profil (Opsional)')),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Pengguna')),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kode Owner (RYAA-TEMPEST)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              final newName = nameCtrl.text.trim().isEmpty ? name : nameCtrl.text.trim();
              final newImg = imgCtrl.text.trim();
              final ownerActive = isOwner || codeCtrl.text.trim() == 'RYAA-TEMPEST';
              await p.setString('name', newName);
              await p.setString('avatar', newImg);
              await p.setBool('owner', ownerActive);
              setState(() { name = newName; avatarUrl = newImg; isOwner = ownerActive; });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
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
                    const Padding(
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
  final genres = ['Action', 'Fantasy', 'Adventure', 'Romance', 'Comedy', 'Magic', 'Supernatural', 'Sci-Fi'];

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

class _PlayerPageState extends State<PlayerPage> {
  static const String streamApiBase = 'http://191.222.39.242:3001';
  final List<String> servers = ['Server 1', 'Server 2', 'Server 3', 'Server 4'];
  final List<String> qualities = ['360p', '480p', '720p', '1080p'];
  final List<double> speeds = [1.0, 1.25, 1.5, 2.0];

  VideoPlayerController? vp;
  bool ready = false;
  bool showCtrl = true;
  bool locked = false;
  bool fullscreen = false;
  bool autonext = true;
  bool isNavigatingEp = false;

  String server = 'Server 1';
  String quality = '480p';
  double speed = 1.0;
  double bright = 0.85;
  double vol = 0.85;
  String userAvatar = '';
  String statusMsg = 'Menyiapkan pemutar Tempest...';
  int loadToken = 0;

  @override
  void initState() {
    super.initState();
    loadUser();
    initVideo();
  }

  @override
  void dispose() {
    loadToken++;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    vp?.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => userAvatar = p.getString('avatar') ?? '');
  }

  String _fmtDuration(Duration d) {
    final totalSec = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<String?> _fetchStreamUrlForServer(String targetServer, int token) async {
    if (streamApiBase == 'MASUKKAN_API_DISINI' || streamApiBase.trim().isEmpty) {
      return null;
    }
    final base = streamApiBase.trim().replaceAll(RegExp(r'/+$'), '');
    final title = (widget.item['title'] ?? '').toString().trim();
    final directId = (widget.item['animeId'] ?? widget.item['id'] ?? '').toString().trim();

    const platforms = ['otakudesu', 'oploverz', 'samehadaku', 'kuramanime'];
    final srvIdx = servers.indexOf(targetServer);
    final platform = (srvIdx >= 0 && srvIdx < platforms.length) ? platforms[srvIdx] : 'otakudesu';

    Future?> getJson(Uri u) async {
      try {
        final r = await http.get(u).timeout(const Duration(seconds: 15));
        if (!mounted || token != loadToken || r.statusCode != 200) return null;
        final j = jsonDecode(r.body);
        return j is Map<String, dynamic> ? j : null;
      } catch (_) {
        return null;
      }
    }

    String? extractUrl(dynamic v) {
      if (v == null) return null;
      final str = v.toString().trim();
      if (str.startsWith('http://') || str.startsWith('https://')) return str;
      return null;
    }

    try {
      String animeId = platform == 'otakudesu' ? directId : '';
      if (animeId.isEmpty && title.isNotEmpty) {
        final searchJson = await getJson(Uri.parse('$base/$platform/search?q=${Uri.encodeComponent(title)}'));
        final data = searchJson?['data'];
        final list = (data is Map ? (data['animeList'] ?? data['searchResults'] ?? data['animes']) : null);
        if (list is List && list.isNotEmpty && list.first is Map) {
          final first = list.first as Map;
          animeId = (first['animeId'] ?? first['id'] ?? first['slug'] ?? '').toString().trim();
        }
      }
      if (animeId.isEmpty || !mounted || token != loadToken) return null;

      final animeJson = await getJson(Uri.parse('$base/$platform/anime/${Uri.encodeComponent(animeId)}'));
      final animeData = animeJson?['data'];
      final epList = animeData is Map ? (animeData['episodeList'] ?? animeData['episodes']) : null;

      String episodeId = '';
      if (epList is List && epList.isNotEmpty) {
        final targetEpStr = widget.ep.toString();
        for (final epItem in epList) {
          if (epItem is Map) {
            final epTitle = (epItem['title'] ?? epItem['episode'] ?? '').toString().trim();
            final eid = (epItem['episodeId'] ?? epItem['id'] ?? epItem['slug'] ?? '').toString().trim();
            if (eid.isNotEmpty && (epTitle == targetEpStr || RegExp(r'(?:^|\D)' + RegExp.escape(targetEpStr) + r'(?:$|\D)').hasMatch(epTitle))) {
              episodeId = eid;
              break;
            }
          }
        }
        if (episodeId.isEmpty && epList.first is Map) {
          final firstEp = epList.first as Map;
          episodeId = (firstEp['episodeId'] ?? firstEp['id'] ?? firstEp['slug'] ?? '').toString().trim();
        }
      }
      if (episodeId.isEmpty || !mounted || token != loadToken) return null;

      final epJson = await getJson(Uri.parse('$base/$platform/episode/${Uri.encodeComponent(episodeId)}'));
      final epData = epJson?['data'];
      final details = (epData is Map && epData['details'] is Map) ? epData['details'] as Map : (epData is Map ? epData : null);
      if (details == null) return null;

      String? serverId;
      final qList = details['server'] is Map ? details['server']['qualityList'] : null;
      if (qList is List && qList.isNotEmpty) {
        Map? chosenQual;
        final qClean = quality.replaceAll('p', '').trim();
        for (final qItem in qList) {
          if (qItem is Map) {
            final qTitle = (qItem['title'] ?? '').toString();
            if (qTitle.contains(quality) || (qClean.isNotEmpty && qTitle.contains(qClean))) {
              chosenQual = qItem;
              break;
            }
          }
        }
        chosenQual ??= qList.first is Map ? qList.first as Map : null;

        final srvList = chosenQual?['serverList'];
        if (srvList is List && srvList.isNotEmpty && srvList.first is Map) {
          serverId = (srvList.first['serverId'] ?? '').toString().trim();
        }
      }

      if (serverId != null && serverId.isNotEmpty) {
        final srvJson = await getJson(Uri.parse('$base/$platform/server/${Uri.encodeComponent(serverId)}'));
        final srvDetails = srvJson?['data']?['details'];
        final streamUrl = extractUrl(srvDetails is Map ? srvDetails['url'] : srvJson?['data']?['url']);
        if (streamUrl != null) return streamUrl;
      }

      return extractUrl(details['defaultStreamingUrl'] ?? details['url'] ?? details['streamUrl']);
    } catch (_) {
      return null;
    }
  }

  Future<void> initVideo({bool autoFallback = true}) async {
    final int token = ++loadToken;
    final String title = (widget.item['title'] ?? 'Anime').toString();

    setState(() {
      ready = false;
      statusMsg = 'Memuat stream $title Ep ${widget.ep} ($server)...';
    });

    if (streamApiBase == 'MASUKKAN_API_DISINI' || streamApiBase.trim().isEmpty) {
      if (!mounted || token != loadToken) return;
      setState(() {
        statusMsg = 'API Stream belum terhubung (Ep ${widget.ep} • $quality • $server)';
      });
      return;
    }

    final startIdx = servers.indexOf(server).clamp(0, servers.length - 1);
    final candidateServers = autoFallback
        ? [
            servers[startIdx],
            for (int i = 0; i < servers.length; i++)
              if (i != startIdx) servers[i],
          ]
        : [servers[startIdx]];

    String? chosenUrl;
    String activeServer = server;

    for (final srv in candidateServers) {
      if (!mounted || token != loadToken) return;
      setState(() {
        statusMsg = 'Mencoba $srv • Ep ${widget.ep} ($quality)...';
      });
      final url = await _fetchStreamUrlForServer(srv, token);
      if (!mounted || token != loadToken) return;
      if (url != null && url.isNotEmpty) {
        chosenUrl = url;
        activeServer = srv;
        break;
      }
    }

    if (!mounted || token != loadToken) return;

    if (chosenUrl == null || chosenUrl.isEmpty) {
      setState(() {
        statusMsg = 'Stream tidak tersedia pada 4 server (Ep ${widget.ep} • $quality)';
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
      await vp!.setVolume(vol);
      await vp!.setPlaybackSpeed(speed);
      await vp!.play();

      vp!.addListener(() {
        if (!mounted || token != loadToken || vp == null) return;
        final val = vp!.value;
        if (ready &&
            autonext &&
            !isNavigatingEp &&
            val.duration > Duration.zero &&
            val.position >= val.duration) {
          final maxEp = (widget.item['episodes'] is int) ? widget.item['episodes'] as int : 12;
          if (widget.ep < maxEp) {
            isNavigatingEp = true;
            _goToEpisode(widget.ep + 1);
          }
        }
        if (mounted) setState(() {});
      });

      setState(() {
        server = activeServer;
        ready = true;
      });
    } catch (_) {
      await newController.dispose();
      if (!mounted || token != loadToken) return;
      setState(() {
        ready = false;
        statusMsg = 'Gagal memutar video dari $activeServer (Ep ${widget.ep})';
      });
    }
  }

  Future<void> _goToEpisode(int nextEp) async {
    if (!mounted) return;
    await vp?.pause();
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerPage(item: widget.item, ep: nextEp),
      ),
    );
  }

  Future<void> _seekBy(int seconds) async {
    if (vp == null || !ready) return;
    final dur = vp!.value.duration;
    final target = vp!.value.position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > dur ? dur : target);
    await vp!.seekTo(clamped);
  }

  Future<void> _toggleFullscreen() async {
    final next = !fullscreen;
    setState(() => fullscreen = next);
    if (next) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.item['title'] ?? 'Anime').toString();
    final maxEp = (widget.item['episodes'] is int) ? widget.item['episodes'] as int : 12;
    final pos = vp?.value.position ?? Duration.zero;
    final dur = vp?.value.duration ?? Duration.zero;
    final isPlaying = vp?.value.isPlaying ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !fullscreen,
        bottom: !fullscreen,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => showCtrl = !showCtrl);
          },
          onVerticalDragUpdate: locked
              ? null
              : (details) {
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: ready && vp != null
                    ? AspectRatio(
                        aspectRatio: vp!.value.aspectRatio > 0
                            ? vp!.value.aspectRatio
                            : 16 / 9,
                        child: VideoPlayer(vp!),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF38BDF8)),
                            const SizedBox(height: 14),
                            Text(
                              statusMsg,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
              ),
              IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity((1.0 - bright) * 0.75),
                ),
              ),
              if (showCtrl)
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: Icon(
                      locked ? Icons.lock : Icons.lock_open,
                      color: locked ? const Color(0xFFFFBBF24) : Colors.white,
                    ),
                    onPressed: () => setState(() => locked = !locked),
                  ),
                ),
              if (showCtrl && !locked) ...[
                Positioned(
                  top: 10,
                  left: 8,
                  right: 56,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Episode ${widget.ep}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 80,
                  bottom: 95,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(bright * 100).round()}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: bright,
                            min: 0.15,
                            max: 1.0,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                            onChanged: (v) => setState(() => bright = v),
                          ),
                        ),
                      ),
                      const Icon(Icons.wb_sunny, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 80,
                  bottom: 95,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(vol * 100).round()}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: vol,
                            min: 0.0,
                            max: 1.0,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                            onChanged: (v) {
                              setState(() => vol = v);
                              vp?.setVolume(v);
                            },
                          ),
                        ),
                      ),
                      Icon(
                        vol == 0 ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 34,
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () => _seekBy(-10),
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        iconSize: 52,
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          if (!ready || vp == null) return;
                          if (isPlaying) {
                            await vp!.pause();
                          } else {
                            await vp!.play();
                          }
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        iconSize: 34,
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () => _seekBy(10),
                      ),
                      if (widget.ep < maxEp) ...[
                        const SizedBox(width: 14),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 34,
                              icon: const Icon(Icons.skip_next, color: Colors.white),
                              onPressed: () => _goToEpisode(widget.ep + 1),
                            ),
                            Text(
                              'Episode ${widget.ep + 1}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ready && vp != null)
                        VideoProgressIndicator(
                          vp!,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          colors: VideoProgressColors(
                            playedColor: Color(0xFFEF4444),
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      Row(
                        children: [
                          Text(
                            '${_fmtDuration(pos)} / ${_fmtDuration(dur)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: server,
                            dropdownColor: const Color(0xFF0F172A),
                            underline: const SizedBox(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: servers
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => server = val);
                              initVideo(autoFallback: true);
                            },
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => autonext = !autonext),
                            child: Text(
                              'Autonext',
                              style: TextStyle(
                                color: autonext ? const Color(0xFF38BDF8) : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: quality,
                            dropdownColor: const Color(0xFF0F172A),
                            underline: const SizedBox(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: qualities
                                .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => quality = val);
                              initVideo(autoFallback: true);
                            },
                          ),
                          const SizedBox(width: 6),
                          DropdownButton<double>(
                            value: speed,
                            dropdownColor: const Color(0xFF0F172A),
                            underline: const SizedBox(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: speeds
                                .map((sp) => DropdownMenuItem(value: sp, child: Text('${sp}x')))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => speed = val);
                              vp?.setPlaybackSpeed(val);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: _toggleFullscreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
