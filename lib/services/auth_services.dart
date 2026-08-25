import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
class AuthService {


// Add this function inside AuthService class
  static Future<String> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) {
        return 'Google sign in cancelled';
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      return 'success';
    } catch (e) {
      return 'Google sign in failed: $e';
    }
  }

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        return 'Please verify your email first!';
      }
      return 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password. Please try again.';
      }
      return e.message ?? 'Login failed.';
    }
  }

  static Future<String> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user!.updateDisplayName(name);
      await userCredential.user!.sendEmailVerification();
      // Save to Firestore
      await saveUserToFirestore(
        userID: userCredential.user!.uid,
        name: name,
        email: email,
      );
      await FirebaseAuth.instance.signOut();
      return 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Password must be at least 6 characters.';
      } else if (e.code == 'email-already-in-use') {
        return 'Account already exists with this email.';
      }
      return e.message ?? 'Signup failed.';
    }
  }

  static Future<String> forgotPassword({
    required String email,
  }) async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email.';
    }
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }
  // Save user profile to Firestore after signup
  static Future<void> saveUserToFirestore({
    required String userID,
    required String name,
    required String email,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .set({
      'userID': userID,
      'name': name,
      'email': email,
      'createdAt': Timestamp.now(),
      'totalNotes': 0,
      'totalStudyTime': 0,
    });
  }
}