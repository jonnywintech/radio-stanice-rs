import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/radio_station.dart';

class RadioBrowserService {
  static const String _apiHost = 'de1.api.radio-browser.info';

  Future<String?> resolveStreamUrl({
    required RadioStation station,
    required Map<String, String> streamCache,
  }) async {
    final String? cached = streamCache[station.name];
    if (cached != null && cached.isNotEmpty) {
      return cached;
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

    final String? bestUrl = _pickBestUrl(station, candidates);
    if (bestUrl != null) {
      streamCache[station.name] = bestUrl;
    }
    return bestUrl;
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

    final Uri uri = Uri.https(_apiHost, '/json/stations/search', params);
    final http.Response response = await http.get(uri);
    if (response.statusCode != 200) {
      return <Map<String, dynamic>>[];
    }

    final Object decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }

    return decoded
        .whereType<Map>()
        .map(
          (Map item) => item.map(
            (dynamic key, dynamic value) => MapEntry(
              key.toString(),
              value,
            ),
          ),
        )
        .toList();
  }

  String? _pickBestUrl(
    RadioStation station,
    List<Map<String, dynamic>> candidates,
  ) {
    if (candidates.isEmpty) {
      return null;
    }

    final Set<String> tokens = station.name
        .toLowerCase()
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((String t) => t.length > 1)
        .toSet();

    Map<String, dynamic>? winner;
    int bestScore = -1;

    for (final Map<String, dynamic> item in candidates) {
      final String stream =
          (item['url_resolved'] ?? item['url'] ?? '').toString().trim();
      if (stream.isEmpty) {
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

      final String countryCode =
          (item['countrycode'] ?? '').toString().toLowerCase();
      if (countryCode == 'rs') {
        score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        winner = item;
      }
    }

    if (winner == null) {
      return null;
    }

    return (winner['url_resolved'] ?? winner['url'] ?? '').toString();
  }
}
