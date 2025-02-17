import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../Utility/globals.dart';
import '../../../core/helpers/firebase_helper.dart';


class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  String? errorMessage;


  final firebaseRef = FirebaseHelper.firebaseRef;
  
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

      firebaseRef.child('users').child(_auth.currentUser!.uid).set({
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

  // where to use this class ?

  Future<void> checkUserFoundingMembership(String documentName,bool isFoundingMember) async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('kurumlar')
        .doc(documentName)
        .get()
        .then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        // Explicitly cast the data object to a Map<String, dynamic>
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        if (data != null && data['members'] is List<dynamic>) {
          var members = data['members'] as List<dynamic>;

          if (members.isNotEmpty) {
            // Access the fields of the first item in the 'members' array
            var firstMember = members[0];
            if (firstMember is Map<String, dynamic>) {
              // Check if 'kurucuÜye' exists in the first member
              var kurucuUyeValue = firstMember['name'];
              if (kurucuUyeValue.toString() == uid ) {
                isFoundingMember = true;
              } else {
                // If 'kurucuÜye' doesn't exist, do something else
                print('No kurucuÜye value found');
              }
            } else {
              // Handle case when firstMember is not a Map<String, dynamic>
              print('Invalid format for first member');
            }
          } else {
            // 'members' array is empty
            print('No members found.');
          }
        }
      } else {
        // Document not found
        print('Document not found');
      }
    }).catchError((error) {
      // Handle errors
      print('Error fetching document: $error');
    });
  }

  void removeItem(KurumsalItem item, String? documentName) async {

    // Perform asynchronous operations first
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {


      // Get the reference to the Firestore collection
      CollectionReference kurumlarCollection = FirebaseFirestore.instance.collection('kurumlar');

      // Get the document reference based on the document name
      DocumentReference documentRef = kurumlarCollection.doc(documentName);

      // Fetch the document snapshot
      DocumentSnapshot documentSnapshot = await documentRef.get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        // Get the tasks array from the document
        List<dynamic>? tasks = (documentSnapshot.data() as Map<String, dynamic>?)?['tasks'];


        if (tasks != null) {
          // Create a copy of the tasks list to iterate over
          List<dynamic> tasksCopy = List.from(tasks);

          // Iterate through the items in the tasks array
          for (var task in tasksCopy) {
            // Check if the task matches the item to be removed
            if (task is Map<String, dynamic> && // Ensure task is a Map<String, dynamic>
                task['date'] == item.date &&
                task['description'] == item.description &&
                task['name'] == item.name &&
                task['username'] == user.displayName) {
              // Remove the matching task from the tasks array
              tasks.remove(task);
            }
          }

          // Update the document in Firestore with the modified tasks array
          await documentRef.update({'tasks': tasks});
        }
      }
    }


  }
  
  
  Future<void> removeItemDetailScreen(KurumsalItem item) async {
    // Perform asynchronous operations first
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String? taskKey = Globals.taskKeysByName[item.name];

      DatabaseReference userTaskReference =
      firebaseRef.child('users').child(user.uid).child("tasks").child(
          taskKey!);

      await userTaskReference.remove();

      DatabaseReference userKurumRef = firebaseRef.child('users').child(user.uid).child("kurum");

      // Use async/await to handle the asynchronous operation
      try {
        DataSnapshot snapshot = await userKurumRef.get();

        if (snapshot.value != null) {
          print("The 'kurum' child exists under users/${user.uid}");

          // Access data using DataSnapshot methods
          dynamic userData = snapshot.value;

          if (userData != null && userData is Map<dynamic, dynamic>) {
            String? name = userData['name'];
            String? invitationCode = userData['invitationCode'];

            if (name != null && invitationCode != null) {
              String kurumName = " $name - $invitationCode ";

              final FirebaseFirestore firestore = FirebaseFirestore.instance;

              final DocumentReference documentRef = firestore.collection('kurumlar').doc(kurumName);
              DocumentSnapshot documentSnapshot = await documentRef.get();

              if (documentSnapshot.exists) {
                List<dynamic>? tasks = documentSnapshot['tasks'];
                if (tasks != null) {
                  List<dynamic> tasksCopy = List.from(tasks); // Create a copy of the list
                  for (var task in tasksCopy) {
                    if (task['username'] == item.username &&
                        task['description'] == item.description &&
                        task['name'] == item.name) {
                      tasks.remove(task); // Modify the original list
                    }
                  }

                  await documentRef.update({'tasks': tasks});
                }

                print("Document exists under 'kurumlar/$kurumName'");
                // Proceed with further operations here
                // Update UI state, etc.
              } else {
                print("Document does not exist under 'kurumlar/$kurumName'");
              }
            } else {
              print("Invalid data format for 'name' or 'invitationCode'");
            }
          } else {
            print("Invalid data format for 'userData'");
          }
        } else {
          print("The 'kurum' child does not exist under users/${user.uid}");
        }
      } catch (error) {
        print("Error: $error");
      }

    }
  }
  
  /*

  Future<void> _shareInvitationCode(String documentName) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firebaseRef = FirebaseHelper.firebaseRef;

      // Update the reference to include the user's UID
      DatabaseReference kurumsalReference = firebaseRef.child("users").child(user.uid).child("kurum");

      // Read the invitation code from the database
      DataSnapshot dataSnapshot = await kurumsalReference.get();
      Map<dynamic, dynamic>? values = dataSnapshot.value as Map<dynamic, dynamic>?;

      if (values != null && values.containsKey("invitationCode")) {
        String invitationCode = values["invitationCode"] as String;
        // Find the index of the '-' character
        int dashIndex = documentName.indexOf('-');

        // Extract the text before the '-' character
        String textBeforeDash = documentName.substring(0, dashIndex).trim();

        // Use share_plus to share the invitation code
        Share.share("$textBeforeDash kurumumuza bu davet koduyla katılabilirsin: $invitationCode");
      }
    }
  }*/

  Future<bool> checkIfKurucuMemberExists() async {
    try {
      // Reference to the 'kurumlar' collection
      CollectionReference kurumlarCollection = FirebaseFirestore.instance
          .collection('kurumlar');

      // Document ID of the specific document you want to check
      String documentId = 'your_document_id_here';

      // Query to check if any member has 'kurucuÜye' equal to 'evet'
      QuerySnapshot querySnapshot = await kurumlarCollection
          .doc(documentId)
          .collection('members')
          .where('kurucuÜye', isEqualTo: 'evet')
          .get();

      // Return true if at least one member is a kurucuÜye with the value "evet"
      return querySnapshot.docs.isNotEmpty;
    } catch (error) {
      print('Error: $error');
      // Return false in case of an error
      return false;
    }
  }
}
