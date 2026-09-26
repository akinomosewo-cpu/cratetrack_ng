import 'package:flutter/material.dart';

/// Animates a numeric value counting up from its previous value whenever it
/// changes, formatting each intermediate frame with [formatter]. Used for the
/// dashboard's stat cards and revenue total so updates feel alive without
/// blocking the UI.
class AnimatedCounter extends StatelessWidget {
  final num value;
  final String Function(num value) formatter;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final display = value is int ? animatedValue.round() : animatedValue;
        return Text(formatter(display), style: style);
      },
    );
  }
}
