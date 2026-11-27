import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayScreen extends StatefulWidget {
  final String animeTitle;
  final String initialEpisode;

  const PlayScreen({
    super.key,
    required this.animeTitle,
    this.initialEpisode = 'Episode 1',
  });

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  String _selectedResolution = '480p';
  int _selectedServer = 1;
  int _selectedEpisodeNumber = 1;
  String _activeCommentBg = 'Tempest Cyan';
  String _username = 'Warga Tempest';

  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> _comments = [
    {
      'author': 'Rimuru Tempest',
      'badge': 'FEDERASI TEMPEST',
      'text': 'Selamat datang di Federasi Jura Tempest, nikmati tontonannya!',
    },
  ];

  final List<String> _resolutions = const ['360p', '480p', '720p', '1080p'];

  @override
  void initState() {
    super.initState();
    _loadPlayPrefs();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _activeCommentBg =
          prefs.getString('active_comment_bg') ?? 'Tempest Cyan';
      _username = prefs.getString('username') ?? 'Warga Tempest';
    });
  }

  List<Color> _commentGradient(String bgName) {
    switch (bgName) {
      case 'Slime Mint':
        return const [Color(0xFF0F5C5E), Color(0xFF0A3642)];
      case 'Starlight Rose':
        return const [Color(0xFF6B2D5C), Color(0xFF1E3A5F)];
      case 'Storm Gold':
        return const [Color(0xFF6B4E16), Color(0xFF14354C)];
      default:
        return const [Color(0xFF0E4A6E), Color(0xFF0A2E47)];
    }
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, {
        'author': _username,
        'badge': 'WARGA TEMPEST',
        'text': text,
      });
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColors = _commentGradient(_activeCommentBg);

    return Scaffold(
      backgroundColor: const Color(0xFF091B29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2436),
        foregroundColor: const Color(0xFFE6F7FF),
        title: Text(
          widget.animeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            height: 215,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B2538), Color(0xFF071724)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 64,
                  color: Color(0xFF38BDF8),
                ),
                const SizedBox(height: 8),
                Text(
                  'Server $_selectedServer • $_selectedResolution',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8FD3F4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.animeTitle} - Episode $_selectedEpisodeNumber',
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE6F7FF),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Jalur $_selectedResolution',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF8FD3F4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D283D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'EXP: 24m',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5EEAD4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _resolutions.map((res) {
                    final active = _selectedResolution == res;
                    return ChoiceChip(
                      label: Text(res),
                      selected: active,
                      onSelected: (_) =>
                          setState(() => _selectedResolution = res),
                      selectedColor: const Color(0xFF18B6E8),
                      backgroundColor: const Color(0xFF0D283D),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? const Color(0xFF061624)
                            : const Color(0xFFB6DEEF),
                      ),
                      side: BorderSide(
                        color: active
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF1F4E6B),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [1, 2].map((srv) {
                    final active = _selectedServer == srv;
                    return Padding(
                      padding: EdgeInsets.only(right: srv == 1 ? 10 : 0),
                      child: ChoiceChip(
                        label: Text('Server $srv'),
                        selected: active,
                        onSelected: (_) =>
                            setState(() => _selectedServer = srv),
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF0D283D),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: active
                              ? const Color(0xFF061624)
                              : const Color(0xFFB6DEEF),
                        ),
                        side: BorderSide(
                          color: active
                              ? const Color(0xFF5EEAD4)
                              : const Color(0xFF1F4E6B),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Menyiapkan unduhan Episode $_selectedEpisodeNumber ($_selectedResolution)...',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Download',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE6F7FF),
                    side: const BorderSide(color: Color(0xFF1F4E6B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Episode',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE6F7FF),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 12,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final epNum = idx + 1;
                      final selected = _selectedEpisodeNumber == epNum;
                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedEpisodeNumber = epNum),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF18B6E8)
                                : const Color(0xFF0D283D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF1F4E6B),
                            ),
                          ),
                          child: Text(
                            '$epNum',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? const Color(0xFF061624)
                                  : const Color(0xFFB6DEEF),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Komentar Tempest',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE6F7FF),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Color(0xFFE6F7FF)),
                        decoration: InputDecoration(
                          hintText: 'Tulis komentar warga Tempest...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF7FAEC4),
                            fontSize: 13.5,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0D283D),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1F4E6B),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF38BDF8),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendComment,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._comments.map((c) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    constraints: const BoxConstraints(minHeight: 112),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: bgColors,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF5EEAD4).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF081C2B),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
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
                              Row(
                                children: [
                                  Text(
                                    c['author'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE6F7FF),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF081C2B)
                                          .withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c['badge'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5EEAD4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                c['text'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  color: Color(0xFFF0FAFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
