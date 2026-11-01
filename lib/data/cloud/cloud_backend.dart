import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Account and storage calls the app needs from the cloud. The Firebase
/// version is below; tests use a fake so nothing needs a Firebase project.
abstract class CloudBackend {
  /// False when Firebase has no config file, so the app stays offline-only.
  bool get available;
  String? get email;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<void> upload(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> download();
}

class FirebaseBackend implements CloudBackend {
  @override
  bool get available => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  String? get email => available ? _auth.currentUser?.email : null;

  DocumentReference<Map<String, dynamic>> get _doc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in first.');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('backup')
        .doc('latest');
  }

  @override
  Future<void> signIn(String email, String password) => _auth
      .signInWithEmailAndPassword(email: email.trim(), password: password);

  @override
  Future<void> register(String email, String password) => _auth
      .createUserWithEmailAndPassword(email: email.trim(), password: password);

  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> upload(Map<String, dynamic> data) => _doc.set(data);

  @override
  Future<Map<String, dynamic>?> download() async =>
      (await _doc.get()).data();
}
