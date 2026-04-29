import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StepBar extends StatelessWidget {
  final int step;
  final int total;

  const StepBar({
    super.key,
    required this.step,
    this.total = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.accent : AppColors.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
