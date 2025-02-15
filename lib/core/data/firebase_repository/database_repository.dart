import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../Utility/globals.dart';
import '../../helpers/firebase_helper.dart';

class DatabaseRepository{

  final firebaseRef = FirebaseHelper.firebaseRef;

  late final FirebaseAuth _auth ;


  Future<bool> isUserKurumsalMember(String userId) async {


    DatabaseReference userTaskReference =
    firebaseRef.child('users').child(userId).child("kurum");

    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value != null;
  }


  Future<String?> fetchUsername() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DatabaseReference userReference = firebaseRef.child('users').child(user.uid);
      DataSnapshot userSnapshot = await userReference.get();

      if (userSnapshot.value != null) {
        Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
        if (userData.containsKey('username') && userData['username'] != null) {
          return userData['username'];
        }
      }
    }
    return null; // No username found
  }

  // Helper method to get 'invitationCode' from Realtime Database
  Future<String> getInvitationCodeFromDatabase(String userId) async {

    // Reference to 'invitationCode' field in Realtime Database
    DatabaseReference userTaskReference = firebaseRef.child('users').child(userId).child('kurum').child('invitationCode');

    // Get the 'invitationCode' value
    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value.toString();
  }

  // Helper method to get 'name' from Realtime Database
  Future<String> getKurumNameFromDatabase(String userId) async {

    // Reference to 'invitationCode' field in Realtime Database
    DatabaseReference userTaskReference = firebaseRef.child('users').child(userId).child('kurum').child('name');

    // Get the 'invitationCode' value
    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value.toString();
  }
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