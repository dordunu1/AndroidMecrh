import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<MerchUser?>((ref) async {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) async {
      if (user == null) return null;
      return ref.read(authServiceProvider).getCurrentUser();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<MerchUser?> getCurrentUser() async {
    try {
      if (currentUser == null) return null;

      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (!doc.exists) return null;

      return MerchUser.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Only update lastLoginAt timestamp
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Create user profile in Firestore with only essential fields
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email.trim(),
        'name': email.split('@')[0], // Default name from email
        'phone': '',
        'photoUrl': '',
        'isAdmin': false,
        'isSeller': false,
        'isBuyer': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'preferences': {},
      });

      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        // Web-specific logout
        await _auth.signOut();
        // For web, just sign out from Firebase is sufficient
      } else {
        // Mobile logout
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
        await _auth.signOut();
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      await currentUser!.updateDisplayName(displayName);
      await currentUser!.updatePhotoURL(photoURL);

      await _firestore.collection('users').doc(currentUser!.uid).update({
        if (displayName != null) 'name': displayName,
        if (photoURL != null) 'photoUrl': photoURL,
      });
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> updateEmail(String newEmail, String password) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Reauthenticate user before updating email
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      await currentUser!.updateEmail(newEmail.trim());
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'email': newEmail.trim(),
      });
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Reauthenticate user before updating password
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      // Reauthenticate user before deleting account
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser!.uid).delete();

      // Delete user account
      await currentUser!.delete();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // Web-specific Google Sign-in
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile Google Sign-in
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) throw Exception('Google Sign-In cancelled');

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      // Check if user exists in Firestore and create/update profile
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        // Create new user profile in Firestore with only essential fields
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName ?? userCredential.user!.email!.split('@')[0],
          'phone': userCredential.user!.phoneNumber ?? '',
          'photoUrl': userCredential.user!.photoURL ?? '',
          'isAdmin': false,
          'isSeller': false,
          'isBuyer': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'preferences': {},
        });
      } else {
        // Update last login timestamp
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'requires-recent-login':
          return 'Please log in again to complete this action.';
        default:
          return e.message ?? 'An unknown error occurred.';
      }
    }
    return e.toString();
  }
} 