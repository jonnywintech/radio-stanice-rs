import 'package:flutter/material.dart';

import 'pages/radio_home_page.dart';

class RadioStaniceApp extends StatelessWidget {
  const RadioStaniceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF060C1B),
      fontFamily: 'Montserrat',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2DD4BF),
        secondary: Color(0xFF60A5FA),
        surface: Color(0xFF0D1830),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Radio Stanice Srbije',
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const RadioHomePage(),
    );
  }
}
