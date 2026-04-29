import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const Duration kToastDuration = Duration(milliseconds: 2200);

final toastProvider = StateProvider<String?>((ref) => null);

Timer? _toastTimer;

void _setMessage(StateController<String?> controller, String message) {
  controller.state = message;
  _toastTimer?.cancel();
  _toastTimer = Timer(kToastDuration, () {
    controller.state = null;
  });
}

void showToast(WidgetRef ref, String message) {
  _setMessage(ref.read(toastProvider.notifier), message);
}

void showToastFromRef(Ref ref, String message) {
  _setMessage(ref.read(toastProvider.notifier), message);
}
