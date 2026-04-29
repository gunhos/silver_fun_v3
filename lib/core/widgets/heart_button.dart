import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HeartButton extends StatefulWidget {
  final bool liked;
  final VoidCallback? onTap;
  final double size;

  const HeartButton({
    super.key,
    required this.liked,
    required this.onTap,
    this.size = 36,
  });

  @override
  State<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.liked ? Icons.favorite : Icons.favorite_border,
            color: widget.liked ? AppColors.accent : AppColors.muted,
            size: widget.size * 0.55,
          ),
        ),
      ),
    );
  }
}
