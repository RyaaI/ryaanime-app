import 'dart:convert';
import 'package:http/http.dart' as http;

class StreamService {
  static const String baseUrl = 'http://191.222.39.242:3001';
  static const String resolverBaseUrl = 'http://191.222.39.226:30001';

  static Future<Map<String, dynamic>?> _getJson(Uri uri, {int timeoutSec = 15}) async {
    try {
      final res = await http.get(uri).timeout(Duration(seconds: timeoutSec));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _resolveDirectMp4(String rawUrl) async {
    if (rawUrl.isEmpty) return null;
    if (RegExp(r'\.mp4(\?|$)', caseSensitive: false).hasMatch(rawUrl)) {
      return rawUrl;
    }
    final res = await _getJson(
      Uri.parse('$resolverBaseUrl/resolve?url=${Uri.encodeComponent(rawUrl)}'),
      timeoutSec: 8,
    );
    final direct = (res?['directUrl'] ?? '').toString().trim();
    if (direct.startsWith('http')) return direct;
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
    for (final q in queries) {
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

      for (final candidate in animeList.take(5)) {
        if (candidate is! Map) continue;
        final animeId = (candidate['animeId'] ?? '').toString().trim();
        final candTitle = (candidate['title'] ?? '').toString().trim();
        if (animeId.isEmpty) continue;
        final hay = '$candTitle $animeId'.toLowerCase();
        if (reqSeason != null && reqSeason.isNotEmpty) {
          final hasSeason = RegExp(r'(?:season[-_\s]*' + reqSeason + r'\b|\bs' + reqSeason + r'(?:\b|-|_))', caseSensitive: false).hasMatch(hay);
          if (!hasSeason) continue;
        }
        final minRequiredTokens = keyTokens.length >= 2 ? 2 : 1;
        if (keyTokens.isNotEmpty) {
          final matchedTokens = keyTokens.where((t) => hay.contains(t)).length;
          if (matchedTokens < minRequiredTokens) continue;
        }

        final animeJson = await _getJson(
          Uri.parse('$baseUrl/$provider/anime/${Uri.encodeComponent(animeId)}'),
        );
        final animeDetails = animeJson?['data']?['details'];
        final detailTitle = (animeDetails is Map ? (animeDetails['title'] ?? '') : '').toString().trim();
        final fullHay = '$hay $detailTitle'.toLowerCase();
        if (reqSeason != null && reqSeason.isNotEmpty) {
          final hasSeasonDetail = RegExp(r'(?:season[-_\s]*' + reqSeason + r'\b|\bs' + reqSeason + r'(?:\b|-|_))', caseSensitive: false).hasMatch(fullHay);
          if (!hasSeasonDetail) continue;
        }
        if (keyTokens.isNotEmpty) {
          final matchedDetailTokens = keyTokens.where((t) => fullHay.contains(t)).length;
          if (matchedDetailTokens < minRequiredTokens) continue;
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
        if (details is! Map) continue;

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
            for (final srv in orderedServers.take(3)) {
              if (srv is! Map) continue;
              final serverId = (srv['serverId'] ?? '').toString().trim();
              final sTitle = (srv['title'] ?? 'Server').toString().trim();
              if (serverId.isEmpty) continue;
              final srvJson = await _getJson(
                Uri.parse('$baseUrl/$provider/server/${Uri.encodeComponent(serverId)}'),
              );
              final u = (srvJson?['data']?['details']?['url'] ?? '').toString().trim();
              if (!u.startsWith('http')) continue;
              final directMp4 = await _resolveDirectMp4(u);
              if (directMp4 != null && directMp4.isNotEmpty) {
                final actualRes = (chosenQual?['title'] ?? quality).toString().trim();
                return {
                  'url': directMp4,
                  'label': '$actualRes',
                  'provider': provider,
                  'downloadUrl': downloadUrl,
                };
              }
            }
          }
        }
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> resolveEpisode({
    required List<String> titleCandidates,
    required int episode,
    String quality = '720p',
    int serverIndex = 0,
    String preferredProvider = 'oploverz',
  }) async {
    final queries = _expandQueries(titleCandidates);

    if (serverIndex == 1) {
      return await _fetchFromProvider(
        provider: 'otakudesu',
        queries: queries,
        episode: episode,
        quality: quality == '1080p' ? '720p' : quality,
      );
    }
    if (serverIndex == 2) {
      return await _fetchFromProvider(
        provider: 'otakudesu',
        queries: queries,
        episode: episode,
        quality: '480p',
      );
    }

    final firstPick = preferredProvider == 'otakudesu' ? 'otakudesu' : 'oploverz';
    final secondPick = firstPick == 'oploverz' ? 'otakudesu' : 'oploverz';

    final primary = await _fetchFromProvider(
      provider: firstPick,
      queries: queries,
      episode: episode,
      quality: quality,
    );
    if (primary != null) return primary;

    return await _fetchFromProvider(
      provider: secondPick,
      queries: queries,
      episode: episode,
      quality: quality,
    );
  }
}
