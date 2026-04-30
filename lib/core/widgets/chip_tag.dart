import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum ChipSize { sm, md }

class ChipTag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final ChipSize size;

  const ChipTag({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.size = ChipSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final isSm = size == ChipSize.sm;
    final pad = isSm
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    final fontSize = isSm ? 14.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: pad,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.chipBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
