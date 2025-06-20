import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/core/providers/firebase_provider.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);
  return AuthController(firebaseAuth);
});

class AuthController {
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  final FirebaseAuth _firebaseAuth;
  AuthController(this._firebaseAuth);

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> register({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
}
