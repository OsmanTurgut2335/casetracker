import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


import '../../product/authentication/viewmodel/auth_viewmodel.dart';
import '../data/firebase_repository/firestore_repository.dart';

final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  return AuthViewModel();
});
//HEYYYYYYYYYY BURDA AYNI ŞEYLERİ KULLANANLARI BESLE

// Firebase Providers
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseDatabaseProvider = Provider<DatabaseReference>((ref) {
  return FirebaseDatabase.instance.ref();
});


// Repository Providers
/*
final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return DatabaseRepository(ref.read(firebaseAuthProvider));
});
*/

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository(ref.read(firebaseFirestoreProvider),ref.read(firebaseAuthProvider));
});
