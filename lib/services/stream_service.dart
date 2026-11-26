import 'dart:convert';
import 'package:http/http.dart' as http;

class StreamService {
  static const String baseUrl = 'http://191.222.39.242:3001';
  static const List<String> providers = [
    'otakudesu',
    'samehadaku',
    'kuramanime',
    'oploverz',
  ];

  static Future<Map<String, dynamic>>? _getJson(Uri uri) async {
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>>? resolveEpisode({
    required List<String> titleCandidates,
    required int episode,
    String quality = '480p',
    int serverIndex = 0,
    String preferredProvider = 'otakudesu',
  }) async {
    final ordered = [
      preferredProvider,
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
        String streamUrl = '';
        String serverLabel = provider.toUpperCase();

        if (qList is List && qList.isNotEmpty) {
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
                  streamUrl = u;
                  serverLabel = '${provider.toUpperCase()} • $sTitle';
                }
              }
            }
          }
        }

        if (streamUrl.isEmpty) {
          final defUrl = (details['defaultStreamingUrl'] ?? '').toString().trim();
          if (defUrl.startsWith('http')) {
            streamUrl = defUrl;
            serverLabel = '${provider.toUpperCase()} • Default';
          }
        }

        if (streamUrl.isNotEmpty) {
          return {
            'url': streamUrl,
            'label': serverLabel,
            'provider': provider,
            'downloadUrl': downloadUrl,
          };
        }
      }
    }
    return null;
  }
}
