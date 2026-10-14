import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;

  const WaveformVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 12,
    this.height = 24,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final Random _rnd = Random();
  late List<double> _baseHeights;

  @override
  void initState() {
    super.initState();
    _baseHeights = List.generate(widget.barCount, (i) => 0.2 + _rnd.nextDouble() * 0.8);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isPlaying) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if (!widget.isPlaying && _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              double factor = _baseHeights[index];
              if (widget.isPlaying) {
                factor = (_baseHeights[index] + sin(_animController.value * pi * 2 + index) * 0.4).clamp(0.15, 1.0);
              } else {
                factor = 0.2;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 3.5,
                height: widget.height * factor,
                decoration: BoxDecoration(
                  color: widget.isPlaying ? AppTheme.amber : AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
