import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Sign up
  Future<User?> signup(String email, String password) async {
    try {
      final authCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (authCredential.user != null) {
        log('user created successfully');
        return authCredential.user!;
      }
    } on FirebaseAuthException catch (e) {
      print(e.message!);
      rethrow;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
    return null;
  }

  // Login
  Future<User?> login(String email, String password) async {
    try {
      final authCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (authCredential.user != null) {
        log("user logged in successfully");
        return authCredential.user!;
      }
    } on FirebaseAuthException catch (e) {
      log(e.message!);
      rethrow;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      log("user logged out successfully");
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}