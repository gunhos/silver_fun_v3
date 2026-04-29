import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum BtnVariant { primary, ghost, dark }

class Btn extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final BtnVariant variant;
  final Widget? leading;
  final bool expanded;

  const Btn({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BtnVariant.primary,
    this.leading,
    this.expanded = true,
  });

  @override
  State<Btn> createState() => _BtnState();
}

class _BtnState extends State<Btn> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final colors = _colorsFor(widget.variant);

    final child = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: disabled ? colors.disabled : colors.bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: colors.border,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 10),
            ],
            Text(
              widget.label,
              style: TextStyle(
                color: colors.fg,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  _BtnColors _colorsFor(BtnVariant v) {
    switch (v) {
      case BtnVariant.primary:
        return const _BtnColors(
          bg: AppColors.accent,
          fg: Colors.white,
          disabled: Color(0xFFE0AAB1),
        );
      case BtnVariant.ghost:
        return _BtnColors(
          bg: Colors.transparent,
          fg: AppColors.ink,
          disabled: Colors.transparent,
          border: Border.all(color: AppColors.line, width: 1.5),
        );
      case BtnVariant.dark:
        return const _BtnColors(
          bg: AppColors.ink,
          fg: Colors.white,
          disabled: Color(0xFF8A85A8),
        );
    }
  }
}

class _BtnColors {
  final Color bg;
  final Color fg;
  final Color disabled;
  final BoxBorder? border;

  const _BtnColors({
    required this.bg,
    required this.fg,
    required this.disabled,
    this.border,
  });
}
