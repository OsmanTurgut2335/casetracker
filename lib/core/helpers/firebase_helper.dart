import 'package:firebase_database/firebase_database.dart';

class FirebaseHelper {
  static final DatabaseReference firebaseRef = FirebaseDatabase(
    databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();



}
