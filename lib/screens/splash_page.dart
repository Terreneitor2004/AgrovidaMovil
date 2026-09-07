import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoOffset;
  late final Animation<double> _textOpacity;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1850),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _finish();
        });

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.28, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.64, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.52, curve: Curves.easeOutBack),
      ),
    );
    _logoRotation = Tween<double>(begin: -0.09, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _logoOffset =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 34,
              end: -8,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 68,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: -8,
              end: 0,
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            weight: 32,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0, 0.68)),
        );
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.68, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = math.min(shortestSide * 0.46, 190.0);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF164F39), Color(0xFF09291D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final haloScale = 0.92 + (0.08 * _controller.value);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _logoOffset.value),
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Transform.scale(
                              scale: haloScale,
                              child: Container(
                                width: logoSize,
                                height: logoSize,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.96),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 36,
                                      offset: const Offset(0, 18),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 24,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Semantics(
                                  label: 'Logo de AgroVida',
                                  image: true,
                                  child: Image.asset(
                                    'assets/branding/agrovida_logo.png',
                                    key: const ValueKey('splash-logo'),
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.28),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(
                                  0.32,
                                  0.68,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            ),
                        child: const Text(
                          'AgroVida',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SizedBox(
                        width: 92,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: _controller.value,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFB9DFC6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
