import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/radio_station.dart';
import '../services/radio_browser_service.dart';
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

  int _selectedTab = 0;
  int _playRequestId = 0;
  RadioStation? _currentStation;

  final List<RadioStation> _stations = const <RadioStation>[
    RadioStation('Radio S1', <String>[
      'radio s1',
      's1 radio',
    ], coverUrl: 'https://picsum.photos/seed/radios1/600/600'),
    RadioStation('Radio OK', <String>[
      'radio ok',
      'ok radio',
    ], coverUrl: 'https://picsum.photos/seed/radiook/600/600'),
    RadioStation('TDI', <String>[
      'tdi radio',
      'tdi',
    ], coverUrl: 'https://picsum.photos/seed/tdiradio/600/600'),
    RadioStation('JAT', <String>[
      'radio jat',
      'jat',
    ], coverUrl: 'https://picsum.photos/seed/jatradio/600/600'),
    RadioStation('Rock Radio', <String>[
      'rock radio',
    ], coverUrl: 'https://picsum.photos/seed/rockradio/600/600'),
    RadioStation('Karolina', <String>[
      'radio karolina',
      'karolina',
    ], coverUrl: 'https://picsum.photos/seed/karolina/600/600'),
    RadioStation('Red', <String>[
      'radio red',
      'red radio',
    ], coverUrl: 'https://picsum.photos/seed/redradio/600/600'),
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
    if (_loadingStations.contains(station.name)) {
      return;
    }

    if (_currentStation == station && _player.playing) {
      _playRequestId++;
      await _player.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentStation = null;
        _loadingStations.remove(station.name);
      });
      return;
    }

    final int requestId = ++_playRequestId;

    setState(() {
      _currentStation = station;
      _loadingStations
        ..clear()
        ..add(station.name);
    });

    try {
      final List<String> streamUrls = await _radioService.resolveStreamUrls(
        station: station,
        streamCache: _streamCache,
      );

      if (!mounted || requestId != _playRequestId) {
        return;
      }

      if (streamUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nisam pronasao stream za ${station.name}.')),
        );
        setState(() {
          if (_currentStation == station) {
            _currentStation = null;
          }
        });
        return;
      }

      if (_player.playing) {
        await _player.stop();
      }

      String? selectedStream;
      PlayerException? lastPlayerError;

      for (final String streamUrl in streamUrls.take(8)) {
        try {
          final Uri streamUri = Uri.parse(streamUrl);
          await _player.setAudioSource(
            AudioSource.uri(
              streamUri,
              headers: const <String, String>{
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36',
              },
            ),
          );
          await _player.play();
          selectedStream = streamUrl;
          break;
        } on PlayerException catch (error) {
          lastPlayerError = error;
          debugPrint(
            'Stream candidate failed for ${station.name}: url=$streamUrl, code=${error.code}, message=${error.message}',
          );
        }
      }

      if (selectedStream == null) {
        if (lastPlayerError != null) {
          debugPrint(
            'Playback failed for ${station.name}: code=${lastPlayerError.code}, message=${lastPlayerError.message}',
          );
        }
        throw Exception('No playable stream candidate found.');
      }

      _streamCache[station.name] = selectedStream;

      if (!mounted || requestId != _playRequestId) {
        return;
      }
      setState(() {
        _currentStation = station;
      });
    } on PlayerException catch (error) {
      debugPrint(
        'Playback failed for ${station.name}: code=${error.code}, message=${error.message}',
      );
      if (!mounted || requestId != _playRequestId) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ne mogu da pokrenem stream za ${station.name}.'),
        ),
      );
      setState(() {
        if (_currentStation == station) {
          _currentStation = null;
        }
      });
    } catch (error) {
      debugPrint('Playback failed for ${station.name}: $error');
      if (!mounted || requestId != _playRequestId) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ne mogu da pokrenem stream za ${station.name}.'),
        ),
      );
      setState(() {
        if (_currentStation == station) {
          _currentStation = null;
        }
      });
    } finally {
      if (mounted && requestId == _playRequestId) {
        setState(() {
          _loadingStations.remove(station.name);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060C1B),
      body: Stack(
        children: <Widget>[
          const _DeepBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _TopAppBar(),
                        const SizedBox(height: 14),
                        const _SearchField(),
                        const SizedBox(height: 22),
                        const _SectionTitle(title: 'Recently Played'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 134,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _stations.length.clamp(0, 5),
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (BuildContext context, int index) {
                              final RadioStation station = _stations[index];
                              final bool playing = _currentStation == station;

                              return _MiniStationTile(
                                station: station,
                                isPlaying: playing,
                                onTap: () => _onStationTap(station),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _SectionTitle(title: 'Featured Genres'),
                        const SizedBox(height: 12),
                        const Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _GenrePill(
                              icon: Icons.music_note_rounded,
                              label: 'Pop',
                              colors: <Color>[
                                Color(0xFF2DD4BF),
                                Color(0xFF0EA5A3),
                              ],
                            ),
                            _GenrePill(
                              icon: Icons.electric_bolt_rounded,
                              label: 'Electronic',
                              colors: <Color>[
                                Color(0xFF8B5CF6),
                                Color(0xFF4F46E5),
                              ],
                            ),
                            _GenrePill(
                              icon: Icons.graphic_eq_rounded,
                              label: 'Rock',
                              colors: <Color>[
                                Color(0xFFFB7185),
                                Color(0xFFB91C1C),
                              ],
                            ),
                            _GenrePill(
                              icon: Icons.piano_rounded,
                              label: 'Jazz',
                              colors: <Color>[
                                Color(0xFFF59E0B),
                                Color(0xFFB45309),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _SectionTitle(title: 'Explore Stations'),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _stations.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final RadioStation station = _stations[index];

                            return StationCard(
                              station: station,
                              isPlaying: _currentStation == station,
                              isLoading: _loadingStations.contains(
                                station.name,
                              ),
                              onTap: () => _onStationTap(station),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        if (_currentStation != null)
                          _NowPlayingPanel(
                            stationName: _currentStation!.name,
                            onStop: () => _onStationTap(_currentStation!),
                          ),
                        const SizedBox(height: 88),
                      ],
                    ),
                  ),
                ),
                _BottomNavBar(
                  selectedTab: _selectedTab,
                  onSelect: (int index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeepBackground extends StatelessWidget {
  const _DeepBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0C1631),
            Color(0xFF060C1B),
            Color(0xFF040914),
          ],
          stops: <double>[0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: const <Widget>[
          Positioned(
            top: -120,
            left: -70,
            child: _GlowOrb(color: Color(0xFF1D4ED8), size: 280),
          ),
          Positioned(
            right: -90,
            top: 140,
            child: _GlowOrb(color: Color(0xFF0EA5A3), size: 250),
          ),
          Positioned(
            bottom: -100,
            left: 60,
            child: _GlowOrb(color: Color(0xFF7C3AED), size: 220),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 90,
              spreadRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        _CircleIconButton(icon: Icons.menu_rounded),
        SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: 'Radio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                TextSpan(
                  text: ' Now',
                  style: TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        _CircleIconButton(icon: Icons.search_rounded),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF111C35).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2C4068), width: 1),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: const Color(0xFF101B34).withValues(alpha: 0.84),
        border: Border.all(color: const Color(0xFF2B426F), width: 1),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.58),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'Search stations, genres...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.96),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MiniStationTile extends StatelessWidget {
  const _MiniStationTile({
    required this.station,
    required this.isPlaying,
    required this.onTap,
  });

  final RadioStation station;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF111B33).withValues(alpha: 0.9),
          border: Border.all(
            color: isPlaying
                ? const Color(0xFF2DD4BF)
                : const Color(0xFF283C62),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 74,
                child: Image.network(
                  station.coverUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF1B2746),
                    child: const Icon(
                      Icons.radio_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              station.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              isPlaying ? 'Now Playing' : 'Station',
              style: TextStyle(
                color: isPlaying
                    ? const Color(0xFF2DD4BF)
                    : Colors.white.withValues(alpha: 0.58),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenrePill extends StatelessWidget {
  const _GenrePill({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(colors: colors),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingPanel extends StatelessWidget {
  const _NowPlayingPanel({required this.stationName, required this.onStop});

  final String stationName;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1A2C4F), Color(0xFF10213E)],
        ),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Color(0xFF2DD4BF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Now Playing',
                  style: TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onStop,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2DD4BF),
              ),
              child: const Icon(
                Icons.pause_rounded,
                color: Color(0xFF072623),
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedTab, required this.onSelect});

  final int selectedTab;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const List<IconData> icons = <IconData>[
      Icons.home_rounded,
      Icons.radio_rounded,
      Icons.favorite_rounded,
      Icons.person_rounded,
    ];
    const List<String> labels = <String>[
      'Home',
      'Stations',
      'Favorites',
      'Profile',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1830).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF21385D), width: 1),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0xAA020611),
              blurRadius: 26,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: List<Widget>.generate(icons.length, (int index) {
            final bool selected = selectedTab == index;

            return Expanded(
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      icons[index],
                      color: selected
                          ? const Color(0xFF2DD4BF)
                          : Colors.white.withValues(alpha: 0.54),
                      size: 23,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF2DD4BF)
                            : Colors.white.withValues(alpha: 0.54),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
}
