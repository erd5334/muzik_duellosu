import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VinylRecord extends StatefulWidget {
  final bool isPlaying;
  final String? artworkUrl;
  final double size;

  const VinylRecord({
    super.key,
    required this.isPlaying,
    this.artworkUrl,
    this.size = 180,
  });

  @override
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VinylRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF111319),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFF232838), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Plak Kanalları (Grooves)
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _VinylGroovePainter(),
            ),

            // Orta Göbek (Albüm Kapağı veya Plak Etiketi)
            Container(
              width: widget.size * 0.42,
              height: widget.size * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                border: Border.all(color: AppTheme.amber.withValues(alpha: 0.5), width: 2),
              ),
              child: ClipOval(
                child: widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty
                    ? Image.network(
                        widget.artworkUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderLabel(),
                      )
                    : _buildPlaceholderLabel(),
              ),
            ),

            // Plak İğne Deliği (Center Spindle Hole)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0D0F17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderLabel() {
    return Container(
      color: AppTheme.surfaceLight,
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: AppTheme.amber, size: 28),
      ),
    );
  }
}

class _VinylGroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF1E2230).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Eşmerkezli plak olukları
    for (double r = size.width * 0.25; r < size.width * 0.46; r += 7.0) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
