import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<User?> registerWithProfile({required String name, required String email, required String password}) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    final user = result.user;

    if (user != null) {
      final createdAt = DateTime.now().toUtc().toIso8601String();

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'createdAt': createdAt,
      });
    }

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
