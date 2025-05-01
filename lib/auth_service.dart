import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '1092509163883-jgrii1pk46ilc6je3qv86mdfcmag09k2.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // User canceled the login

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Store the user's email securely
      await storage.write(key: 'user_email', value: googleUser.email);

      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (e is FirebaseAuthException) {
        debugPrint('Firebase error: ${e.message}');
      }
      return null;
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await storage.delete(key: 'user_email'); // Remove stored email
    } catch (e) {
      debugPrint('Sign-Out error: $e');
    }
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      return user; // User is signed in
    } else {
      return null; // No user is signed in
    }
  }

  /// Check if the user is signed in on app startup
  Future<bool> isUserLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Web-specific sign-in (if needed)
  Future<UserCredential?> signInWithGoogleWeb() async {
    if (kIsWeb) {
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) return null; // User canceled the login

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in with the credential
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        // Store the user's email securely
        await storage.write(key: 'user_email', value: googleUser.email);

        return userCredential;
      } catch (e) {
        debugPrint('Web Google Sign-In error: $e');
        return null;
      }
    }
    return null; // Web-specific flow, for now
  }
}
