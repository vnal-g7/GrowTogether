import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = result.user;
    if (user == null) return null;

    await _dbRef.child('users').child(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'coins': 100,
      'xp': 0,
      'streak': 0,
      'approvedSubmissions': 0,
      'approvedChallenges': 0,
      'isAdmin': false,
      'profilePic': '',
      'createdAt': ServerValue.timestamp,
      'lastApprovedDate': '',
    });

    return user;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();
}
