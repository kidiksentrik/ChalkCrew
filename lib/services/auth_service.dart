import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp({ required String email, required String password, }) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code; // 'weak-password', 'email-already-in-use' 등
    }
  }

  Future<String?> signIn({ required String email, required String password, }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code; // 'user-not-found', 'wrong-password' 등
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}
