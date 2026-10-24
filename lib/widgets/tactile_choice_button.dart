import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class TactileChoiceButton extends StatefulWidget {
  final String label; // "A", "B", "C", "D"
  final String text;
  final bool isEliminated;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final bool isCompact;
  final Widget? opponentBadge;
  final VoidCallback? onTap;

  const TactileChoiceButton({
    super.key,
    required this.label,
    required this.text,
    this.isEliminated = false,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.isCompact = false,
    this.opponentBadge,
    this.onTap,
  });

  @override
  State<TactileChoiceButton> createState() => _TactileChoiceButtonState();
}

class _TactileChoiceButtonState extends State<TactileChoiceButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isEliminated) {
      return Opacity(
        opacity: 0.18,
        child: _buildButtonContainer(
          bgColor: AppTheme.surface.withValues(alpha: 0.5),
          borderColor: Colors.transparent,
          textColor: AppTheme.textMuted,
        ),
      );
    }

    Color bgColor = AppTheme.surface;
    Color borderColor = AppTheme.border;
    Color textColor = AppTheme.textPrimary;
    Widget? trailingIcon;

    if (widget.showResult) {
      if (widget.isCorrect) {
        bgColor = AppTheme.emerald.withValues(alpha: 0.2);
        borderColor = AppTheme.emerald;
        textColor = Colors.white;
        trailingIcon = const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 22);
      } else if (widget.isSelected && !widget.isCorrect) {
        bgColor = AppTheme.crimson.withValues(alpha: 0.2);
        borderColor = AppTheme.crimson;
        textColor = Colors.white;
        trailingIcon = const Icon(Icons.cancel_rounded, color: AppTheme.crimson, size: 22);
      }
    }

    return GestureDetector(
      onTapDown: widget.showResult || widget.onTap == null ? null : (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: widget.showResult || widget.onTap == null ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.showResult ? null : () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: _buildButtonContainer(
          bgColor: bgColor,
          borderColor: borderColor,
          textColor: textColor,
          trailingIcon: trailingIcon,
        ),
      ),
    );
  }

  Widget _buildButtonContainer({
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    Widget? trailingIcon,
  }) {
    final hasResultGlow = widget.showResult && (widget.isCorrect || (widget.isSelected && !widget.isCorrect));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 12 : 16,
        vertical: widget.isCompact ? 9 : 13,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: hasResultGlow ? 2.0 : 1.5),
        boxShadow: [
          if (widget.showResult && widget.isCorrect) ...[
            BoxShadow(
              color: AppTheme.emerald.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ] else if (widget.showResult && widget.isSelected && !widget.isCorrect) ...[
            BoxShadow(
              color: AppTheme.crimson.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ] else ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ],
      ),
      child: Row(
        children: [
          // Rozet A, B, C, D
          Container(
            width: widget.isCompact ? 28 : 32,
            height: widget.isCompact ? 28 : 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.amber,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Metin
          Expanded(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.opponentBadge != null) ...[
            const SizedBox(width: 8),
            widget.opponentBadge!,
          ],
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            trailingIcon,
          ],
        ],
      ),
    );
  }
}
