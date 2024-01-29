import 'dart:core';
import 'dart:math';
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
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _personController = TextEditingController();
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
    _personController.text = widget.kurumsalItem.person;
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
        title: Text('Edit Kurumsal Item'),
        backgroundColor: Colors.grey,
        elevation: 4,
        shape: UnderlineInputBorder(),
      ),
      body: CustomPaint(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDueDateSelector(),
              SizedBox(height: 16),
              _buildItemNameField(),
              SizedBox(height: 16),
              _buildPersonField(),
              SizedBox(height: 16),
              _buildDescriptionField(),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final editedItem = KurumsalItem(
                    name: _itemNameController.text,
                    description: _descriptionController.text,
                    date: _selectedDueDate,
                    person: _personController.text,
                  );

                  try {
                    User? user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      final firebaseRef = FirebaseDatabase(
                        databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
                      ).reference();

                      DatabaseReference userTaskReference =
                      firebaseRef.child('users').child(user.uid).child(Globals.taskKeysByName[itemName]!);

                      Map<String, dynamic> newTaskData = {
                        "name": editedItem.name,
                        "description": editedItem.description ?? "",
                        "date": editedItem.date.toUtc().toIso8601String(),
                        "person": editedItem.person,
                      };

                      await userTaskReference.set(newTaskData);

                      for (var itemList in Globals.itemsList) {
                        try {
                          var item = itemList.firstWhere((item) => item.name == itemName);
                          item.name = editedItem.name;
                          await Globals.fetchDataFromDatabase();
                          break;
                        } catch (e) {
                          // Item with the given name not found in the current list
                        }
                      }
                    }
                  } catch (e) {
                    print("Error during database update: $e");
                  }

                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  foregroundColor: Colors.lightGreen[200],
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Row(
      children: [
        Text(
          'Due Date:',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        SizedBox(width: 16),
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
            primary: Colors.grey[400],
          ),
          child: Text(
            '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildItemNameField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _itemNameController,
        decoration: InputDecoration(
          labelText: 'Item Name',
          labelStyle: TextStyle(
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
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _personController,
        decoration: InputDecoration(
          labelText: 'Person',
          labelStyle: TextStyle(
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
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Description',
          labelStyle: TextStyle(
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
}
