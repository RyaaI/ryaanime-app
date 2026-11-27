import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/stream_service.dart';
import '../services/tempest_store.dart';

class PlayerPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int initialEpisode;
  final VoidCallback? onProfileUpdated;

  const PlayerPage({
    super.key,
    required this.item,
    this.initialEpisode = 1,
    this.onProfileUpdated,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  late int _currentEp;
  String _quality = '480p';
  int _serverIdx = 0;

  bool _loading = true;
  bool _useWebView = false;
  bool _locked = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  String? _seekOverlayText;

  String _statusMsg = 'Memuat server...';
  String _activeStreamUrl = '';
  dynamic _downloadData;

  VideoPlayerController? _videoCtrl;
  WebViewController? _webCtrl;

  Timer? _watchTimer;
  int _watchedSeconds = 0;
  int _actualWatchedSeconds = 0;
  int? _lastVideoPosSec;
  bool _expClaimedForEp = false;
  bool _autoPlayNext = true;
  int _prefetchedEp = -1;
  static const int _requiredSeconds = 24 * 60;

  final _commentCtrl = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  String _username = 'Warga Tempest';
  String _avatarPath = '';
  String _borderId = 'b_slime';
  String _bgId = 'bg_slate';
  bool _isOwner = false;
  int _exp = 0;

  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentEp = widget.initialEpisode;
    _loadProfileAndComments();
    _initStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _watchTimer?.cancel();
    _videoCtrl?.dispose();
    _commentCtrl.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  String get _commentStorageKey {
    final id = widget.item['id'] ?? widget.item['title'] ?? 'anime';
    return 'tempest_comments_${id}_ep_$_currentEp';
  }

  String get _epClaimedKey {
    final id = widget.item['id'] ?? widget.item['title'] ?? 'anime';
    return 'exp_claimed_${id}_ep_$_currentEp';
  }

  Future<void> _loadProfileAndComments() async {
    final prefs = await SharedPreferences.getInstance();
    final rawComments = prefs.getString(_commentStorageKey);
    List<Map<String, dynamic>> parsed = [];
    if (rawComments != null && rawComments.isNotEmpty) {
      try {
        final list = jsonDecode(rawComments);
        if (list is List) {
          parsed = list
              .whereType()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _username = prefs.getString('username') ?? 'Warga Tempest';
      _avatarPath = prefs.getString('avatar_path') ?? '';
      _borderId = prefs.getString('active_border') ?? 'b_slime';
      _bgId = prefs.getString('active_bg') ?? 'bg_slate';
      _isOwner = prefs.getBool('is_owner') ?? false;
      _exp = prefs.getInt('exp') ?? 0;
      _expClaimedForEp = prefs.getBool(_epClaimedKey) ?? false;
      _comments = parsed;
    });
  }

  void _startWatchTracker() {
    _watchTimer?.cancel();
    _watchedSeconds = 0;
    _actualWatchedSeconds = 0;
    _lastVideoPosSec = null;
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _expClaimedForEp) return;
      final isPlayingNative = _videoCtrl != null &&
          _videoCtrl!.value.isInitialized &&
          _videoCtrl!.value.isPlaying;
      final isPlayingWeb = _useWebView && !_loading;

      if (isPlayingNative || isPlayingWeb) {
        _watchedSeconds++;
        bool reachedEndNative = false;
        int minRequiredSec = _requiredSeconds;

        if (isPlayingNative) {
          final dur = _videoCtrl!.value.duration.inSeconds;
          final pos = _videoCtrl!.value.position.inSeconds;
          if (dur > 5 && pos >= dur - 1 && _autoPlayNext) {
            final maxEp = _getTotalEpisodesSafe();
            if (_currentEp < maxEp) {
              _switchToEpisode(_currentEp + 1);
            }
          }

          if (_lastVideoPosSec != null) {
            final diff = pos - _lastVideoPosSec!;
            if (diff >= 0 && diff <= 3) {
              _actualWatchedSeconds += (diff == 0 ? 1 : diff);
            }
          } else {
            _actualWatchedSeconds++;
          }
          _lastVideoPosSec = pos;

          if (dur > 60) {
            final req85 = (dur * 0.85).round();
            if (req85 < minRequiredSec) {
              minRequiredSec = req85;
            }
            if (pos >= (dur * 0.92).round()) {
              reachedEndNative = true;
            }
          }
        } else {
          _actualWatchedSeconds++;
        }

        final validCompletion = reachedEndNative && (_actualWatchedSeconds >= minRequiredSec);
        final validMarathon = _actualWatchedSeconds >= _requiredSeconds;
        if (validCompletion || validMarathon) {
          _grantEpisodeExp();
        }
      } else {
        _lastVideoPosSec = null;
      }
    });
  }

  int _getTotalEpisodesSafe() {
    final raw = widget.item['episodes'];
    if (raw is int && raw > 0) return raw;
    return int.tryParse('$raw') ?? 12;
  }

    void _prefetchNextEpisode() {
    final nextEp = _currentEp + 1;
    final totalEp = _getTotalEpisodesSafe();
    if (nextEp <= 1 || nextEp > totalEp || _prefetchedEp == nextEp) return;
    _prefetchedEp = nextEp;
    final titles = <String>[
      if (widget.title.trim().isNotEmpty) widget.title.trim(),
      if ((_animeTitle ?? '').trim().isNotEmpty) _animeTitle!.trim(),
    ];
    if (titles.isEmpty) return;
    StreamService.resolveEpisode(
      titleCandidates: titles,
      episode: nextEp,
      quality: _quality,
      serverIndex: _serverIndex,
      preferredProvider: _preferredProvider,
    ).catchError((_) => null);
  }

  Future<void> _switchToEpisode(int ep) async {
    final maxEp = _getTotalEpisodesSafe();
    if (ep < 1 || ep > maxEp || ep == _currentEp) return;
    if (!mounted) return;
    setState(() {
      _currentEp = ep;
    _prefetchNextEpisode();
      _watchedSeconds = 0;
      _actualWatchedSeconds = 0;
      _lastVideoPosSec = null;
      _expClaimedForEp = false;
    });
    await _loadProfileAndComments();
    _initStream();
  }

  Future<void> _grantEpisodeExp() async {
    if (_expClaimedForEp) return;
    _expClaimedForEp = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_epClaimedKey, true);
    final newExp = (prefs.getInt('exp') ?? 0) + 50;
    final watchedCount = (prefs.getInt('watched_episodes_count') ?? 0) + 1;
    await prefs.setInt('exp', newExp);
    await prefs.setInt('watched_episodes_count', watchedCount);
    await SessionManager.persistActiveProfile();
    widget.onProfileUpdated?.call();

    if (!mounted) return;
    setState(() => _exp = newExp);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Episode selesai / 24 menit tercapai! +50 EXP Tempest'),
        backgroundColor: Color(0xFF0284C7),
      ),
    );
  }

  List<String> _titleCandidates() {
    final t = (widget.item['title'] ?? '').toString().trim();
    final r = (widget.item['romaji'] ?? '').toString().trim();
    final e = (widget.item['english'] ?? '').toString().trim();
    final clean = t
        .replaceAll(
            RegExp(
                r'(\d+(st|nd|rd|th)\s*Season|Season\s*\d+|Part\s*\d+|[:!\-?])',
                caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final short = clean.split(' ').take(3).join(' ');
    return <String>{t, r, e, clean, short}.where((s) => s.length >= 3).toList();
  }

  Future<void> _initStream() async {
    final token = ++_loadToken;
    _watchTimer?.cancel();
    await _videoCtrl?.dispose();
    _videoCtrl = null;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _useWebView = false;
      _statusMsg = 'Memuat $_quality • Server ${_serverIdx + 1}...';
    });

    final result = await StreamService.resolveEpisode(
      titleCandidates: _titleCandidates(),
      episode: _currentEp,
      quality: _quality,
      serverIndex: _serverIdx,
    );

    if (!mounted || token != _loadToken) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _statusMsg =
            'Server belum tersedia untuk episode ini. Coba ganti server/resolusi.';
      });
      return;
    }

    final url = (result['url'] ?? '').toString();
    final label = (result['label'] ?? 'Server').toString();
    _activeStreamUrl = url;
    _downloadData = result['downloadUrl'];

    final isDirectVideo = url.contains('.mp4') ||
        url.contains('.m3u8') ||
        url.contains('googlevideo.com');

    if (isDirectVideo) {
      try {
        final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
        await ctrl.initialize();
        if (!mounted || token != _loadToken) {
          await ctrl.dispose();
          return;
        }
        await ctrl.play();
        setState(() {
          _videoCtrl = ctrl;
          _useWebView = false;
          _loading = false;
          _statusMsg = label;
        });
        _startWatchTracker();
        return;
      } catch (_) {}
    }

    final urlLower = url.toLowerCase();
    if (urlLower.contains('invalidargument') || urlLower.contains('<error>')) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loading = false;
        _useWebView = false;
        _statusMsg = 'Sumber stream sedang bermasalah (XML error). Coba server lain.';
      });
      return;
    }
    final initialHost = Uri.tryParse(url)?.host ?? '';
    final wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final targetUri = Uri.tryParse(req.url);
            if (targetUri == null) return NavigationDecision.prevent;

            final rawLower = req.url.toLowerCase();
            final hostLower = targetUri.host.toLowerCase();
            final schemeLower = targetUri.scheme.toLowerCase();
            final allowedHost = (initialHost.isNotEmpty &&
                    hostLower.contains(initialHost.toLowerCase())) ||
                hostLower.contains('blogger') ||
                hostLower.contains('desustream') ||
                hostLower.contains('vidhide') ||
                hostLower.contains('filedon') ||
                hostLower.contains('mp4upload') ||
                hostLower.contains('yourupload');

            const blockedTerms = [
              'doubleclick',
              'googlesyndication',
              'adserver',
              'popads',
              'popcash',
              'propeller',
              'exoclick',
              'juicyads',
              'trafficjunky',
              'revcontent',
              'mgid',
              'outbrain',
              'taboola',
              'terabox',
              't.me/',
              'whatsapp.com',
              'play.google.com',
              '/dl/',
              'dl=',
              'force_download',
              'download='
            ];

            final isBlockedScheme =
                schemeLower != 'http' && schemeLower != 'https';
            final isBlockedUrl =
                blockedTerms.any((t) => rawLower.contains(t));

            if (isBlockedScheme ||
                isBlockedUrl ||
                (req.isMainFrame && !allowedHost)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) async {
            if (!mounted || token != _loadToken) return;
            try {
              if (_webCtrl != null) {
                await _webCtrl!.runJavaScript('''
                  (function() {
                    try {
                      window.open = function() { return null; };
                      function cleanEmbed() {
                        document.querySelectorAll('a[target="_blank"]').forEach(function(a) {
                          a.setAttribute('target', '_self');
                        });
                        var st = document.getElementById('rya-clean-style');
                        if (!st) {
                          st = document.createElement('style');
                          st.id = 'rya-clean-style';
                          st.textContent = '[id*="ad" i], [class*="popup" i], [class*="popunder" i] { display: none !important; visibility: hidden !important; }';
                          (document.head || document.documentElement).appendChild(st);
                        }

                      }
                      cleanEmbed();
                      var v0 = document.querySelector('video');
                      if (v0 && v0.paused) { v0.play().catch(function() {}); }
                      if (!window._ryaObs) {
                        window._ryaObs = new MutationObserver(cleanEmbed);
                        window._ryaObs.observe(document.documentElement, { childList: true, subtree: true });
                      }
                    } catch (e) {}
                  })();
                ''');
              }
            } catch (_) {}
            if (!mounted || token != _loadToken) return;
            setState(() {
              _loading = false;
              _statusMsg = label;
            });
            _startWatchTracker();
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    if (!mounted || token != _loadToken) return;
    setState(() {
      _webCtrl = wv;
      _useWebView = true;
      _loading = false;
      _statusMsg = label;
    });
    _startWatchTracker();
  }

  void _restartHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _videoCtrl != null && _videoCtrl!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControlsVisibility() {
    if (_locked) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _restartHideControlsTimer();
  }

  Future<void> _seekRelative(int seconds) async {
    final ctrl = _videoCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    var target = pos + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;
    await ctrl.seekTo(target);
    if (!mounted) return;
    setState(() {
      _seekOverlayText = seconds > 0 ? '+${seconds}d' : '${seconds}d';
    });
    _restartHideControlsTimer();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _seekOverlayText != null) {
        setState(() => _seekOverlayText = null);
      }
    });
  }

  void _togglePlayPause() {
    final ctrl = _videoCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    setState(() {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
        _showControls = true;
        _hideControlsTimer?.cancel();
      } else {
        ctrl.play();
        _restartHideControlsTimer();
      }
    });
  }

  String _fmtDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$mins:$secs';
    return '$mins:$secs';
  }



  Future<void> _toggleFullscreen() async {
    final wasPlaying = _videoCtrl != null &&
        _videoCtrl!.value.isInitialized &&
        _videoCtrl!.value.isPlaying;
    if (wasPlaying) {
      await _videoCtrl!.pause();
    }
    if (!mounted) return;
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
    if (wasPlaying && _videoCtrl != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) await _videoCtrl!.play();
    }
  }

  void _showDownloadSheet() {
    final List<Map<String, dynamic>> links = [];
    if (_downloadData is Map) {
      final qList = _downloadData['qualityList'];
      if (qList is List) {
        for (final q in qList) {
          if (q is Map) {
            final qTitle = (q['title'] ?? '').toString();
            final uList = q['urlList'];
            if (uList is List) {
              for (final u in uList) {
                if (u is Map) {
                  final host = (u['title'] ?? 'Download').toString();
                  final href = (u['url'] ?? '').toString();
                  if (href.startsWith('http')) {
                    links.add({'label': '$qTitle • $host', 'url': href});
                  }
                }
              }
            }
          }
        }
      }
    }

    if (links.isEmpty && _activeStreamUrl.startsWith('http')) {
      links.add(
          {'label': 'Buka Tautan Stream ($_quality)', 'url': _activeStreamUrl});
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unduh Episode $_currentEp',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (links.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Tautan unduhan belum tersedia untuk episode ini.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: links.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = links[i];
                    return ListTile(
                      tileColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: const Icon(Icons.download_rounded,
                          color: Color(0xFF38BDF8)),
                      title: Text(
                        item['label']!,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy,
                            color: Colors.white54, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item['url']!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tautan disalin!')),
                          );
                        },
                      ),
                      onTap: () => launchUrl(
                        Uri.parse(item['url']!),
                        mode: LaunchMode.externalApplication,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();

    final prefs = await SharedPreferences.getInstance();
    final rankInfo = RankHelper.getRank(_exp, _isOwner);
    final entry = {
      'user': _username,
      'avatar': _avatarPath,
      'border': _borderId,
      'bg': _bgId,
      'isOwner': _isOwner,
      'rankTitle': rankInfo['title'],
      'text': text,
      'time': 'Baru saja',
    };

    final updated = [entry, ..._comments];
    await prefs.setString(_commentStorageKey, jsonEncode(updated));
    final cCount = (prefs.getInt('comment_count') ?? 0) + 1;
    await prefs.setInt('comment_count', cCount);

    if (!mounted) return;
    setState(() => _comments = updated);
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.item['title'] ?? 'Anime').toString();
    final totalEps = (widget.item['episodes'] is int)
        ? widget.item['episodes'] as int
        : int.tryParse('${widget.item['episodes']}') ?? 12;

    final isNativeReady = _videoCtrl != null && _videoCtrl!.value.isInitialized;
    final ready = _videoCtrl != null && _videoCtrl!.value.isInitialized;
    final playerBox = Container(
      color: Colors.black,
      width: double.infinity,
      height: _isFullscreen ? MediaQuery.of(context).size.height : 225,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _locked,
              child: Center(
                child: ready
                    ? AspectRatio(aspectRatio: _videoCtrl!.value.aspectRatio, child: VideoPlayer(_videoCtrl!))
                    : ((_useWebView && _webCtrl != null)
                        ? WebViewWidget(controller: _webCtrl!)
                        : Padding(padding: const EdgeInsets.all(16), child: Text(_statusMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)))),
              ),
            ),
          ),
          if (ready && !_locked)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _toggleControlsVisibility, onDoubleTap: () => _seekRelative(-10))),
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _toggleControlsVisibility, onDoubleTap: () => _seekRelative(10))),
                ],
              ),
            ),
          if (_seekOverlayText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.72), borderRadius: BorderRadius.circular(24)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_seekOverlayText!.startsWith('+') ? Icons.forward_10_rounded : Icons.replay_10_rounded, color: const Color(0xFF38BDF8), size: 24),
                  const SizedBox(width: 6),
                  Text(_seekOverlayText!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          if (_loading) const CircularProgressIndicator(color: Color(0xFF38BDF8)),
          if (!_locked && (_showControls || !ready))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 6, 6, 12),
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.78), Colors.transparent])),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () { if (_isFullscreen) { _toggleFullscreen(); } else { Navigator.pop(context); } }),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.skip_previous, color: Colors.white),
                          onPressed: _currentEp > 1 ? () => _switchToEpisode(_currentEp - 1) : null,
                        ),
                        Flexible(child: Text('$title • Ep $_currentEp', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5))),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: _currentEp < _getTotalEpisodesSafe() ? () => _switchToEpisode(_currentEp + 1) : null,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            _autoPlayNext ? Icons.autoplay : Icons.play_disabled,
                            color: _autoPlayNext ? const Color(0xFFFF85C0) : Colors.white54,
                          ),
                          onPressed: () => setState(() => _autoPlayNext = !_autoPlayNext),
                        ),
                      ],
                    ),
                          Text(_statusMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(tooltip: 'Kunci Layar', icon: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20), onPressed: () { _hideControlsTimer?.cancel(); setState(() => _locked = true); }),
                    IconButton(tooltip: 'Layar Penuh', icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white, size: 22), onPressed: _toggleFullscreen),
                  ],
                ),
              ),
            ),
          if (!_locked && _showControls && ready)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(color: Colors.black45, shape: const CircleBorder(), child: IconButton(iconSize: 30, color: Colors.white, icon: const Icon(Icons.replay_10_rounded), onPressed: () => _seekRelative(-10))),
                const SizedBox(width: 24),
                Material(color: const Color(0xFF38BDF8).withOpacity(0.9), shape: const CircleBorder(), child: IconButton(iconSize: 38, color: const Color(0xFF0A0E1A), icon: Icon(_videoCtrl!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded), onPressed: _togglePlayPause)),
                const SizedBox(width: 24),
                Material(color: Colors.black45, shape: const CircleBorder(), child: IconButton(iconSize: 30, color: Colors.white, icon: const Icon(Icons.forward_10_rounded), onPressed: () => _seekRelative(10))),
              ],
            ),
          if (!_locked && _showControls && ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.82), Colors.transparent])),
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _videoCtrl!,
                  builder: (context, val, _) {
                    final pos = val.position;
                    final dur = val.duration;
                    final maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
                    final curMs = pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 12), activeTrackColor: const Color(0xFF38BDF8), inactiveTrackColor: Colors.white24, thumbColor: const Color(0xFF38BDF8)),
                          child: Slider(value: curMs, min: 0, max: maxMs, onChangeStart: (_) => _hideControlsTimer?.cancel(), onChanged: (v) => _videoCtrl!.seekTo(Duration(milliseconds: v.toInt())), onChangeEnd: (_) => _restartHideControlsTimer()),
                        ),
                        Row(
                          children: [
                            Text('${_fmtDuration(pos)} / ${_fmtDuration(dur)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: Text(_quality, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          if (_locked)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () { setState(() { _locked = false; _showControls = true; }); _restartHideControlsTimer(); },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: Color(0xFFFBBF24), size: 18),
                        SizedBox(width: 6),
                        Text('Terkunci', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: playerBox),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            playerBox,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$title - Episode $_currentEp',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _expClaimedForEp
                              ? const Color(0xFF065F46)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _expClaimedForEp
                              ? 'EXP Diklaim (+50)'
                              : 'EXP: Selesai / 24m',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusMsg,
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final q in ['360p', '480p', '720p', '1080p'])
                        ChoiceChip(
                          label: Text(q),
                          selected: _quality == q,
                          onSelected: (_) {
                            setState(() => _quality = q);
                            _initStream();
                          },
                        ),
                      for (int s = 0; s < 3; s++)
                        ChoiceChip(
                          label: Text('Server ${s + 1}'),
                          selected: _serverIdx == s,
                          onSelected: (_) {
                            setState(() => _serverIdx = s);
                            _initStream();
                          },
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.download,
                            size: 16, color: Color(0xFF38BDF8)),
                        label: const Text('Download'),
                        onPressed: _showDownloadSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pilih Episode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: totalEps > 0 ? totalEps : 12,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, idx) {
                        final epNum = idx + 1;
                        final active = epNum == _currentEp;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _currentEp = epNum);
                            _loadProfileAndComments();
                            _initStream();
                          },
                          child: Container(
                            width: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF1E3A5F),
                              ),
                            ),
                            child: Text(
                              '$epNum',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? const Color(0xFF0A0E1A)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 28, color: Color(0xFF1E293B)),
                  const Text(
                    'Komentar Tempest',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TempestStore.buildAvatar(
                        _avatarPath,
                        _borderId,
                        radius: 18,
                        isOwner: _isOwner,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Tulis komentar warga Tempest...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: const Color(0xFF111827),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendComment,
                        icon: const Icon(Icons.send_rounded,
                            color: Color(0xFF38BDF8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final c in _comments) _buildCommentCard(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> c) {
    final bgKey = (c['bg'] ?? 'bg_slate').toString();
    final bg = TempestStore.backgrounds[bgKey] ??
        TempestStore.backgrounds['bg_slate']!;
    final c1 = Color(bg['c1'] as int);
    final c2 = Color(bg['c2'] as int);
    final borderCol = Color(bg['border'] as int);
    final tag = (bg['tag'] ?? '').toString();

    if (bg['anim'] == true) {
      return AnimatedOwnerCommentCard(
        c1: c1,
        c2: c2,
        borderCol: borderCol,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tag.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: borderCol.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderCol, width: 1),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: borderCol,
                  ),
                ),
              ),
            Text(
              (c['rankTitle'] ?? 'Unique Slime').toString(),
              style: const TextStyle(fontSize: 10, color: Colors.white60),
            ),
            const SizedBox(height: 6),
            Text(
              (c['text'] ?? '').toString(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      )))))))
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TempestStore.buildAvatar(
            (c['avatar'] ?? '').toString(),
            (c['border'] ?? 'b_slime').toString(),
            radius: 18,
            isOwner: c['isOwner'] == true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      (c['user'] ?? 'Warga Tempest').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    if (tag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: borderCol.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderCol),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: borderCol,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  (c['rankTitle'] ?? 'Unique Slime').toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ,
                const SizedBox(height: 6),
                Text(
                  (c['text'] ?? '').toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ,
              ],
            ,
          ,
        ],
      ,
    ;
  }
}
