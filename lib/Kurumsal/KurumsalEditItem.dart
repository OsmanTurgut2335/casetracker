import 'dart:core';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../Utility/globals.dart';
import '../Utility/main.dart';


class EditKurumsalItemScreen extends StatefulWidget {
  final KurumsalItem kurumsalItem;

  EditKurumsalItemScreen({required this.kurumsalItem});

  @override
  _EditKurumsalItemScreenState createState() => _EditKurumsalItemScreenState();
}

class _EditKurumsalItemScreenState extends State<EditKurumsalItemScreen> with RouteAware {
  DateTime _selectedDueDate = DateTime.now();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  late String itemName;
  late String keyValue;
  late String targetValue;
  late String foundKey;
  late String? taskKey;

  String findKeyByValue(Map<String, String> map, String targetValue) {
    for (var entry in map.entries) {
      if (entry.value == targetValue) {
        return entry.key;
      }
    }
    return ""; // Return an empty string (or null) if the value is not found
  }

  @override
  void initState() {
    super.initState();
    _selectedDueDate = widget.kurumsalItem.date;
    _itemNameController.text = widget.kurumsalItem.name;
    _personController.text = widget.kurumsalItem.username;
    itemName = widget.kurumsalItem.name;
    targetValue = itemName;
    _descriptionController.text = widget.kurumsalItem.description ?? "";
    foundKey = findKeyByValue(Globals.taskKeysByName, targetValue);
    taskKey = Globals.taskKeysByName[_itemNameController.text];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevi Düzenle'),
        backgroundColor: Colors.grey,
        elevation: 4,
        shape: const UnderlineInputBorder(),
      ),
      body: CustomPaint(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDueDateSelector(),
                const SizedBox(height: 16),
                _buildItemNameField(),
                const SizedBox(height: 16),
                _buildPersonField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const  SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final editedItem = KurumsalItem(
                      name: _itemNameController.text,
                      description: _descriptionController.text,
                      date: _selectedDueDate,
                      username: _personController.text,
                    );
            
                    try {
                      // Get the current authenticated user
                      User? user = FirebaseAuth.instance.currentUser;
            
                      if (user != null) {
                        final firebaseRef = FirebaseDatabase(
                          databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
                        ).reference();
            
                        // Update Realtime Database
                        DatabaseReference userTaskReference = firebaseRef
                            .child('users')
                            .child(user.uid)
                            .child("tasks")
                            .child(Globals.taskKeysByName[itemName]!);
            
                        // Create a map for the new task
                        Map<String, dynamic> newTaskData = {
                          "name": editedItem.name,
                          "description": editedItem.description ?? "",
                          "date": editedItem.date.toUtc().toIso8601String(),
                        };
            
                        await userTaskReference.set(newTaskData);
            
                        // Update Cloud Firestore
                        final firestore = FirebaseFirestore.instance;
                        String invitationCode = await _getInvitationCodeFromDatabase(user.uid);
                        String kurumName = await _getKurumNameFromDatabase(user.uid);
                        String documentName = " $kurumName - $invitationCode ";
            
                        QuerySnapshot querySnapshot = await firestore
                            .collection('kurumlar')
                            .where(FieldPath.documentId, isEqualTo: documentName)
                            .get();
            
                        for (QueryDocumentSnapshot document in querySnapshot.docs) {
                          List tasksArray = document['tasks'];
            
                          for (int i = 0; i < tasksArray.length; i++) {
                            if (tasksArray[i]['name'] == itemName) {
                              // Update the name, description, and date in the tasks array
                              tasksArray[i]['name'] = editedItem.name;
                              tasksArray[i]['description'] = editedItem.description ?? "";
                              tasksArray[i]['date'] = editedItem.date.toUtc().toIso8601String();
            
                              // Update the Firestore document with the modified tasks array
                              await firestore.collection('kurumlar').doc(document.id).update({
                                'tasks': tasksArray,
                              });
            
                              break; // Break the loop once the item is found and updated
                            }
                          }
                        }
            
                        // *************************
                        for (var itemList in Globals.itemsList) {
                          try {
                            // Find the item with the current name
                            var item = itemList.firstWhere((item) => item.name == itemName);
            
                            // Update the name of the found item
                            item.name = editedItem.name;
                            Globals globals = Globals();
            
                            // Call the method fetchKurumsalItemsFromDatabase()
                            await globals.fetchKurumsalItemsFromDatabase();
            
            
                            // If you want to update the name in the database, you'll need to implement that logic here
            
                            break; // Break the loop once the item is found and updated
                          } catch (e) {
                            // Item with the given name not found in the current list
                          }
                        }
                      }
                    } catch (e) {
                      print("Error during database update: $e");
                      // Handle error if needed
                    }
            
                    Navigator.pop(context);
                    Navigator.pop(context);

                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    foregroundColor: Colors.lightGreen[200],
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child:const Text('Değişiklikleri Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Row(
      children: [
        const  Text(
          'Bitiş Tarihi:',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (pickedDate != null && pickedDate != _selectedDueDate) {
              setState(() {
                _selectedDueDate = pickedDate;
              });
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[400],
          ),
          child: Text(
            '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
            style:const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildItemNameField() {
    return Container(
      margin:const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _itemNameController,
        decoration: InputDecoration(
          labelText: 'İsim',
          labelStyle:const TextStyle(
            color: Colors.black,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
          ),
          filled: true,
          fillColor: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildPersonField() {
    return Container(
      margin:const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _personController,
        decoration: InputDecoration(
          labelText: 'Sorumlu Kişi',
          labelStyle:const TextStyle(
            color: Colors.black,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
          ),
          filled: true,
          fillColor: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Açıklama',
          labelStyle: const TextStyle(
            color: Colors.black,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
          ),
          filled: true,
          fillColor: Colors.grey[400],
        ),
      ),
    );
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
