import 'package:flutter/material.dart';

class RadioHomeHeader extends StatelessWidget {
  const RadioHomeHeader({
    super.key,
    required this.currentStationName,
  });

  final String? currentStationName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Radio stanice Srbije',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          currentStationName == null
              ? 'Izaberi stanicu i pokreni stream.'
              : 'Slušaš: $currentStationName',
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
