library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';

/// Soft gray unit field: label, value left, unit right; green focus border.
class CalcUnitField extends StatefulWidget {
  const CalcUnitField({
    required this.label,
    required this.unit,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.readOnly = false,
    super.key,
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  State<CalcUnitField> createState() => _CalcUnitFieldState();
}

class _CalcUnitFieldState extends State<CalcUnitField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() {
        setState(() => _focused = _focus.hasFocus);
      });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null;
    final active = _focused || hasError;
    final borderColor = hasError
        ? Theme.of(context).colorScheme.error
        : active
            ? YakitlaColors.accent
            : Colors.transparent;
    final labelColor = hasError
        ? Theme.of(context).colorScheme.error
        : active
            ? YakitlaColors.accent
            : YakitlaColors.muted;
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF3F4F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      readOnly: widget.readOnly,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'),
                        ),
                      ],
                      onChanged: widget.onChanged,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.unit,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: YakitlaColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
