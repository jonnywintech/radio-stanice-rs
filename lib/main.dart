import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _safeInitAudioBackground();
  runApp(const RadioStaniceApp());
}

Future<void> _safeInitAudioBackground() async {
  if (kIsWeb) {
    return;
  }

  final bool supportsBackgroundAudio =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  if (!supportsBackgroundAudio) {
    return;
  }

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'rs.radio.stanice.channel.audio',
      androidNotificationChannelName: 'Radio Playback',
      androidNotificationOngoing: true,
    ).timeout(const Duration(seconds: 5));
  } catch (_) {
    // Allow app startup even if platform initialization is unavailable.
  }
}
