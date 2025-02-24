import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/helpers/firebase_helper.dart';
import '../../core/helpers/globals.dart';
import '../../core/provider/providers.dart';
import '../../core/widgets/textfield/edit_page_textfields.dart';




class EditItemScreen extends ConsumerStatefulWidget {
  final Item item;


  const EditItemScreen({required this.item});

  @override
  EditItemScreenState createState() => EditItemScreenState();
}

class EditItemScreenState extends ConsumerState<EditItemScreen>  with RouteAware {
  DateTime _selectedDueDate = DateTime.now();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();


  late String itemName ;
  late String keyValue;
  late String targetValue ;
  late String foundKey ;
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
    _selectedDueDate = widget.item.date;
    _itemNameController.text = widget.item.name;
    itemName = widget.item.name;



    targetValue = itemName;
    _descriptionController.text = widget.item.description ?? "";
    foundKey = findKeyByValue(Globals.taskKeysByName, targetValue);
    taskKey = Globals.taskKeysByName[_itemNameController.text];
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.read(authViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
        backgroundColor: Colors.grey, // Set app bar background color
        elevation: 4, // Set the elevation for a shadow effect
        shape: const UnderlineInputBorder(

        ),
      ),
      body: CustomPaint(
      //  painter: MyCustomPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDueDateSelector(),
              const SizedBox(height: 16),
              EditPageTextFields().buildItemNameField(_itemNameController),
              const SizedBox(height: 16),
              EditPageTextFields().buildDescriptionField(_descriptionController),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final editedItem = Item(
                    name: _itemNameController.text,
                    description: _descriptionController.text,
                    date: _selectedDueDate,

                  );

                  try {
                    // Get the current authenticated user
                    User? user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      final firebaseRef = FirebaseHelper.firebaseRef;

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
                      String invitationCode = await authViewModel.getInvitationCodeFromDatabase(user.uid);
                      String kurumName = await authViewModel.getKurumNameFromDatabase(user.uid);
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
                          await Globals.fetchDataFromDatabase();
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



                },
                  style: ElevatedButton.styleFrom(
                    elevation: 5, // Shadow depth
                    foregroundColor: Colors.lightGreen[200] ,
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0), // Button border radius
                    ),
                  ),
                  child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildDueDateSelector(){
    EditPageTextFields().buildDueDateSelector(_selectedDueDate, context);
    setState(() {

    });
  }


}



