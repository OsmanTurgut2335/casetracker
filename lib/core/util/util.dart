import 'package:casetracker/core/util/corpoUtil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../Utility/globals.dart';

class Util{
  final firebaseRef = FirebaseDatabase(
    databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();
  final corpuUtil = CorpoUtil();




  Future<void> fetchDataFromDatabase() async {
    Globals.itemsList[0].clear();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {


      // Update the reference to include the user's UID and fetch tasks from the "tasks" branch
      DatabaseReference userTaskReference = firebaseRef.child('users').child(user.uid).child('tasks');

      final snapshot = await userTaskReference.get();

      if (snapshot.value is Map<dynamic, dynamic>) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        Globals.itemsList[0].clear();
        Globals.taskKeysByName.clear();
        data.forEach((key, value) {
          final item = Item(
            name: value['name'],
            description: value['description'],
            date: DateTime.parse(value['date']),
          );
          Globals.taskKeysByName[item.name] = key;

          Globals.itemsList[0].add(item);
        });


      }
    }
  }

}