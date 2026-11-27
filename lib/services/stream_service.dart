import 'dart:convert';
import 'package:http/http.dart' as http;

class StreamService {
  static const String baseUrl = 'http://191.222.39.242:3001';
  static const String resolverBaseUrl = 'http://191.222.39.226:30001';
  static final http.Client _httpClient = http.Client();
  static final Map _jsonCache = {};
  static final Map _jsonCacheTime = {};
  static final Map<String, Map<String, dynamic>> _mp4Cache = {};

  static Future _getJson(Uri uri, {int timeoutSec = 4}) async {
    final key = uri.toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cached = _jsonCache[key];
    final ts = _jsonCacheTime[key];
    if (cached is Map && ts is int && (now - ts) < 600000) {
      return Map.from(cached).cast();
    }
    try {
      final res = await _httpClient.get(uri).timeout(Duration(seconds: timeoutSec));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          final typed = Map.from(decoded).cast();
          _jsonCache[key] = typed;
          _jsonCacheTime[key] = now;
          return typed;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _resolveDirectMp4(String rawUrl) async {
    final cached = _mp4Cache[rawUrl];
    if (cached != null) {
      final ts = (cached['ts'] as int?) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - ts < 300000) {
        return cached['url'] as String?;
      }
    }

    if (rawUrl.isEmpty) return null;
    if (RegExp(r'\.mp4(\?|$)', caseSensitive: false).hasMatch(rawUrl)) {
      return rawUrl;
    }
    final res = await _getJson(
      Uri.parse('$resolverBaseUrl/resolve?url=${Uri.encodeComponent(rawUrl)}'),
      timeoutSec: 4,
    );
    final direct = (res?['directUrl'] ?? '').toString().trim();
    if (direct.startsWith('http')) return direct;
        if (direct.startsWith('http')) {
      _mp4Cache[rawUrl] = {'url': direct, 'ts': DateTime.now().millisecondsSinceEpoch};
      return direct;
    }
    _mp4Cache[rawUrl] = {'url': null, 'ts': DateTime.now().millisecondsSinceEpoch};
    return null;
  }

static List<String> _expandQueries(List<String> rawCandidates) {
    final out = List<String>.from([]);
    void addUnique(String s) {
      final clean = s.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (clean.length >= 3 && !out.contains(clean)) out.add(clean);
    }
    for (final raw in rawCandidates) {
      addUnique(raw);
      final cleanedDash = raw.split(' - ').first.trim();
      addUnique(cleanedDash);
      final noSeason = cleanedDash
          .replaceAll(RegExp(r'\b(Season|Part|Cour)\s*\d+.*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[:\-]\s*$'), '')
          .trim();
      addUnique(noSeason);
      final words = noSeason.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length >= 4) addUnique(words.take(4).join(' '));
      if (words.length >= 3) addUnique(words.take(3).join(' '));
    }
    return out;
  }

  static String? _pickOploverzFiledonUrl(dynamic downloadSource, String quality) {
    final qClean = quality.toLowerCase().replaceAll('p', '').trim();
    String? pickFromUrlList(dynamic rawList) {
      if (rawList is! List) return null;
      for (final u in rawList) {
        if (u is! Map) continue;
        final href = (u['url'] ?? '').toString().trim();
        final title = (u['title'] ?? '').toString().toLowerCase();
        if (href.startsWith('http') &&
            (href.toLowerCase().contains('filedon.co') || title.contains('filedon'))) {
          return href;
        }
      }
      return null;
    }

    if (downloadSource is List) {
      final sortedFormats = List<dynamic>.from(downloadSource)
        ..sort((a, b) {
          final ta = (a is Map ? (a['title'] ?? '') : '').toString().toLowerCase();
          final tb = (b is Map ? (b['title'] ?? '') : '').toString().toLowerCase();
          final sa = ta == 'mp4' ? 0 : (ta == 'mkv' ? 1 : 2);
          final sb = tb == 'mp4' ? 0 : (tb == 'mkv' ? 1 : 2);
          return sa.compareTo(sb);
        });

      for (final fmt in sortedFormats) {
        if (fmt is! Map) continue;
        final qList = fmt['qualityList'];
        if (qList is! List || qList.isEmpty) continue;
        Map? matched;
        for (final q in qList) {
          if (q is! Map) continue;
          final qt = (q['title'] ?? '').toString().toLowerCase();
          if (qClean.isNotEmpty && qt.contains(qClean)) {
            matched = q;
            break;
          }
        }
        matched ??= qList.last is Map ? qList.last as Map : null;
        final found = pickFromUrlList(matched?['urlList']);
        if (found != null) return found;
      }
    }

    if (downloadSource is Map) {
      final qualities = downloadSource['qualities'];
      if (qualities is List && qualities.isNotEmpty) {
        Map? chosenQual;
        for (final q in qualities) {
          if (q is! Map) continue;
          final title = (q['title'] ?? '').toString().toLowerCase();
          if (qClean.isNotEmpty && title.contains(qClean)) {
            chosenQual = q;
            break;
          }
        }
        chosenQual ??= qualities.last is Map ? qualities.last as Map : null;
        return pickFromUrlList(chosenQual?['urls']);
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> _fetchFromProvider({
    required String provider,
    required List<String> queries,
    required int episode,
    required String quality,
  }) async {
    for (final q in queries.take(2)) {
      final searchJson = await _getJson(
        Uri.parse('$baseUrl/$provider/search?q=${Uri.encodeComponent(q)}'),
      );
      final animeList = searchJson?['data']?['animeList'];
      if (animeList is! List || animeList.isEmpty) continue;

      final qLower = q.toLowerCase();
      final seasonMatch = RegExp(r'\b(?:season|s)\s*(\d+)\b', caseSensitive: false).firstMatch(qLower);
      final reqSeason = seasonMatch?.group(1);
      final keyTokens = qLower
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 3 && !const {'season', 'part', 'cour', 'the', 'and', 'subtitle', 'indonesia'}.contains(w))
          .toList();

      final List rankedCandidates = [];
      for (final candidate in animeList) {
        if (candidate is! Map) continue;
        final animeId = (candidate['animeId'] ?? '').toString().trim();
        if (animeId.isEmpty || animeId.toLowerCase() == 'none') continue;
        final candTitle = (candidate['title'] ?? '').toString().trim();
        final hay = '$candTitle $animeId'
            .toLowerCase()
            .replaceAll(RegExp(r'\b1(?=[a-z])'), 'one ')
            .replaceAll('1', ' one ');
        final hayWords = hay
            .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toSet();
        int score = 0;
        if (keyTokens.isNotEmpty) {
          score = keyTokens.where((t) => hayWords.contains(t)).length;
          if (score == 0) continue;
        }
        if (reqSeason != null && reqSeason.isNotEmpty) {
          final hasSeason = RegExp(r'(?:season[-_\s]*' + reqSeason + r'\b|\bs' + reqSeason + r'(?:\b|-|_))', caseSensitive: false).hasMatch(hay);
          if (hasSeason) score += 2;
        }
        rankedCandidates.add({
          'animeId': animeId,
          'hay': hay,
          'score': score,
        });
      }
      rankedCandidates.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      final requiredHits = keyTokens.length;

      for (final cand in rankedCandidates.take(2)) {
        final animeId = cand['animeId'] as String;
        final hay = cand['hay'] as String;

        final animeJson = await _getJson(
          Uri.parse('$baseUrl/$provider/anime/${Uri.encodeComponent(animeId)}'),
        );
        final animeDetails = animeJson?['data']?['details'];
        final detailTitle = (animeDetails is Map ? (animeDetails['title'] ?? '') : '').toString().trim();
        final fullHay = '$hay $detailTitle'
            .toLowerCase()
            .replaceAll(RegExp(r'\b1(?=[a-z])'), 'one ')
            .replaceAll('1', ' one ');
        final fullWords = fullHay
            .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toSet();
        if (requiredHits > 0) {
          final matchedDetailTokens = keyTokens.where((t) => fullWords.contains(t)).length;
          if (matchedDetailTokens < requiredHits) continue;
        }
        final epList = animeDetails is Map ? animeDetails['episodeList'] : null;
        if (epList is! List || epList.isEmpty) continue;

        String episodeId = '';
        for (final ep in epList) {
          if (ep is! Map) continue;
          final epTitle = (ep['title'] ?? '').toString().trim();
          final eid = (ep['episodeId'] ?? '').toString().trim();
          if (eid.isNotEmpty &&
              (epTitle == '$episode' ||
                  RegExp(r'(?:^|\D)' '$episode' r'(?=$|\D)').hasMatch(epTitle))) {
            episodeId = eid;
            break;
          }
        }
        if (episodeId.isEmpty) continue;

        final epJson = await _getJson(
          Uri.parse('$baseUrl/$provider/episode/${Uri.encodeComponent(episodeId)}'),
        );
        final details = epJson?['data']?['details'];
        if (details is! Map) return null;

        final downloadUrl = details['downloadUrl'];
        final qList = details['server']?['qualityList'];

        if (provider == 'oploverz') {
          final pickedFiledon = _pickOploverzFiledonUrl(details['download'] ?? downloadUrl, quality);
          if (pickedFiledon != null) {
            final directMp4 = await _resolveDirectMp4(pickedFiledon);
            if (directMp4 != null && directMp4.isNotEmpty) {
              return {
                'url': directMp4,
                'label': '$quality',
                'provider': provider,
                'downloadUrl': downloadUrl,
              };
            }
          }
        } else if (qList is List && qList.isNotEmpty) {
          Map? chosenQual;
          final qClean = quality.replaceAll('p', '');
          for (final item in qList) {
            if (item is Map && (item['title'] ?? '').toString().contains(qClean)) {
              chosenQual = item;
              break;
            }
          }
          if (chosenQual == null) {
            chosenQual = (quality == '1080p' || quality == '720p')
                ? (qList.last is Map ? qList.last as Map : null)
                : (qList.first is Map ? qList.first as Map : null);
          }

          final srvList = chosenQual?['serverList'];
          if (srvList is List && srvList.isNotEmpty) {
            final orderedServers = [
              ...srvList.where((s) => s is Map && (s['title'] ?? '').toString().toLowerCase().contains('odstream')),
              ...srvList.where((s) => s is Map && !(s['title'] ?? '').toString().toLowerCase().contains('odstream')),
            ];
            final tasks = orderedServers.take(3).where((s) => s is Map).map((srv) async {
              final serverId = (srv['serverId'] ?? '').toString().trim();
              if (serverId.isEmpty) return null;
              final srvJson = await _getJson(
                Uri.parse('$baseUrl/$provider/server/${Uri.encodeComponent(serverId)}'),
                timeoutSec: 4,
              );
              final u = (srvJson?['data']?['details']?['url'] ?? '').toString().trim();
              if (!u.startsWith('http')) return null;
              final directMp4 = await _resolveDirectMp4(u);
              if (directMp4 == null || directMp4.isEmpty) return null;
              final actualRes = (chosenQual?['title'] ?? quality).toString().trim();
              return {
                'url': directMp4,
                'label': '$actualRes',
                'provider': provider,
                'downloadUrl': downloadUrl,
              };
            }).toList();
            if (tasks.isNotEmpty) {
              final winners = await Future.wait(tasks);
              for (final w in winners) {
                if (w != null) return w;
            }
            }
          }
        }
      }
    }
    return null;
  }

  static List<String> _tokenizeTitle(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toList();
  }

  static Future<List>> _searchSingleRouter(
    String provider,
    String query,
  ) async {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) return [];

    final uri = Uri.parse(
      '$baseUrl/$provider/search?q=${Uri.encodeComponent(cleanQ)}',
    );
    final json = await _getJson(uri, timeoutSec: 6);
    final data = json?['data'];
    if (data is! Map) return [];

    final rawList = data['animeList'] ?? data['searchList'] ?? data['results'];
    if (rawList is! List) return [];

    final qTokens = _tokenizeTitle(cleanQ);
    final qLower = cleanQ.toLowerCase();
    final List> out = [];

    for (final item in rawList) {
      if (item is! Map) continue;
      final title = (item['title'] ?? item['seriesName'] ?? '').toString().trim();
      final animeId = (item['animeId'] ?? item['id'] ?? item['slug'] ?? '')
          .toString()
          .trim();
      if (title.isEmpty || animeId.isEmpty) continue;

      final titleLower = title.toLowerCase();
      final titleTokens = _tokenizeTitle(title).toSet();

      int score = 0;
      if (titleLower.contains(qLower)) score += 10;
      if (qTokens.isNotEmpty) {
        final hits = qTokens.where((t) => titleTokens.contains(t)).length;
        if (hits == 0 && !titleLower.contains(qLower)) continue;
        score += hits * 3;
      }

      final poster = (item['poster'] ?? item['thumb'] ?? item['img'] ?? '')
          .toString()
          .trim();
      final epText = (item['episodes'] ?? item['episode'] ?? item['status'] ?? '')
          .toString()
          .trim();

      out.add({
        'title': title,
        'animeId': animeId,
        'source': provider,
        'poster': poster,
        'episode': epText.isEmpty ? 'Tersedia' : epText,
        '_score': score,
      });
    }

    out.sort(
      (a, b) => ((b['_score'] as int?) ?? 0).compareTo((a['_score'] as int?) ?? 0),
    );
    return out;
  }

  // Mencari langsung di kedua router: oploverz dan otakudesu
  static Future<List>> searchBothRouters(
    String query,
  ) async {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) return [];

    List> oploverzRes = [];
    List> otakudesuRes = [];

    try {
      oploverzRes = await _searchSingleRouter('oploverz', cleanQ)
          .timeout(const Duration(seconds: 7), onTimeout: () => []);
    } catch (_) {}

    try {
      otakudesuRes = await _searchSingleRouter('otakudesu', cleanQ)
          .timeout(const Duration(seconds: 7), onTimeout: () => []);
    } catch (_) {}

    final merged = >[];
    final seen = <String>{};

    // Selang-seling agar hasil kedua router terwakili seimbang
    final maxLen = oploverzRes.length > otakudesuRes.length
        ? oploverzRes.length
        : otakudesuRes.length;
    for (int i = 0; i < maxLen; i++) {
      for (final bucket in [oploverzRes, otakudesuRes]) {
        if (i < bucket.length) {
          final item = Map<String, dynamic>.from(bucket[i]);
          final key =
              '${item['source']}_${item['animeId']}_${(item['title'] as String).toLowerCase()}';
          if (seen.add(key)) {
            item.remove('_score');
            merged.add(item);
          }
        }
      }
    }
    return merged;
  }

  // 2 server utama: index 0 -> oploverz dulu (fallback otakudesu), index 1 -> otakudesu dulu (fallback oploverz)
  // Semua pilihan kualitas ('360p', '480p', '720p', '1080p') diteruskan langsung ke provider
  static Future?> resolveEpisode({
    required List<String> titleCandidates,
    required int episode,
    String quality = '720p',
    int serverIndex = 0,
    String preferredProvider = 'oploverz',
  }) async {
    final queries = _expandQueries(titleCandidates);
    final allowedQualities = {'360p', '480p', '720p', '1080p'};
    final cleanQuality = allowedQualities.contains(quality) ? quality : '720p';

    final String firstPick;
    if (serverIndex == 0) {
      firstPick = 'oploverz';
    } else if (serverIndex == 1) {
      firstPick = 'otakudesu';
    } else {
      firstPick = preferredProvider == 'otakudesu' ? 'otakudesu' : 'oploverz';
    }
    final String secondPick = firstPick == 'oploverz' ? 'otakudesu' : 'oploverz';

    bool hasValidStream(Map<String, dynamic>? m) {
      if (m == null) return false;
      final u = (m['streamUrl'] ?? m['url'] ?? m['directUrl'] ?? '').toString().trim();
      return u.startsWith('http');
    }

    final r1 = await _fetchFromProvider(
      provider: firstPick,
      queries: queries,
      episode: episode,
      quality: cleanQuality,
    ).timeout(const Duration(seconds: 6), onTimeout: () => null);
    if (hasValidStream(r1)) return r1;

    final r2 = await _fetchFromProvider(
      provider: secondPick,
      queries: queries,
      episode: episode,
      quality: cleanQuality,
    ).timeout(const Duration(seconds: 6), onTimeout: () => null);
    if (hasValidStream(r2)) return r2;

    return r1 ?? r2;
  }
}
