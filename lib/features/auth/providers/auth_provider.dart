import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/google_auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService(auth: ref.watch(firebaseAuthProvider));
});

final authProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(googleAuthServiceProvider);
  return service.authStateChanges();
});
