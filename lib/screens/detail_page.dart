import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player_page.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onProfileUpdated;

  const DetailPage({
    super.key,
    required this.item,
    this.onProfileUpdated,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _checkFav();
  }

  Future<void> _checkFav() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tempest_favorites_v1') ?? '[]';
    try {
      final list = jsonDecode(raw) as List;
      final id = widget.item['id'];
      if (!mounted) return;
      setState(() {
        _isFav = list.any((e) => e is Map && e['id'] == id);
      });
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tempest_favorites_v1') ?? '[]';
    List<dynamic> list = [];
    try {
      list = jsonDecode(raw) as List;
    } catch (_) {}

    final id = widget.item['id'];
    if (_isFav) {
      list.removeWhere((e) => e is Map && e['id'] == id);
    } else {
      list.insert(0, widget.item);
    }
    await prefs.setString('tempest_favorites_v1', jsonEncode(list));
    await prefs.setInt('fav_count', list.length);
    widget.onProfileUpdated?.call();

    if (!mounted) return;
    setState(() => _isFav = !_isFav);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFav
            ? 'Ditambahkan ke Koleksi Favorit!'
            : 'Dihapus dari Koleksi Favorit'),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  Future<void> _openEpisode(int ep) async {
    final prefs = await SharedPreferences.getInstance();
    final rawHist = prefs.getString('tempest_history_v1') ?? '[]';
    List<dynamic> hist = [];
    try {
      hist = jsonDecode(rawHist) as List;
    } catch (_) {}

    final id = widget.item['id'];
    hist.removeWhere((e) => e is Map && e['id'] == id);
    final entry = Map<String, dynamic>.from(widget.item);
    entry['lastEp'] = ep;
    hist.insert(0, entry);
    if (hist.length > 40) hist = hist.sublist(0, 40);
    await prefs.setString('tempest_history_v1', jsonEncode(hist));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          item: widget.item,
          initialEpisode: ep,
          onProfileUpdated: widget.onProfileUpdated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.item['title'] ?? 'Anime').toString();
    final img = (widget.item['img'] ?? '').toString();
    final score = (widget.item['score'] ?? 'N/A').toString();
    final synopsis =
        (widget.item['synopsis'] ?? 'Tidak ada sinopsis.').toString();
    final totalEps = (widget.item['episodes'] is int)
        ? widget.item['episodes'] as int
        : int.tryParse('${widget.item['episodes']}') ?? 12;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.bookmark : Icons.bookmark_border,
              color: _isFav ? const Color(0xFFFBBF24) : Colors.white,
            ),
            onPressed: _toggleFav,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: img.isNotEmpty
                    ? Image.network(
                        img,
                        width: 115,
                        height: 165,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 115,
                          height: 165,
                          color: const Color(0xFF111827),
                          child: const Icon(Icons.movie, color: Colors.white38),
                        ),
                      )
                    : Container(
                        width: 115,
                        height: 165,
                        color: const Color(0xFF111827),
                        child: const Icon(Icons.movie, color: Colors.white38),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$score / 10',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$totalEps Episode',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openEpisode(1),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'TONTON EPISODE 1',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0A0E1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Sinopsis',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            synopsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Daftar Episode',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalEps > 0 ? totalEps : 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (_, idx) {
              final ep = idx + 1;
              return InkWell(
                onTap: () => _openEpisode(ep),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E3A5F)),
                  ),
                  child: Text(
                    'Ep $ep',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
