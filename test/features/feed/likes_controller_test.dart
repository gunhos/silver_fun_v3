import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/features/auth/providers/auth_provider.dart';
import 'package:silver_fun/features/feed/providers/likes_provider.dart';
import 'package:silver_fun/features/profile/providers/my_profile_provider.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  Future<void> seedPartner({String name = 'Sora', int age = 70}) async {
    await firestore.collection('users').doc('partner').set({
      'name': name,
      'age': age,
      'bio': '',
      'photoUrl': '',
      'interests': <String>[],
      'city': '',
      'published': true,
      'profilePaused': false,
    });
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    final mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'me', email: 'me@example.com'),
    );

    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      authProvider.overrideWith(
        (ref) => Stream<User?>.value(mockAuth.currentUser),
      ),
      // Seed liked-by-me as empty so toggleLike treats this as a new like.
      likedByMeProvider.overrideWith(
        (ref) => Stream<Set<String>>.value(const <String>{}),
      ),
    ]);

    // Resolve authProvider so subsequent .read returns the user.
    await container.read(authProvider.future);
    await container.read(likedByMeProvider.future);
  });

  tearDown(() => container.dispose());

  test('toggleLike on a non-mutual like returns LikeOutcomeKind.liked', () async {
    await seedPartner();

    final controller = container.read(likesControllerProvider);
    final outcome = await controller.toggleLike('partner');

    expect(outcome.kind, LikeOutcomeKind.liked);
    expect(outcome.partnerName, 'Sora');

    // Forward + reverse like docs were written.
    final forward = await firestore
        .collection('likes')
        .doc('me')
        .collection('liked')
        .doc('partner')
        .get();
    expect(forward.exists, isTrue);

    final reverse = await firestore
        .collection('likedBy')
        .doc('partner')
        .collection('from')
        .doc('me')
        .get();
    expect(reverse.exists, isTrue);
  });

  test('toggleLike on a mutual like returns LikeOutcomeKind.connected',
      () async {
    await seedPartner();

    // Pre-write partner→me so the new like becomes mutual.
    await firestore
        .collection('likes')
        .doc('partner')
        .collection('liked')
        .doc('me')
        .set({'likedAt': FieldValue.serverTimestamp()});

    final controller = container.read(likesControllerProvider);
    final outcome = await controller.toggleLike('partner');

    expect(outcome.kind, LikeOutcomeKind.connected);
    expect(outcome.partnerName, 'Sora');
  });

  test('toggleLike on an already-liked target unlikes and returns unliked',
      () async {
    await seedPartner();

    // Pre-seed me→partner so toggleLike takes the unlike branch.
    await firestore
        .collection('likes')
        .doc('me')
        .collection('liked')
        .doc('partner')
        .set({'likedAt': FieldValue.serverTimestamp()});
    await firestore
        .collection('likedBy')
        .doc('partner')
        .collection('from')
        .doc('me')
        .set({'likedAt': FieldValue.serverTimestamp()});

    // Override likedByMeProvider to reflect the pre-seeded like.
    container.dispose();
    final mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'me', email: 'me@example.com'),
    );
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      authProvider.overrideWith(
        (ref) => Stream<User?>.value(mockAuth.currentUser),
      ),
      likedByMeProvider.overrideWith(
        (ref) => Stream<Set<String>>.value(const <String>{'partner'}),
      ),
    ]);
    await container.read(authProvider.future);
    await container.read(likedByMeProvider.future);

    final controller = container.read(likesControllerProvider);
    final outcome = await controller.toggleLike('partner');

    expect(outcome.kind, LikeOutcomeKind.unliked);
    expect(outcome.partnerName, '');

    // Both forward and reverse docs are gone.
    final forward = await firestore
        .collection('likes')
        .doc('me')
        .collection('liked')
        .doc('partner')
        .get();
    expect(forward.exists, isFalse);

    final reverse = await firestore
        .collection('likedBy')
        .doc('partner')
        .collection('from')
        .doc('me')
        .get();
    expect(reverse.exists, isFalse);
  });
}
