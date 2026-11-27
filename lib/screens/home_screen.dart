import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/stream_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenMenu;
  final Function(Map<String, String> anime)? onOpenAnime;

  const HomeScreen({
    super.key,
    required this.onOpenMenu,
    this.onOpenAnime,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'Warga Tempest';
  String _avatarPath = '';
  String _activeBorder = 'Slime Cyan';
  int _level = 1;
  int _exp = 0;
  String _searchQuery = '';
  List> _routerSearchResults = const [];
  bool _isSearchingRouter = false;
  Timer? _searchDebounce;
  int _searchToken = 0;
  String _selectedGenre = 'Semua';

  final List<String> _genres = const [
    'Semua',
    'Action',
    'Fantasy',
    'Adventure',
    'Comedy',
    'Isekai',
  ];

  final List> _catalog = const [
    {
      'title': 'Tensei Shitara Slime Datta Ken',
      'episode': 'Episode 24',
      'genre': 'Fantasy',
      'tag': 'Populer',
    },
    {
      'title': 'Tensura Nikki: Slime Seikatsu',
      'episode': 'Episode 12',
      'genre': 'Comedy',
      'tag': 'Ongoing',
    },
    {
      'title': 'KonoSuba: God’s Blessing',
      'episode': 'Episode 10',
      'genre': 'Adventure',
      'tag': 'Populer',
    },
    {
      'title': 'Mushoku Tensei: Jobless Reincarnation',
      'episode': 'Episode 23',
      'genre': 'Isekai',
      'tag': 'Ongoing',
    },
    {
      'title': 'Solo Leveling',
      'episode': 'Episode 12',
      'genre': 'Action',
      'tag': 'Populer',
    },
    {
      'title': 'Frieren: Beyond Journey’s End',
      'episode': 'Episode 28',
      'genre': 'Fantasy',
      'tag': 'Ongoing',
    },
  ];

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    setState(() {
      _searchQuery = value;
      if (trimmed.length < 2) {
        _routerSearchResults = const [];
        _isSearchingRouter = false;
      } else {
        _isSearchingRouter = true;
      }
    });
    if (trimmed.length < 2) return;
    final currentToken = ++_searchToken;
    _searchDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final raw = await StreamService.searchBothRouters(trimmed);
        if (!mounted || currentToken != _searchToken) return;
        final mapped = raw.map>((m) {
          final src = (m['source'] ?? 'router').toString().trim();
          final srcLabel = src.isEmpty ? 'Router' : src[0].toUpperCase() + src.substring(1);
          return {
            'title': (m['title'] ?? 'Anime').toString(),
            'animeId': (m['animeId'] ?? '').toString(),
            'source': src,
            'poster': (m['poster'] ?? '').toString(),
            'episode': (m['episode'] ?? 'Tersedia').toString(),
            'genre': 'Semua',
            'tag': srcLabel,
          };
        }).toList();
        setState(() {
          _routerSearchResults = mapped;
          _isSearchingRouter = false;
        });
      } catch (_) {
        if (!mounted || currentToken != _searchToken) return;
        setState(() {
          _routerSearchResults = const [];
          _isSearchingRouter = false;
        });
      }
    });
  }
  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _loadProfileState();
  }

  Future<void> _loadProfileState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString('username') ?? 'Warga Tempest';
      _avatarPath = prefs.getString('avatar_path') ?? '';
      _activeBorder = prefs.getString('active_border') ?? 'Slime Cyan';
      _level = prefs.getInt('user_level') ?? 1;
      _exp = prefs.getInt('user_exp') ?? 0;
    });
  }

  Color _borderColorFor(String borderName) {
    switch (borderName) {
      case 'Rimuru Aura':
        return const Color(0xFF5EEAD4);
      case 'Veldora Storm':
        return const Color(0xFFFACC15);
      case 'Milim Starlight':
        return const Color(0xFFF472B6);
      default:
        return const Color(0xFF38BDF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int expTarget = 2500;
    final double expProgress = (_exp % expTarget) / expTarget;

    final trimmedQuery = _searchQuery.trim();
    final queryLower = trimmedQuery.toLowerCase();
    final hasRouterResults = trimmedQuery.length >= 2 && _routerSearchResults.isNotEmpty;
    final sourceList = hasRouterResults ? _routerSearchResults : _catalog;
    final filteredList = sourceList.where((item) {
      final matchesGenre = _selectedGenre == 'Semua' ||
          item['genre'] == _selectedGenre ||
          hasRouterResults;
      final titleLower = (item['title'] ?? '').toLowerCase();
      final matchesQuery = trimmedQuery.isEmpty ||
          hasRouterResults ||
          titleLower.contains(queryLower);
      return matchesGenre && matchesQuery;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF0D283D),
      onRefresh: _loadProfileState,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          // Kartu Profil + Tombol Menu Garis Tiga di pojok kanan atas
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF123650),
                  Color(0xFF0C2436),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _borderColorFor(_activeBorder),
                          width: 2.5,
                        ),
                        color: const Color(0xFF081C2B),
                      ),
                      child: ClipOval(
                        child: _avatarPath.isNotEmpty &&
                                File(_avatarPath).existsSync()
                            ? Image.file(
                                File(_avatarPath),
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/login_logo.png',
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE6F7FF),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level $_level • $_activeBorder',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8FD3F4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onOpenMenu,
                      tooltip: 'Menu',
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFFE6F7FF),
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EXP Tempest',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF9BC4D8),
                      ),
                    ),
                    Text(
                      '$_exp / $expTarget',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5EEAD4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: expProgress.clamp(0.04, 1.0),
                    minHeight: 7,
                    backgroundColor: const Color(0xFF081C2B),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Kotak Pencarian
          TextField(
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Color(0xFFE6F7FF), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari anime favoritmu...',
              hintStyle: const TextStyle(color: Color(0xFF7FAEC4), fontSize: 13.5),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF38BDF8),
              ),
              filled: true,
              fillColor: const Color(0xFF0D283D),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1F4E6B)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF38BDF8),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Genre
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _genres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = _genres[index];
                final active = _selectedGenre == genre;
                return ChoiceChip(
                  label: Text(genre),
                  selected: active,
                  onSelected: (_) => setState(() => _selectedGenre = genre),
                  selectedColor: const Color(0xFF18B6E8),
                  backgroundColor: const Color(0xFF0D283D),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? const Color(0xFF061624)
                        : const Color(0xFFB6DEEF),
                  ),
                  side: BorderSide(
                    color: active
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF1F4E6B),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Judul Katalog Gabungan
          const Text(
            'Katalog Federasi Tempest',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE6F7FF),
            ),
          ),
          const SizedBox(height: 10),

          // Grid Katalog Anime
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.76,
            ),
            itemBuilder: (context, index) {
              final anime = filteredList[index];
              return InkWell(
                onTap: () => widget.onOpenAnime?.call(anime),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D283D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E4661)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF174563),
                                Color(0xFF0B2233),
                              ],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Image.asset(
                                    'assets/icons/home.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF081C2B)
                                        .withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    anime['tag'] ?? 'Anime',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5EEAD4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anime['title'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE6F7FF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${anime['episode']} • ${anime['genre']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8FD3F4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
