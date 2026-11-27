import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestScreen extends StatefulWidget {
  final VoidCallback onExitFullScreen;
  final VoidCallback? onStateChanged;

  const QuestScreen({
    super.key,
    required this.onExitFullScreen,
    this.onStateChanged,
  });

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  int _activeTab = 0;
  String _selectedBorder = 'Slime Cyan';
  String _selectedCommentBg = 'Tempest Cyan';
  int _exp = 0;
  final Set<String> _claimedIds = {};

  final List<Map<String, dynamic>> _quests = const [
    {
      'id': 'q1',
      'title': 'Menjelajah Gerbang Tempest',
      'desc': 'Masuk dan periksa katalog anime hari ini.',
      'exp': 250,
    },
    {
      'id': 'q2',
      'title': 'Penonton Setia 24 Menit',
      'desc': 'Selesaikan satu episode penuh di halaman Play.',
      'exp': 500,
    },
    {
      'id': 'q3',
      'title': 'Penghias Federasi',
      'desc': 'Pasang border profil atau background komentar pilihanmu.',
      'exp': 300,
    },
  ];

  final List<Map<String, dynamic>> _borders = const [
    {'name': 'Slime Cyan', 'color': Color(0xFF38BDF8)},
    {'name': 'Rimuru Aura', 'color': Color(0xFF5EEAD4)},
    {'name': 'Veldora Storm', 'color': Color(0xFFFACC15)},
    {'name': 'Milim Starlight', 'color': Color(0xFFF472B6)},
  ];

  final List<Map<String, dynamic>> _commentBackgrounds = const [
    {
      'name': 'Tempest Cyan',
      'start': Color(0xFF0E4A6E),
      'end': Color(0xFF0A2E47),
    },
    {
      'name': 'Slime Mint',
      'start': Color(0xFF0F5C5E),
      'end': Color(0xFF0A3642),
    },
    {
      'name': 'Starlight Rose',
      'start': Color(0xFF6B2D5C),
      'end': Color(0xFF1E3A5F),
    },
    {
      'name': 'Storm Gold',
      'start': Color(0xFF6B4E16),
      'end': Color(0xFF14354C),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestData();
  }

  Future<void> _loadQuestData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedBorder = prefs.getString('active_border') ?? 'Slime Cyan';
      _selectedCommentBg =
          prefs.getString('active_comment_bg') ?? 'Tempest Cyan';
      _exp = prefs.getInt('user_exp') ?? 0;
      _claimedIds.addAll(prefs.getStringList('claimed_quests') ?? const []);
    });
  }

  Future<void> _claimQuest(String id, int rewardExp) async {
    if (_claimedIds.contains(id)) return;
    final prefs = await SharedPreferences.getInstance();
    final newExp = _exp + rewardExp;
    final newLevel = 1 + (newExp ~/ 2500);
    _claimedIds.add(id);

    await prefs.setInt('user_exp', newExp);
    await prefs.setInt('user_level', newLevel);
    await prefs.setStringList('claimed_quests', _claimedIds.toList());

    if (!mounted) return;
    setState(() => _exp = newExp);
    widget.onStateChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hadiah +$rewardExp EXP berhasil diklaim.')),
    );
  }

  Future<void> _selectBorder(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_border', name);
    if (!mounted) return;
    setState(() => _selectedBorder = name);
    widget.onStateChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Border "$name" diaktifkan.')),
    );
  }

  Future<void> _selectCommentBg(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_comment_bg', name);
    if (!mounted) return;
    setState(() => _selectedCommentBg = name);
    widget.onStateChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Background komentar "$name" diaktifkan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = const ['Quest', 'Border', 'Background'];

    return Scaffold(
      backgroundColor: const Color(0xFF091B29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2436),
        foregroundColor: const Color(0xFFE6F7FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onExitFullScreen,
        ),
        title: const Text(
          'Pusat Quest & Kustomisasi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final selected = _activeTab == index;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < tabs.length - 1 ? 8 : 0,
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF18B6E8)
                              : const Color(0xFF0D283D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF1F4E6B),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? const Color(0xFF061624)
                                : const Color(0xFFB6DEEF),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: _activeTab == 0
                ? _buildQuestTab()
                : _activeTab == 1
                    ? _buildBorderTab()
                    : _buildBackgroundTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: _quests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final q = _quests[index];
        final id = q['id'] as String;
        final expReward = q['exp'] as int;
        final claimed = _claimedIds.contains(id);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D283D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E4661)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['title'] as String,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE6F7FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q['desc'] as String,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF9BC4D8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+$expReward EXP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5EEAD4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: claimed ? null : () => _claimQuest(id, expReward),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18B6E8),
                  foregroundColor: const Color(0xFF061624),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  claimed ? 'Diklaim' : 'Klaim',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBorderTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: _borders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = _borders[index];
        final name = b['name'] as String;
        final color = b['color'] as Color;
        final active = _selectedBorder == name;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D283D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? color : const Color(0xFF1E4661),
              width: active ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  color: const Color(0xFF081C2B),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/login_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE6F7FF),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _selectBorder(name),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      active ? const Color(0xFF1E4661) : const Color(0xFF18B6E8),
                  foregroundColor:
                      active ? const Color(0xFFE6F7FF) : const Color(0xFF061624),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  active ? 'Aktif' : 'Pakai',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: _commentBackgrounds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bg = _commentBackgrounds[index];
        final name = bg['name'] as String;
        final start = bg['start'] as Color;
        final end = bg['end'] as Color;
        final active = _selectedCommentBg == name;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [start, end],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? const Color(0xFF5EEAD4)
                  : const Color(0xFF38BDF8).withValues(alpha: 0.35),
              width: active ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE6F7FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pratinjau latar belakang gelembung komentar Tempest.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD8F3FF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _selectCommentBg(name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF081C2B),
                  foregroundColor: const Color(0xFFE6F7FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  active ? 'Aktif' : 'Pakai',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
