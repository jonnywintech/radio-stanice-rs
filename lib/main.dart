import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const RadioStaniceApp());
}

class RadioStaniceApp extends StatelessWidget {
  const RadioStaniceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Radio Stanice Srbije',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005D6C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const RadioHomePage(),
    );
  }
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  static const String _apiHost = 'de1.api.radio-browser.info';

  final AudioPlayer _player = AudioPlayer();
  final Set<String> _loadingStations = <String>{};
  final Map<String, String> _streamCache = <String, String>{};

  RadioStation? _currentStation;

  final List<RadioStation> _stations = const <RadioStation>[
    RadioStation('Radio S1', <String>['radio s1', 's1 radio']),
    RadioStation('Radio OK', <String>['radio ok', 'ok radio']),
    RadioStation('TDI', <String>['tdi radio', 'tdi']),
    RadioStation('JAT', <String>['radio jat', 'jat']),
    RadioStation('Rock Radio', <String>['rock radio']),
    RadioStation('Karolina', <String>['radio karolina', 'karolina']),
    RadioStation('Red', <String>['radio red', 'red radio']),
  ];

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((PlayerState state) {
      if (!mounted) {
        return;
      }
      if (state.processingState == ProcessingState.idle &&
          !state.playing &&
          _currentStation != null) {
        setState(() {
          _currentStation = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _onStationTap(RadioStation station) async {
    if (_currentStation == station && _player.playing) {
      await _player.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentStation = null;
      });
      return;
    }

    setState(() {
      _loadingStations.add(station.name);
    });

    try {
      final String? streamUrl = await _resolveStreamUrl(station);
      if (streamUrl == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nisam pronasao stream za ${station.name}.')),
        );
        return;
      }

      await _player.setUrl(streamUrl);
      await _player.play();

      if (!mounted) {
        return;
      }
      setState(() {
        _currentStation = station;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ne mogu da pokrenem stream za ${station.name}.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingStations.remove(station.name);
        });
      }
    }
  }

  Future<String?> _resolveStreamUrl(RadioStation station) async {
    final String? cached = _streamCache[station.name];
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
      _streamCache[station.name] = bestUrl;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF3FAF8), Color(0xFFD7ECE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Radio stanice Srbije',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF113B43),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentStation == null
                      ? 'Izaberi stanicu i pokreni stream.'
                      : 'Slušaš: ${_currentStation!.name}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF28535D),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    itemCount: _stations.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final RadioStation station = _stations[index];
                      final bool isPlaying = _currentStation == station;
                      final bool isLoading =
                          _loadingStations.contains(station.name);

                      return InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _onStationTap(station),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isPlaying
                                ? const Color(0xFF007F8B)
                                : const Color(0xFFE7F5F2),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 10,
                                offset: Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: isPlaying
                                  ? const Color(0xFF005862)
                                  : const Color(0xFFB6D9D1),
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                isPlaying
                                    ? Icons.graphic_eq_rounded
                                    : Icons.radio_rounded,
                                size: 34,
                                color: isPlaying
                                    ? Colors.white
                                    : const Color(0xFF145360),
                              ),
                              const Spacer(),
                              Text(
                                station.name,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: isPlaying
                                      ? Colors.white
                                      : const Color(0xFF13343A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (isLoading)
                                SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isPlaying
                                        ? Colors.white
                                        : const Color(0xFF0E5F67),
                                  ),
                                )
                              else
                                Text(
                                  isPlaying ? 'Pauziraj' : 'Pusti stream',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isPlaying
                                        ? Colors.white.withValues(alpha: 0.94)
                                        : const Color(0xFF2F6169),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RadioStation {
  const RadioStation(this.name, this.searchQueries);

  final String name;
  final List<String> searchQueries;
}
