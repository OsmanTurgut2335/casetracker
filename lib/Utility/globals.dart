import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import '../Bireysel/mainBireysel.dart';

class Item {
  late String name;
  late String? description; // Allow null for description
  late DateTime date;

  Item({required this.name, this.description, required this.date});
}
class KurumsalItem {
  late String name;
  late String? description; // Allow null for description
  late DateTime date;
  late String username ;
  KurumsalItem({required this.name, this.description, required this.date,required this.username});
}


class Globals {
  static List<List<Item>> itemsList = [
    [],
    [],
  ];
  static List<List<KurumsalItem>> kurumsalItemsList = [
    [],
    [],
  ];



  static Map<String, String> taskKeysByName = {};
  static Map<String, String> kurumsalTaskKeysByName = {};

  //Kurumların invitaton valuesini tutan map

  static Map<String, String> kurumInvitationMap = {};

  static Map<String, String> userIDandName = {};

  List<String> kurumNameList = [];
  late String username;

 static  List<String> kurumsMembersList= [];

  static Future<void> fetchDataFromDatabase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firebaseRef = FirebaseDatabase(
        databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
      ).reference();

      // Update the reference to include the user's UID
      DatabaseReference userTaskReference =
      firebaseRef.child('users').child(user.uid).child("tasks");

      final snapshot = await userTaskReference.get();

      if (snapshot.value is Map<dynamic, dynamic>) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        itemsList[0].clear(); // Change here
        taskKeysByName.clear();
        data.forEach((key, value) {
          final item = Item(
            name: value['name'],
            description: value['description'],
            date: DateTime.parse(value['date']),
          );
          taskKeysByName[item.name] = key;

          itemsList[0].add(item);
        });
      }
    }
  }
  Future<bool> isUserKurumsalMember(String userId) async {

    final firebaseRef = FirebaseDatabase(
      databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
    ).reference();

    DatabaseReference userTaskReference =
    firebaseRef.child('users').child(userId).child("kurum");

    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value != null;
  }

  Future<void>  fetchKurumsalItemsFromDatabase() async {
    // Clear the existing kurumsalItemsList
    Globals.kurumsalItemsList[0].clear();

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {

      // Access Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      try {
        // Get the 'invitationCode' from Realtime Database
        String invitationCode = await _getInvitationCodeFromDatabase(user.uid);
        String kurumName = await _getKurumNameFromDatabase(user.uid);
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
            Globals.kurumsalTaskKeysByName.clear();
            for (var taskData in tasks) {
              // Extract data from each task item
              String name = taskData['name'];
              String? description = taskData['description'];
              DateTime date = DateTime.parse(taskData['date']);
              username = taskData['username'];

              // Create a KurumsalItem and add it to the kurumsalItemsList
              KurumsalItem kurumsalItem = KurumsalItem(
                name: name,
                description: description,
                date: date,
                username: username,
              );


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
  // Helper method to get 'invitationCode' from Realtime Database
  Future<String> _getInvitationCodeFromDatabase(String userId) async {
    DatabaseReference firebaseRef = FirebaseDatabase(
      databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
    ).reference();

    // Reference to 'invitationCode' field in Realtime Database
    DatabaseReference userTaskReference = firebaseRef.child('users').child(userId).child('kurum').child('invitationCode');

    // Get the 'invitationCode' value
    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value.toString();
  }

// Helper method to get 'name' from Realtime Database
   Future<String> _getKurumNameFromDatabase(String userId) async {
    DatabaseReference firebaseRef = FirebaseDatabase(
      databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
    ).reference();

    // Reference to 'invitationCode' field in Realtime Database
    DatabaseReference userTaskReference = firebaseRef.child('users').child(userId).child('kurum').child('name');

    // Get the 'invitationCode' value
    DataSnapshot snapshot = await userTaskReference.get();

    return snapshot.value.toString();
  }

}

class NumberGenerator {
  Future<List<String>> slowNumbers() async {
    return Future.delayed(const Duration(milliseconds: 1000), () => numbers,);
  }

  List<String> get numbers => List.generate(5, (index) => number);


  String get number => Random().nextInt(99999).toString();
}
