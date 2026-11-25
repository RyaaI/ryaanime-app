import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [const HomeTab(), const ScheduleTab(), const SearchTab()];
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.blueGrey,
        onTap: (v) => setState(() => idx = v),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop_rounded), label: 'Tempest'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Jadwal'),
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
  String avatarPath = '';
  int exp = 0;
  bool isOwner = false;
  late Future<List> futureAnime;

  @override
  void initState() {
    super.initState();
    futureAnime = fetchTop();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      name = p.getString('name') ?? 'Warga Tempest';
      avatarPath = p.getString('avatar') ?? '';
      exp = p.getInt('exp') ?? 0;
      isOwner = p.getBool('owner') ?? false;
    });
  }

  Future<List> fetchTop() async {
    final res = await http.get(Uri.https('api.jikan.moe', '/v4/seasons/now', {'limit': '24'}));
    return jsonDecode(res.body)['data'] ?? [];
  }

  void openProfileDialog() {
    final nameCtrl = TextEditingController(text: name);
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Profil & Rank Tempest', style: TextStyle(color: Color(0xFF38BDF8))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: TextEditingController(text: avatarPath), onChanged: (v) async { final p = await SharedPreferences.getInstance(); await p.setString('avatar', v.trim()); setState(() => avatarPath = v.trim()); }, decoration: const InputDecoration(labelText: 'Link Foto / GIF Profil (Opsional)')),
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
              final ownerActive = isOwner || codeCtrl.text.trim() == 'RYAA-TEMPEST';
              await p.setString('name', newName);
              await p.setBool('owner', ownerActive);
              setState(() { name = newName; isOwner = ownerActive; });
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
                    backgroundImage: avatarPath.startsWith('http') ? NetworkImage(avatarPath) : null,
                    child: avatarPath.isEmpty ? const Icon(Icons.water_drop, color: Color(0xFF0B1120)) : null,
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
                IconButton(icon: const Icon(Icons.refresh, color: Color(0xFFFBBF24)), onPressed: () => setState(() { futureAnime = fetchTop(); })),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List>(
              future: futureAnime,
              builder: (c, s) {
                if (s.hasError) return Center(child: Text('Error: ${s.error}', style: const TextStyle(color: Colors.redAccent)));
                if (!s.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: s.data!.length,
                  itemBuilder: (ctx, i) => AnimeCard(item: s.data![i], onWatch: loadProfile),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});
  Future<List> fetchSched() async {
    final res = await http.get(Uri.https('api.jikan.moe', '/v4/schedules', {'limit': '24'}));
    return jsonDecode(res.body)['data'] ?? [];
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Rilis • RyaaNime'), backgroundColor: const Color(0xFF0F172A)),
      body: FutureBuilder<List>(
        future: fetchSched(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: s.data!.length,
            itemBuilder: (ctx, i) => AnimeCard(item: s.data![i]),
          );
        },
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
  List results = [];
  bool loading = false;
  void search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => loading = true);
    final res = await http.get(Uri.https('api.jikan.moe', '/v4/anime', {'q': q, 'limit': '21'}));
    setState(() { results = jsonDecode(res.body)['data'] ?? []; loading = false; });
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onSubmitted: search,
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
  final Map item;
  final VoidCallback? onWatch;
  const AnimeCard({super.key, required this.item, this.onWatch});
  @override
  Widget build(BuildContext context) {
    final img = item['images']?['jpg']?['image_url'] ?? '';
    final title = item['title'] ?? 'Anime';
    final score = item['score']?.toString() ?? 'N/A';
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
class DetailPage extends StatelessWidget {
  final Map item;
  const DetailPage({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'Anime';
    final syn = item['synopsis'] ?? 'Tidak ada sinopsis.';
    final eps = item['episodes'] ?? 12;
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 15)), backgroundColor: const Color(0xFF0F172A)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
          const SizedBox(height: 8),
          Text(syn, maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          const Text('Pilih Episode (+25 EXP):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(eps > 50 ? 50 : eps, (i) => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), side: const BorderSide(color: Color(0xFF38BDF8))),
              onPressed: () async {
                final p = await SharedPreferences.getInstance();
                await p.setInt('exp', (p.getInt('exp') ?? 0) + 25);
                final uri = Uri.https('://youtube.com', '/results', {'search_query': '$title episode ${i + 1} sub indo'});
                if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(title: '$title - Ep ${i + 1}', url: uri.toString())));
              },
              child: Text('Ep ${i + 1}', style: const TextStyle(color: Color(0xFF38BDF8))),
            )),
          ),
        ],
      ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final String title;
  final String url;
  const PlayerPage({super.key, required this.title, required this.url});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final WebViewController ctrl;
  @override
  void initState() {
    super.initState();
    ctrl = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadRequest(Uri.parse(widget.url));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontSize: 14)), backgroundColor: const Color(0xFF0F172A)), body: WebViewWidget(controller: ctrl));
  }
}
class DetailPage extends StatelessWidget {
  final Map item;
  const DetailPage({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'Anime';
    final syn = item['synopsis'] ?? 'Tidak ada sinopsis.';
    final eps = item['episodes'] ?? 12;
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 15)), backgroundColor: const Color(0xFF0F172A)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
          const SizedBox(height: 8),
          Text(syn, maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          const Text('Pilih Episode (+25 EXP):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(eps > 50 ? 50 : eps, (i) => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), side: const BorderSide(color: Color(0xFF38BDF8))),
              onPressed: () async {
                final p = await SharedPreferences.getInstance();
                await p.setInt('exp', (p.getInt('exp') ?? 0) + 25);
                final uri = Uri.https('://youtube.com', '/results', {'search_query': '$title episode ${i + 1} sub indo'});
                if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(title: '$title - Ep ${i + 1}', url: uri.toString())));
              },
              child: Text('Ep ${i + 1}', style: const TextStyle(color: Color(0xFF38BDF8))),
            )),
          ),
        ],
      ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final String title;
  final String url;
  const PlayerPage({super.key, required this.title, required this.url});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final WebViewController ctrl;
  @override
  void initState() {
    super.initState();
    ctrl = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadRequest(Uri.parse(widget.url));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontSize: 14)), backgroundColor: const Color(0xFF0F172A)), body: WebViewWidget(controller: ctrl));
  }
}
