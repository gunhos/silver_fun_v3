import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'photo_widget.dart';

/// A horizontally swipeable carousel of profile photos with a small dot
/// indicator below. Falls back to a single placeholder when [urls] is empty
/// and hides the indicator when [urls] has 0 or 1 items.
class PhotoCarousel extends StatefulWidget {
  final List<String> urls;
  final BoxFit fit;

  const PhotoCarousel({
    super.key,
    required this.urls,
    this.fit = BoxFit.cover,
  });

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return PhotoWidget(url: null, fit: widget.fit);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) =>
              PhotoWidget(url: widget.urls[i], fit: widget.fit),
        ),
        if (widget.urls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: _Dots(
              key: const ValueKey('photo-carousel-dots'),
              count: widget.urls.length,
              activeIndex: _index,
            ),
          ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _Dots({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          Container(
            key: ValueKey('photo-carousel-dot-$i'),
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == activeIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              border: Border.all(
                color: AppColors.ink.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}
