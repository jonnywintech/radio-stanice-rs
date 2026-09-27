import 'dart:convert';
import 'dart:collection';

import 'package:http/http.dart' as http;

import '../models/radio_station.dart';

class RadioBrowserService {
  static const List<String> _apiHosts = <String>[
    'de1.api.radio-browser.info',
    'nl1.api.radio-browser.info',
    'fr1.api.radio-browser.info',
  ];
  static const Duration _requestTimeout = Duration(seconds: 6);
  static const Duration _resolveTimeout = Duration(seconds: 12);

  Future<String?> resolveStreamUrl({
    required RadioStation station,
    required Map<String, String> streamCache,
  }) async {
    final List<String> urls = await resolveStreamUrls(
      station: station,
      streamCache: streamCache,
    );
    if (urls.isEmpty) {
      return null;
    }
    return urls.first;
  }

  Future<List<String>> resolveStreamUrls({
    required RadioStation station,
    required Map<String, String> streamCache,
  }) async {
    return _resolveStreamUrlsInternal(
      station: station,
      streamCache: streamCache,
    ).timeout(_resolveTimeout, onTimeout: () => <String>[]);
  }

  Future<List<String>> _resolveStreamUrlsInternal({
    required RadioStation station,
    required Map<String, String> streamCache,
  }) async {
    final String? cached = streamCache[station.name];
    if (cached != null && cached.isNotEmpty) {
      return <String>[cached];
    }

    final List<Map<String, dynamic>> candidates = <Map<String, dynamic>>[];

    for (final String query in station.searchQueries) {
      final List<Map<String, dynamic>> local = await _searchStations(
        query: query,
        countryCode: 'RS',
      );
      candidates.addAll(local);
      if (candidates.isNotEmpty) {
        break;
      }
    }

    if (candidates.isEmpty) {
      for (final String query in station.searchQueries) {
        final List<Map<String, dynamic>> global = await _searchStations(
          query: query,
        );
        candidates.addAll(global);
        if (candidates.isNotEmpty) {
          break;
        }
      }
    }

    final List<String> rankedUrls = _rankUrls(station, candidates);
    if (rankedUrls.isNotEmpty) {
      streamCache[station.name] = rankedUrls.first;
    }
    return rankedUrls;
  }

  Future<List<Map<String, dynamic>>> _searchStations({
    required String query,
    String? countryCode,
  }) async {
    final Map<String, String> params = <String, String>{
      'name': query,
      'hidebroken': 'true',
      'limit': '25',
    };
    if (countryCode != null) {
      params['countrycode'] = countryCode;
    }

    for (final String host in _apiHosts) {
      try {
        final Uri uri = Uri.https(host, '/json/stations/search', params);
        final http.Response response = await http
            .get(uri)
            .timeout(_requestTimeout);
        if (response.statusCode != 200) {
          continue;
        }

        final Object decoded = jsonDecode(response.body);
        if (decoded is! List) {
          continue;
        }

        return decoded
            .whereType<Map>()
            .map(
              (Map item) => item.map(
                (dynamic key, dynamic value) => MapEntry(key.toString(), value),
              ),
            )
            .toList();
      } catch (_) {
        // Try the next mirror if this host is unavailable.
      }
    }

    return <Map<String, dynamic>>[];
  }

  List<String> _rankUrls(
    RadioStation station,
    List<Map<String, dynamic>> candidates,
  ) {
    if (candidates.isEmpty) {
      return <String>[];
    }

    final Set<String> tokens = station.name
        .toLowerCase()
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((String t) => t.length > 1)
        .toSet();

    final List<_ScoredStream> scored = <_ScoredStream>[];

    for (final Map<String, dynamic> item in candidates) {
      final String resolved = (item['url_resolved'] ?? '').toString().trim();
      final String fallback = (item['url'] ?? '').toString().trim();
      final String stream = resolved.isNotEmpty ? resolved : fallback;
      if (stream.isEmpty) {
        continue;
      }

      final Uri? uri = Uri.tryParse(stream);
      if (uri == null ||
          !(uri.scheme == 'http' || uri.scheme == 'https') ||
          uri.host.isEmpty) {
        continue;
      }

      final String name = (item['name'] ?? '').toString().toLowerCase();
      int score = 0;

      for (final String token in tokens) {
        if (name.contains(token)) {
          score += 2;
        }
      }

      for (final String query in station.searchQueries) {
        if (name.contains(query.toLowerCase())) {
          score += 3;
        }
      }

      final String countryCode = (item['countrycode'] ?? '')
          .toString()
          .toLowerCase();
      if (countryCode == 'rs') {
        score += 1;
      }

      if (resolved.isNotEmpty) {
        score += 2;
      }

      scored.add(_ScoredStream(url: stream, score: score));
    }

    if (scored.isEmpty) {
      return <String>[];
    }

    scored.sort((_ScoredStream a, _ScoredStream b) => b.score - a.score);

    final LinkedHashSet<String> uniqueUrls = LinkedHashSet<String>();
    for (final _ScoredStream item in scored) {
      uniqueUrls.add(item.url);
    }

    return uniqueUrls.toList(growable: false);
  }
}

class _ScoredStream {
  const _ScoredStream({required this.url, required this.score});

  final String url;
  final int score;
}
