import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../Utility/globals.dart';

class CorpoUtil{
  final firebaseRef = FirebaseDatabase(
    databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
  ).reference();
  // Helper method to get 'invitationCode' from Realtime Database
  Future<String> getInvitationCodeFromDatabase(String userId) async {
    DatabaseReference firebaseRef = FirebaseDatabase(
      databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
    ).reference();

    // Reference to 'invitationCode' field in Realtime Database
    DatabaseReference userTaskReference = firebaseRef.child('users').child(userId).child('kurum').child('invitationCode');

    // Get the 'invitationCode' value
    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value.toString();
  }
  Future<bool> isUserKurumsalMember(String userId) async {

    DatabaseReference userTaskReference =
    firebaseRef.child('users').child(userId).child("kurum");

    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value != null;
  }
  // Helper method to get 'name' from Realtime Database
  Future<String> getKurumNameFromDatabase(String userId) async {
    DatabaseReference firebaseRef = FirebaseDatabase(
      databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
    ).reference();

    // Reference to 'invitationCode' field in Realtime Database
    DatabaseReference userTaskReference = firebaseRef.child('users').child(userId).child('kurum').child('name');

    // Get the 'invitationCode' value
    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value.toString();
  }
  void fetchKurumsalItemsFromDatabase() async {

    // Clear the existing kurumsalItemsList
    Globals.kurumsalItemsList[0].clear();

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {

      // Access Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      try {
        // Get the 'invitationCode' from Realtime Database
        String invitationCode = await getInvitationCodeFromDatabase(user.uid);
        String kurumName = await getKurumNameFromDatabase(user.uid);
        String documentName = " $kurumName - $invitationCode ";
        // Find the document in 'kurumlar' collection where 'name' contains the invitation code


        QuerySnapshot querySnapshot = await firestore
            .collection('kurumlar')
            .where(FieldPath.documentId, isEqualTo: documentName)
            .get();

// Check if any document is found
        if (querySnapshot.docs.isNotEmpty) {
          // Access the first document's data
          Map<String, dynamic> data = querySnapshot.docs.first.data() as Map<String, dynamic>;

          // Get the 'tasks' array from the document
          List<dynamic>? tasks = data['tasks'];

          if (tasks != null) {

            for (var taskData in tasks) {
              // Extract data from each task item
              String name = taskData['name'];
              String? description = taskData['description'];
              DateTime date = DateTime.parse(taskData['date']);
            String  username = taskData['username'];

              // Create a KurumsalItem and add it to the kurumsalItemsList


              KurumsalItem kurumsalItem = KurumsalItem(
                name: name,
                description: description,
                date: date,
                username: username,
              );
              print("Kurumsal Item Details : ${kurumsalItem.username} ");

              // Add the KurumsalItem to the kurumsalItemsList at the determined index
              Globals.kurumsalItemsList[0].add(kurumsalItem);
            }

            // Now kurumsalItemsList should contain the items from the 'tasks' array
          }
        } else {
          // Handle the case where the document is not found
          print('Document not found with the specified value.');
        }

      } catch (e) {
        print("Error: $e");
      }
    }
  }
}