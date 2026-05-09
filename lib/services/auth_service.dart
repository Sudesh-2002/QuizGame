import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register with Email ────────────────────────────────────────
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user == null) return null;

      // Use the exact username the user typed in the form
      await user.updateDisplayName(username);

      final UserModel newUser = UserModel(
        uid: user.uid,
        username: username, // exactly what they typed
        email: email,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newUser.toMap());
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // ── Login with Email ───────────────────────────────────────────
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user == null) return null;
      return await _getUserFromFirestore(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);
      final User? user = result.user;
      if (user == null) return null;

      // Extract FIRST NAME only from Google display name
      final fullName = user.displayName ?? 'Player';
      final firstName = fullName.trim().split(' ').first;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        final UserModel newUser = UserModel(
          uid: user.uid,
          username: firstName, // first name from Google
          email: user.email ?? '',
          photoUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
        return newUser;
      }

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      throw 'Google Sign-In failed. Please try again.';
    }
  }

  // ── Guest Sign-In ──────────────────────────────────────────────
  Future<UserModel?> signInAsGuest() async {
    try {
      final UserCredential result =
          await _auth.signInAnonymously();
      final User? user = result.user;
      if (user == null) return null;

      // Guest name = Player_ + last 5 chars of UID
      final guestName =
          'Player_${user.uid.substring(user.uid.length - 5).toUpperCase()}';

      final UserModel guestUser = UserModel(
        uid: user.uid,
        username: guestName,
        email: '',
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(guestUser.toMap());
      return guestUser;
    } catch (e) {
      throw 'Guest sign-in failed. Please try again.';
    }
  }

  // ── Forgot Password ────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Get User from Firestore ────────────────────────────────────
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc =
        await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  // ── Stream User from Firestore (real-time) ─────────────────────
  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) =>
            doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  // ── Error Handler ──────────────────────────────────────────────
  String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}