import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/core/providers/toast_provider.dart';
import 'package:silver_fun/core/widgets/toast_overlay.dart';

Widget _harness({String? initialMessage}) {
  return ProviderScope(
    overrides: [
      toastProvider.overrideWith((ref) => initialMessage),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Stack(children: [ToastOverlay()]),
      ),
    ),
  );
}

void main() {
  testWidgets('ToastOverlay renders message text', (tester) async {
    await tester.pumpWidget(_harness(initialMessage: 'Liked Maya'));
    await tester.pumpAndSettle();

    expect(find.text('Liked Maya'), findsOneWidget);
    final opacity =
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(opacity.opacity, 1.0);
  });

  testWidgets('ToastOverlay is hidden when toastProvider is null',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final opacity =
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(opacity.opacity, 0.0);
  });

  testWidgets('ToastOverlay updates when toastProvider state changes',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(children: [ToastOverlay()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0.0,
    );

    container.read(toastProvider.notifier).state = "It's a match!";
    await tester.pumpAndSettle();

    expect(find.text("It's a match!"), findsOneWidget);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1.0,
    );
  });
}
