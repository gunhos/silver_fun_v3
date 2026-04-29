import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/auth/services/google_auth_service.dart';

void main() {
  group('GoogleAuthService', () {
    test('signIn returns null when credential is null (user cancels)',
        () async {
      final auth = MockFirebaseAuth();
      final service = GoogleAuthService(
        auth: auth,
        credentialFetcher: () async => null,
      );

      final user = await service.signIn();

      expect(user, isNull);
      expect(auth.currentUser, isNull);
    });

    test('signIn signs in to FirebaseAuth when credential is provided',
        () async {
      final mockUser = MockUser(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'Maya',
      );
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final credential = GoogleAuthProvider.credential(
        idToken: 'id-token',
        accessToken: 'access-token',
      );
      final service = GoogleAuthService(
        auth: auth,
        credentialFetcher: () async => credential,
      );

      final user = await service.signIn();

      expect(user, isNotNull);
      expect(user!.uid, 'u1');
      expect(auth.currentUser, isNotNull);
    });

    test('signOut clears the current user', () async {
      final mockUser = MockUser(uid: 'u1');
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );
      var googleSignedOut = false;
      final service = GoogleAuthService(
        auth: auth,
        credentialFetcher: () async => null,
        googleSignOut: () async {
          googleSignedOut = true;
        },
      );

      expect(auth.currentUser, isNotNull);

      await service.signOut();

      expect(auth.currentUser, isNull);
      expect(googleSignedOut, isTrue);
    });

    test('authStateChanges streams sign-in and sign-out', () async {
      final mockUser = MockUser(uid: 'u1');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final service = GoogleAuthService(
        auth: auth,
        credentialFetcher: () async => GoogleAuthProvider.credential(
          idToken: 'id',
          accessToken: 'access',
        ),
        googleSignOut: () async {},
      );

      final emitted = <User?>[];
      final sub = service.authStateChanges().listen(emitted.add);
      await Future<void>.delayed(Duration.zero);

      await service.signIn();
      await Future<void>.delayed(Duration.zero);

      await service.signOut();
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(emitted.first, isNull);
      expect(emitted.any((u) => u?.uid == 'u1'), isTrue);
      expect(emitted.last, isNull);
    });
  });
}
