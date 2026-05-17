import 'package:flutter/material.dart';
import 'package:shizuka/core/design_tokens.dart';

class ShizukaSecondaryButton extends StatefulWidget {
  const ShizukaSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isFullWidth = false,
    this.isDisabled = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool isFullWidth;
  final bool isDisabled;

  @override
  State<ShizukaSecondaryButton> createState() => _ShizukaSecondaryButtonState();
}

class _ShizukaSecondaryButtonState extends State<ShizukaSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isDisabled
        ? ShizukaTokens.primaryDark.withValues(alpha: 0.4)
        : ShizukaTokens.primaryDark;

    return GestureDetector(
      onTap: widget.isDisabled ? null : widget.onPressed,
      onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.isDisabled ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: effectiveColor, width: 1.4),
            borderRadius: BorderRadius.circular(ShizukaTokens.radiusPill),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
            textAlign: TextAlign.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
