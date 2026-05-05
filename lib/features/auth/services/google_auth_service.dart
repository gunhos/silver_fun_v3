import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

typedef CredentialFetcher = Future<AuthCredential?> Function();
typedef GoogleSignOutFn = Future<void> Function();

class GoogleAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final CredentialFetcher? _credentialFetcher;
  final GoogleSignOutFn? _googleSignOut;

  /// [serverClientId] is the Firebase project's Web OAuth client ID. It is
  /// required on Android release builds signed by Play App Signing so that
  /// `google_sign_in` 6.x can return an `idToken` Firebase Auth will accept.
  /// Ignored when [googleSignIn] is injected directly (tests).
  GoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    String? serverClientId,
    @visibleForTesting CredentialFetcher? credentialFetcher,
    @visibleForTesting GoogleSignOutFn? googleSignOut,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(serverClientId: serverClientId),
        _credentialFetcher = credentialFetcher,
        _googleSignOut = googleSignOut;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signIn() async {
    final credential = await _resolveCredential();
    if (credential == null) return null;
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  Future<void> signOut() async {
    if (_googleSignOut != null) {
      await _googleSignOut();
    } else {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  Future<AuthCredential?> _resolveCredential() async {
    if (_credentialFetcher != null) {
      return _credentialFetcher();
    }
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final googleAuth = await account.authentication;
    return GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
  }
}
