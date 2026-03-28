import 'package:flutter/material.dart';

import '../models/radio_station.dart';

class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final RadioStation station;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = isPlaying
        ? const Color(0xFF1B2A4A)
        : const Color(0xFF111B32);
    final Color border = isPlaying
        ? const Color(0xFF2DD4BF)
        : const Color(0xFF24385F);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 98,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bg.withValues(alpha: 0.96),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xAA040916),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
          border: Border.all(color: border, width: isPlaying ? 1.5 : 1),
        ),
        child: Row(
          children: <Widget>[
            _StationCover(imageUrl: station.coverUrl, isPlaying: isPlaying),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isLoading)
                    Row(
                      children: <Widget>[
                        const _StationLoadingBars(),
                        const SizedBox(width: 8),
                        Text(
                          'Povezivanje...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      isPlaying ? 'Now Playing' : 'Tap to Play',
                      style: TextStyle(
                        color: isPlaying
                            ? const Color(0xFF2DD4BF)
                            : Colors.white.withValues(alpha: 0.66),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlaying
                    ? const Color(0xFF2DD4BF)
                    : const Color(0xFF223659),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? const Color(0xFF072623) : Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationLoadingBars extends StatefulWidget {
  const _StationLoadingBars();

  @override
  State<_StationLoadingBars> createState() => _StationLoadingBarsState();
}

class _StationLoadingBarsState extends State<_StationLoadingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double progress = _controller.value;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(3, (int index) {
              final double phase = (progress + (index * 0.2)) % 1;
              final double wave = (phase < 0.5 ? phase : 1 - phase) * 2;
              final double height = 4 + (wave * 10);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                curve: Curves.easeOut,
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF147A73),
                    const Color(0xFF2DD4BF),
                    wave,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _StationCover extends StatelessWidget {
  const _StationCover({required this.imageUrl, required this.isPlaying});

  final String? imageUrl;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying
              ? const Color(0xFF2DD4BF).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            else
              _fallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    const Color(0x66040B16),
                    const Color(0xCC040B16),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(
                  isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF223659), Color(0xFF141C31)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.radio_rounded,
          size: 26,
          color: Colors.white.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}
