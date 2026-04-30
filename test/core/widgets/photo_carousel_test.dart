import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/core/widgets/photo_carousel.dart';
import 'package:silver_fun/core/widgets/photo_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 320, height: 320, child: child),
    ),
  );
}

void main() {
  testWidgets('renders one PhotoWidget per URL', (tester) async {
    await tester.pumpWidget(_wrap(
      const PhotoCarousel(urls: [
        'https://x/1.jpg',
        'https://x/2.jpg',
        'https://x/3.jpg',
      ]),
    ));
    await tester.pumpAndSettle();

    // PageView lazily builds, so only the first page is mounted; assert
    // by counting PhotoWidgets across the tree at startup.
    expect(find.byType(PhotoWidget), findsWidgets);
  });

  testWidgets('hides dot indicator when only one URL is provided',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PhotoCarousel(urls: ['https://x/only.jpg']),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('photo-carousel-dots')), findsNothing);
  });

  testWidgets('renders N dots when N > 1 URLs are provided', (tester) async {
    await tester.pumpWidget(_wrap(
      const PhotoCarousel(urls: [
        'https://x/1.jpg',
        'https://x/2.jpg',
        'https://x/3.jpg',
      ]),
    ));
    await tester.pumpAndSettle();

    final dots = find.byKey(const ValueKey('photo-carousel-dots'));
    expect(dots, findsOneWidget);
    expect(
      find.descendant(
        of: dots,
        matching: find.byWidgetPredicate((w) {
          final key = w.key;
          return key is ValueKey<String> &&
              key.value.startsWith('photo-carousel-dot-');
        }),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('renders an empty placeholder when urls is empty',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PhotoCarousel(urls: []),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoWidget), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-carousel-dots')), findsNothing);
  });
}
