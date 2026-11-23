
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // The currently signed-in user, if there is one.
  User? get currentUser => _auth.currentUser;

  // Listen for changes when users sign in or sign out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check whether the current account is a guest.
  bool get isGuest => currentUser?.isAnonymous ?? false;

  // Check whether someone is signed in.
  bool get isSignedIn => currentUser != null;

  // Create an account using email and password.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign in with an existing account.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Allow someone to explore TravelMate without registering.
  Future<UserCredential> signInAsGuest() async {
    if (currentUser != null) {
      throw StateError('A user is already signed in.');
    }

    return await _auth.signInAnonymously();
  }

  // Sign out of the current account.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Send a password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // Convert a guest account into a permanent email account.
  // Linking keeps the same Firebase user ID.
  Future<UserCredential> linkGuestAccount({
    required String email,
    required String password,
  }) async {
    final user = currentUser;

    if (user == null || !user.isAnonymous) {
      throw StateError('No guest account is signed in.');
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    return await user.linkWithCredential(credential);
  }
}
