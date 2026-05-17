import 'package:flutter/material.dart';
import 'package:shizuka/core/design_tokens.dart';

class ShizukaPrimaryButton extends StatefulWidget {
  const ShizukaPrimaryButton({
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
  State<ShizukaPrimaryButton> createState() => _ShizukaPrimaryButtonState();
}

class _ShizukaPrimaryButtonState extends State<ShizukaPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDisabled ? null : widget.onPressed,
      onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.isDisabled ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? ShizukaTokens.primaryDark.withValues(alpha: 0.4)
                : ShizukaTokens.primaryDark,
            borderRadius: BorderRadius.circular(ShizukaTokens.radiusPill),
            boxShadow: widget.isDisabled
                ? null
                : [
                    BoxShadow(
                      color: ShizukaTokens.primaryDark.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
