import 'dart:convert';
import 'package:http/http.dart' as http;

class StreamService {
  static const String baseUrl = 'http://191.222.39.242:3001';
  static const String resolverBaseUrl = 'http://191.222.39.226:30001';
  static const List<String> providers = [
    'oploverz',
    'otakudesu',
  ];

  static Future?> _getJson(Uri uri, {int timeoutSec = 15}) async {
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
      timeoutSec: 12,
    );
    final direct = (res?['directUrl'] ?? '').toString().trim();
    if (direct.startsWith('http')) return direct;
    return null;
  }

  static String? _pickOploverzFiledonUrl(dynamic downloadUrlObj, String quality, int serverIndex) {
    if (downloadUrlObj is! Map) return null;
    final qualities = downloadUrlObj['qualities'];
    if (qualities is! List || qualities.isEmpty) return null;

    final qClean = quality.replaceAll('p', '').trim();
    Map? chosenQual;
    for (final item in qualities) {
      if (item is Map && (item['title'] ?? '').toString().contains(qClean)) {
        chosenQual = item;
        break;
      }
    }
    chosenQual ??= qualities.last is Map ? qualities.last as Map : null;
    final urlList = chosenQual?['urls'];
    if (urlList is! List || urlList.isEmpty) return null;

    final filedonUrls = <String>[];
    final otherUrls = <String>[];
    for (final u in urlList) {
      if (u is! Map) continue;
      final href = (u['url'] ?? '').toString().trim();
      if (!href.startsWith('http')) continue;
      if (href.contains('filedon.co')) {
        filedonUrls.add(href);
      } else {
        otherUrls.add(href);
      }
    }

    final pool = filedonUrls.isNotEmpty ? filedonUrls : otherUrls;
    if (pool.isEmpty) return null;
    return pool[serverIndex < pool.length ? serverIndex : 0];
  }

  static Future?> resolveEpisode({
    required List<String> titleCandidates,
    required int episode,
    String quality = '720p',
    int serverIndex = 0,
    String preferredProvider = 'oploverz',
  }) async {
    final ordered = [
      if (providers.contains(preferredProvider)) preferredProvider,
      ...providers.where((p) => p != preferredProvider),
    ];

    for (final provider in ordered) {
      for (final rawQ in titleCandidates) {
        final q = rawQ.trim();
        if (q.length < 3) continue;

        final searchJson = await _getJson(
          Uri.parse('$baseUrl/$provider/search?q=${Uri.encodeComponent(q)}'),
        );
        final animeList = searchJson?['data']?['animeList'];
        if (animeList is! List || animeList.isEmpty) continue;

        final first = animeList.first;
        if (first is! Map) continue;
        final animeId = (first['animeId'] ?? '').toString().trim();
        if (animeId.isEmpty) continue;

        final animeJson = await _getJson(
          Uri.parse('$baseUrl/$provider/anime/${Uri.encodeComponent(animeId)}'),
        );
        final epList = animeJson?['data']?['details']?['episodeList'];
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
        if (episodeId.isEmpty) {
          final revIdx = (epList.length - episode).clamp(0, epList.length - 1);
          episodeId = (epList[revIdx]['episodeId'] ?? '').toString().trim();
        }
        if (episodeId.isEmpty) continue;

        final epJson = await _getJson(
          Uri.parse('$baseUrl/$provider/episode/${Uri.encodeComponent(episodeId)}'),
        );
        final details = epJson?['data']?['details'];
        if (details is! Map) continue;

        final downloadUrl = details['downloadUrl'];
        final qList = details['server']?['qualityList'];
        String rawStreamUrl = '';
        String serverLabel = provider.toUpperCase();

        if (provider == 'oploverz') {
          final pickedFiledon = _pickOploverzFiledonUrl(downloadUrl, quality, serverIndex);
          if (pickedFiledon != null) {
            rawStreamUrl = pickedFiledon;
            serverLabel = 'OPLOVERZ • $quality';
          }
        }

        if (rawStreamUrl.isEmpty && qList is List && qList.isNotEmpty) {
          Map? chosenQual;
          final qClean = quality.replaceAll('p', '');
          for (final item in qList) {
            if (item is Map && (item['title'] ?? '').toString().contains(qClean)) {
              chosenQual = item;
              break;
            }
          }
          chosenQual ??= qList.first is Map ? qList.first as Map : null;

          final srvList = chosenQual?['serverList'];
          if (srvList is List && srvList.isNotEmpty) {
            final picked = srvList[serverIndex < srvList.length ? serverIndex : 0];
            if (picked is Map) {
              final serverId = (picked['serverId'] ?? '').toString().trim();
              final sTitle = (picked['title'] ?? 'Server').toString().trim();
              if (serverId.isNotEmpty) {
                final srvJson = await _getJson(
                  Uri.parse('$baseUrl/$provider/server/${Uri.encodeComponent(serverId)}'),
                );
                final u = (srvJson?['data']?['details']?['url'] ?? '').toString().trim();
                if (u.startsWith('http')) {
                  rawStreamUrl = u;
                  serverLabel = '${provider.toUpperCase()} • $sTitle';
                }
              }
            }
          }
        }

        if (rawStreamUrl.isNotEmpty) {
          final directMp4 = await _resolveDirectMp4(rawStreamUrl);
          if (directMp4 != null && directMp4.isNotEmpty) {
            return {
              'url': directMp4,
              'label': serverLabel,
              'provider': provider,
              'downloadUrl': downloadUrl,
            };
          }
        }
      }
    }
    return null;
  }
}
