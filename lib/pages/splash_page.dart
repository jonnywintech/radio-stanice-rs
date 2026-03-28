import 'dart:async';

import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.nextPage});

  final Widget nextPage;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _scale = Tween<double>(
      begin: 0.94,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _navTimer = Timer(const Duration(milliseconds: 1450), () {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) => widget.nextPage,
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
        ),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060C1B),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _SplashBackground(),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  'assets/branding/logo_splash.png',
                  width: 260,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0D1B3D),
            Color(0xFF060C1B),
            Color(0xFF040914),
          ],
          stops: <double>[0, 0.58, 1],
        ),
      ),
      child: Stack(
        children: const <Widget>[
          Positioned(
            top: -130,
            right: -80,
            child: _Glow(color: Color(0xFF1D4ED8), size: 260),
          ),
          Positioned(
            left: -90,
            bottom: -100,
            child: _Glow(color: Color(0xFF0EA5A3), size: 230),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

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
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 120,
              spreadRadius: 45,
            ),
          ],
        ),
      ),
    );
  }
}
