import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shizuka/core/design_tokens.dart';

class ShizukaTextInput extends StatefulWidget {
  const ShizukaTextInput({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.prefixIcon,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? prefixIcon;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  State<ShizukaTextInput> createState() => _ShizukaTextInputState();
}

class _ShizukaTextInputState extends State<ShizukaTextInput> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ShizukaTokens.radiusSm),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: ShizukaTokens.primaryDark.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        obscureText: widget.obscureText,
        textAlign: widget.textAlign,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        onSubmitted: widget.onSubmitted,
        style: widget.textStyle ??
            const TextStyle(fontSize: 15, color: ShizukaTokens.textPrimary),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          filled: true,
          fillColor: ShizukaTokens.background,
          labelStyle: TextStyle(
            color: _isFocused
                ? ShizukaTokens.primaryDark
                : ShizukaTokens.textSecondary,
            fontSize: 14,
          ),
          hintStyle: const TextStyle(
            color: ShizukaTokens.textSecondary,
            fontSize: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ShizukaTokens.radiusSm),
            borderSide: const BorderSide(color: ShizukaTokens.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ShizukaTokens.radiusSm),
            borderSide:
                const BorderSide(color: ShizukaTokens.primaryDark, width: 2),
          ),
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
