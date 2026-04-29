import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final toastProvider = StateProvider<String?>((ref) => null);

Timer? _toastTimer;

void showToast(WidgetRef ref, String message) {
  ref.read(toastProvider.notifier).state = message;
  _toastTimer?.cancel();
  _toastTimer = Timer(const Duration(milliseconds: 2200), () {
    ref.read(toastProvider.notifier).state = null;
  });
}

void showToastFromRef(Ref ref, String message) {
  ref.read(toastProvider.notifier).state = message;
  _toastTimer?.cancel();
  _toastTimer = Timer(const Duration(milliseconds: 2200), () {
    ref.read(toastProvider.notifier).state = null;
  });
}
