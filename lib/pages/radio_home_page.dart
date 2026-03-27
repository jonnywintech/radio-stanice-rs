import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/radio_station.dart';
import '../services/radio_browser_service.dart';
import '../widgets/radio_home_header.dart';
import '../widgets/station_card.dart';

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  final AudioPlayer _player = AudioPlayer();
  final RadioBrowserService _radioService = RadioBrowserService();
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
      final String? streamUrl = await _radioService.resolveStreamUrl(
        station: station,
        streamCache: _streamCache,
      );
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color topColor = isDark
        ? const Color(0xFF102026)
        : const Color(0xFFF3FAF8);
    final Color bottomColor = isDark
        ? const Color(0xFF0A1418)
        : const Color(0xFFD7ECE7);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[topColor, bottomColor],
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
                RadioHomeHeader(currentStationName: _currentStation?.name),
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

                      return StationCard(
                        station: station,
                        isPlaying: _currentStation == station,
                        isLoading: _loadingStations.contains(station.name),
                        onTap: () => _onStationTap(station),
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
