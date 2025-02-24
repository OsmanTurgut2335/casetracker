import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/globals.dart';
import '../../helpers/firebase_helper.dart';

class FirestoreRepository{

  final FirebaseFirestore _firestore ;

  final FirebaseAuth _auth ;

  final DatabaseReference _firebaseReference =  FirebaseHelper.firebaseRef;

  FirestoreRepository(this._firestore,this._auth);
  

  Future<bool> updateUsername(String newUsername, BuildContext context) async {
    if (newUsername.isEmpty) {
      _showSnackBar(context, 'Lütfen geçerli bir kullanıcı adı girin.');
      return false;
    }

    // Fetch the user list
    CollectionReference usernamesCollection = _firestore.collection('usernames');
    DocumentSnapshot usernamesDoc = await usernamesCollection.doc('usernames').get();
    List<dynamic> userList = List.from(usernamesDoc['userList']);

    // Check if the username already exists
    if (userList.any((user) => user['username'] == newUsername)) {
      _showSnackBar(context, 'Bu kullanıcı adı zaten kullanılıyor.');
      return false;
    }

    // Update Firestore user document
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      'username': newUsername,
    });

    // Update username in the usernames list
    for (var userItem in userList) {
      if (userItem['userid'] == _auth.currentUser?.uid) {
        userItem['username'] = newUsername;
        break;
      }
    }

    // Update Firestore usernames collection
    await usernamesCollection.doc('usernames').update({'userList': userList});

    _showSnackBar(context, 'Kullanıcı adı başarıyla oluşturuldu.');
    return true;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> addMemberToFirestore(String kurumName) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;


    try {
      QuerySnapshot kurumlarSnapshot =
      await firestore.collection('kurumlar').get();

      for (QueryDocumentSnapshot kurumDocument in kurumlarSnapshot.docs) {
        String kurumDocumentName = kurumDocument.id;
        String osman = kurumName;

        if (kurumDocumentName.contains(osman)) {

          DocumentReference kurumReference = kurumDocument.reference;

          DocumentSnapshot kurumSnapshot = await kurumReference.get();
          List<Map<String, dynamic>> currentMembers = [];

          if (kurumSnapshot.exists) {
            Map<String, dynamic>? data =
            kurumSnapshot.data() as Map<String, dynamic>?;

            if (data != null && data.containsKey('members')) {
              List<dynamic>? membersData = data['members'];

              if (membersData != null) {
                currentMembers = List<Map<String, dynamic>>.from(
                    membersData.map((member) =>
                    member as Map<String, dynamic>));
              }
            }
          }

          if (user != null) {
            Map<String, dynamic> currentUser = {
              'name': user.uid,
            };

            currentMembers.add(currentUser);

            await kurumReference.update({
              'members': currentMembers,
            });


            print(
                'User added to the members list of $kurumDocumentName successfully');
          }

          break;
        }
      }
    } catch (e) {
      print('Error adding member to Firestore: $e');
    }
  }
  Future<void> showJoinKurumDialog(BuildContext context) async {
    TextEditingController _invitationCodeController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Join Kurum'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You are not a member of any Kurum. Enter the invitation code to join:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _invitationCodeController,
                decoration: const InputDecoration(
                  labelText: 'Invitation Code',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String invitationCode = _invitationCodeController.text;
                _joinKurum(invitationCode, context);
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinKurum(String invitationCode, BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (user != null) {


      DatabaseReference kurumsReference = _firebaseReference.child('kurums');
      DatabaseReference userTaskReference =
      _firebaseReference.child('users').child(user.uid);

      DataSnapshot kurumsSnapshot = await kurumsReference.get();

      if (kurumsSnapshot.value != null) {
        Map<dynamic, dynamic> kurumsData =
        (kurumsSnapshot.value as Map<dynamic, dynamic>);

        for (var kurumKey in kurumsData.keys) {
          String kurumInvitationCode = kurumKey;

          if (kurumInvitationCode == invitationCode) {
            try {
              await userTaskReference.update({
                'kurum': {
                  'name': kurumsData[kurumKey]['name'],
                  'imageUrl': kurumsData[kurumKey]['imageUrl'],
                  'invitationCode': invitationCode,
                },
              });


              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                      "Successfully joined Kurum: ${kurumsData[kurumKey]['name']}"),
                  duration: const Duration(seconds: 3),
                ),
              );

              await addMemberToFirestore(invitationCode);
              Navigator.pop(context);
              break;
            } catch (error) {
              print("Error updating user Kurum: $error");
            }
          }
        }
      }
    }
  }

  void _removeItem(KurumsalItem item,String documentName) async {

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
}