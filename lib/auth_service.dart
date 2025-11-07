import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      // Optional scopes: provider.addScope('https://www.googleapis.com/auth/contacts.readonly');
      return _auth.signInWithPopup(provider);
    } else {
      // mobile: use google_sign_in if you want native account picker
      final provider = GoogleAuthProvider();
      return _auth.signInWithProvider(provider);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
