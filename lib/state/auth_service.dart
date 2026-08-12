import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper over Firebase email/password auth. Returns a human-readable
/// error string on failure, or null on success.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authState() => _auth.authStateChanges();
  User? get current => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  String? get email => _auth.currentUser?.email;

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _msg(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'That email is already registered — try signing in.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
