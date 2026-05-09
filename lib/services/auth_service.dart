import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    forceCodeForRefreshToken: true,
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email & Password Register ───────────────────────────────
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) return null;

      await user.updateDisplayName(username);

      final UserModel newUser = UserModel(
        uid: user.uid,
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );

      // Try to save to Firestore but don't block navigation if it fails
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
        print('✅ User saved to Firestore');
      } catch (firestoreError) {
        print('⚠️ Firestore save failed: $firestoreError');
        // Continue anyway — auth succeeded
      }

      return newUser;

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    } catch (e) {
      print('Register error: $e');
      throw 'Registration failed. Please try again.';
    }
  }

  // ─── Email & Password Login ───────────────────────────────────
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) return null;

      // Try Firestore first, fallback to basic model
      try {
        final firestoreUser = await _getUserFromFirestore(user.uid);
        if (firestoreUser != null) return firestoreUser;
      } catch (e) {
        print('⚠️ Firestore fetch failed: $e');
      }

      // Fallback — return basic user model from Auth
      return UserModel(
        uid: user.uid,
        username: user.displayName ?? 'Player',
        email: user.email ?? '',
        createdAt: DateTime.now(),
      );

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    } catch (e) {
      print('Login error: $e');
      throw 'Login failed. Please try again.';
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────
  Future<UserModel?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
    
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);
      final User? user = result.user;
      if (user == null) return null;

      final UserModel userModel = UserModel(
        uid: user.uid,
        username: user.displayName ?? 'Player',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        createdAt: DateTime.now(),
      );

      // Try to save to Firestore but don't block navigation
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
        }
        print('✅ Google user saved to Firestore');
      } catch (e) {
        print('⚠️ Firestore save failed: $e');
      }

      return userModel;

    } catch (e) {
      print('Google Sign-In error: $e');
      throw 'Google Sign-In failed. Please try again.';
    }
  }

  // ─── Guest Mode ───────────────────────────────────────────────
  Future<UserModel?> signInAsGuest() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      final User? user = result.user;
      if (user == null) return null;

      final UserModel guestUser = UserModel(
        uid: user.uid,
        username: 'Guest_${user.uid.substring(0, 5)}',
        email: '',
        createdAt: DateTime.now(),
      );

      // Try Firestore save but don't block
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(guestUser.toMap());
        print('✅ Guest saved to Firestore');
      } catch (e) {
        print('⚠️ Firestore save failed: $e');
      }

      return guestUser;

    } catch (e) {
      print('Guest error: $e');
      throw 'Guest sign-in failed. Please try again.';
    }
  }

  // ─── Forgot Password ─────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Get User from Firestore ──────────────────────────────────
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  // ─── Handle Auth Errors ───────────────────────────────────────
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
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}