import 'package:casetracker/core/provider/task_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


import '../../product/authentication/viewmodel/auth_viewmodel.dart';
import '../data/firebase_repository/firestore_repository.dart';

//HEYYYYYYYYYY BURDA AYNI ŞEYLERİ KULLANANLARI BESLE



final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  return AuthViewModel();
});

final taskViewModelProvider = ChangeNotifierProvider<TaskViewmodel>((ref) {
  return TaskViewmodel();
});


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
