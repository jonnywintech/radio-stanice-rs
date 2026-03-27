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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color activeBackground =
        isDark ? colorScheme.primary : const Color(0xFF007F8B);
    final Color activeBorder =
        isDark ? colorScheme.primaryContainer : const Color(0xFF005862);
    final Color inactiveBackground =
        isDark ? const Color(0xFF1A2A2F) : const Color(0xFFE7F5F2);
    final Color inactiveBorder =
        isDark ? const Color(0xFF35515A) : const Color(0xFFB6D9D1);
    final Color activeForeground =
        isDark ? colorScheme.onPrimary : Colors.white;
    final Color inactiveForeground =
        isDark ? colorScheme.onSurface : const Color(0xFF13343A);
    final Color inactiveMuted =
        isDark ? colorScheme.onSurfaceVariant : const Color(0xFF2F6169);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isPlaying ? activeBackground : inactiveBackground,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isDark
                  ? const Color(0x33000000)
                  : const Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isPlaying ? activeBorder : inactiveBorder,
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
              size: 34,
              color: isPlaying
                  ? activeForeground
                  : (isDark
                      ? colorScheme.primary.withValues(alpha: 0.92)
                      : const Color(0xFF145360)),
            ),
            const Spacer(),
            Text(
              station.name,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: isPlaying ? activeForeground : inactiveForeground,
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
                      ? activeForeground
                      : (isDark
                          ? colorScheme.primary
                          : const Color(0xFF0E5F67)),
                ),
              )
            else
              Text(
                isPlaying ? 'Pauziraj' : 'Pusti stream',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPlaying
                      ? activeForeground.withValues(alpha: 0.94)
                      : inactiveMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
