import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  String? errorMessage;

  final DatabaseReference _databaseReference =
  FirebaseDatabase(
    databaseURL:
    "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> login(String email, String password, BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      errorMessage = "Giriş başarısız: ${e.toString()}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<bool> resetPassword(String email) async {
    isLoading = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      isLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false; // Failure
    }
  }

  Future<String?> createUser(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _auth.currentUser!.sendEmailVerification();

      await _firestore.collection('usernames').doc('usernames').update({
        'userList': FieldValue.arrayUnion([
          {'userid': _auth.currentUser!.uid, 'username': ''}
        ])
      });

      _databaseReference.child('users').child(_auth.currentUser!.uid).set({
        'email': _auth.currentUser!.email,
      });

      isLoading = false;
      notifyListeners();
      return null; // Success, no error message
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return e.toString(); // Return error message
    }
  }




}
