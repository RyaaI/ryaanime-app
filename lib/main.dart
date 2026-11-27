import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/play_screen.dart';
import 'screens/quest_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RyaaNimeApp());
}

class RyaaNimeApp extends StatefulWidget {
  const RyaaNimeApp({super.key});

  @override
  State<RyaaNimeApp> createState() => _RyaaNimeAppState();
}

class _RyaaNimeAppState extends State<RyaaNimeApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('username');
    if (!mounted) return;
    setState(() {
      _isLoggedIn = savedUser != null && savedUser.trim().isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryCyan = Color(0xFF18B6E8);
    const softSlimeSurface = Color(0xFF0E293B);
    const softSlimeBackground = Color(0xFF091B29);

    return MaterialApp(
      title: 'RyaaNime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: softSlimeBackground,
        colorScheme: const ColorScheme.dark(
          primary: primaryCyan,
          secondary: Color(0xFF5EEAD4),
          surface: softSlimeSurface,
          onSurface: Color(0xFFE6F7FF),
        ),
      ),
      routes: {
        '/': (context) => _isLoading
            ? const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: primaryCyan),
                ),
              )
            : _isLoggedIn
                ? const TempestMainShell()
                : const LoginScreen(),
        '/main': (context) => const TempestMainShell(),
      },
      initialRoute: '/',
    );
  }
}

class TempestMainShell extends StatefulWidget {
  const TempestMainShell({super.key});

  @override
  State<TempestMainShell> createState() => _TempestMainShellState();
}

class _TempestMainShellState extends State<TempestMainShell> {
  int _currentIndex = 0;
  int _refreshTick = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(label: 'Home', assetPath: 'assets/icons/home.png'),
    _NavItem(label: 'Favorites', assetPath: 'assets/icons/favorites.png'),
    _NavItem(label: 'Quest', assetPath: 'assets/icons/quest.png'),
    _NavItem(label: 'History', assetPath: 'assets/icons/history.png'),
    _NavItem(label: 'Jadwal', assetPath: 'assets/icons/schedule.png'),
  ];

  void _triggerRefresh() {
    setState(() => _refreshTick++);
  }

  void _openMenu() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuScreen(onProfileUpdated: _triggerRefresh),
      ),
    );
  }

  void _openPlay(Map<String, String> anime) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayScreen(
          animeTitle: anime['title'] ?? 'Anime Tempest',
          initialEpisode: anime['episode'] ?? 'Episode 1',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 2) {
      return QuestScreen(
        onExitFullScreen: () => setState(() => _currentIndex = 0),
        onStateChanged: _triggerRefresh,
      );
    }

    Widget currentBody;
    switch (_currentIndex) {
      case 0:
        currentBody = HomeScreen(
          key: ValueKey('home_$_refreshTick'),
          onOpenMenu: _openMenu,
          onOpenAnime: _openPlay,
        );
        break;
      case 1:
        currentBody = _buildSecondaryTabPage(
          title: 'Favorites',
          subtitle: 'Daftar anime favorit warga Tempest.',
          icon: Icons.favorite_border_rounded,
        );
        break;
      case 3:
        currentBody = _buildSecondaryTabPage(
          title: 'History',
          subtitle: 'Riwayat episode yang telah ditonton.',
          icon: Icons.history_rounded,
        );
        break;
      default:
        currentBody = _buildScheduleTabPage();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF091B29),
      body: SafeArea(child: currentBody),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C2436),
          border: Border(
            top: BorderSide(color: Color(0xFF1F4E6B), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final selected = _currentIndex == index;
            return InkWell(
              onTap: () => setState(() => _currentIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      item.assetPath,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                        color: selected
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF9BC4D8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSecondaryTabPage({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE6F7FF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8FD3F4)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D283D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E4661)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 42, color: const Color(0xFF38BDF8)),
                    const SizedBox(height: 10),
                    Text(
                      'Belum ada data $title tersimpan.',
                      style: const TextStyle(
                        color: Color(0xFFB6DEEF),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTabPage() {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final day = days[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D283D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E4661)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE6F7FF),
                ),
              ),
              const Text(
                'Jadwal Rilis Tempest',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF8FD3F4)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final String assetPath;
  const _NavItem({required this.label, required this.assetPath});
}
