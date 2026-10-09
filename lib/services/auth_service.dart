import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import 'db_service.dart';

class Auth {
  static final _auth = FirebaseAuth.instance;
  static bool registering = false;
  static User? get user => _auth.currentUser;

  static Future<void> login(String email, String pass) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: pass);

  static Future<void> register({
    required String role,
    required String name,
    required String email,
    required String phone,
    required String password,
    String vehicleType = '',
    String plate = '',
    String serviceArea = '',
  }) async {
    registering = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await Db.createUser(AppUser(
        uid: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        vehicleType: vehicleType,
        plate: plate.trim(),
        serviceArea: serviceArea.trim(),
      ));
    } finally {
      registering = false;
    }
  }

  static Future<bool> google() async {
    final g = await GoogleSignIn().signIn();
    if (g == null) return false;
    final a = await g.authentication;
    await _auth.signInWithCredential(GoogleAuthProvider.credential(
        accessToken: a.accessToken, idToken: a.idToken));
    return true;
  }

  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  static Future<void> changePassword(String current, String next) async {
    final u = _auth.currentUser;
    if (u == null || u.email == null) {
      throw FirebaseAuthException(
          code: 'no-current-user', message: 'You are not signed in.');
    }
    final cred =
        EmailAuthProvider.credential(email: u.email!, password: current);
    await u.reauthenticateWithCredential(cred);
    await u.updatePassword(next);
  }

  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  static String err(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'That email is already registered. Try logging in.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'network-request-failed':
          return 'No internet connection. Check your network and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'requires-recent-login':
          return 'Please log out and log in again before changing your password.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}
