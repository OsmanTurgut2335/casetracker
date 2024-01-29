import 'dart:core';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../Utility/globals.dart';
import '../Utility/main.dart';
import 'mainBireysel.dart';


class EditItemScreen extends StatefulWidget {
  final Item item;


  EditItemScreen({required this.item});

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen>  with RouteAware {
  DateTime _selectedDueDate = DateTime.now();
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Item'),
        backgroundColor: Colors.grey, // Set app bar background color
        elevation: 4, // Set the elevation for a shadow effect
        shape: UnderlineInputBorder(

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
              SizedBox(height: 16),
              _buildItemNameField(),
              SizedBox(height: 16),
              _buildDescriptionField(),
              SizedBox(height: 16),
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
                      final firebaseRef = FirebaseDatabase(
                        databaseURL: "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
                      ).reference();

                      print("OLD ITEM NAME I GUESS $itemName");

                      DatabaseReference userTaskReference =
                      firebaseRef.child('users').child(user.uid).child(Globals.taskKeysByName[itemName]!);

                      // Create a map for the new task
                      Map<String, dynamic> newTaskData = {
                        "name": editedItem.name,
                        "description": editedItem.description ?? "",
                        "date": editedItem.date.toUtc().toIso8601String(),
                      };

                      await userTaskReference.set(newTaskData);


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

                  // Pop back to the first screen
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                  style: ElevatedButton.styleFrom(
                    elevation: 5, // Shadow depth
                    foregroundColor: Colors.lightGreen[200] ,
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0), // Button border radius
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
            color: Colors.black, // Set text color
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
                _selectedDueDate = pickedDate; // Update the selected due date
              });
            }
          },
          style: TextButton.styleFrom(
            primary: Colors.grey[400] , // Set button text color
          ),
          child: Text(
            '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
            style: TextStyle(
              color: Colors.grey // Set date text color
            ),
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
            color: Colors.black, // Set label text color
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green), // Set border color when focused
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green), // Set border color when not focused
          ),
          filled: true,
          fillColor: Colors.grey[400], // Set background color
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
            color: Colors.black, // Set label text color
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green), // Set border color when focused
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green), // Set border color when not focused
          ),
          filled: true,
          fillColor: Colors.grey[400], // Set background color
        ),
      ),
    );
  }




}
class MyCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw your custom background here
    final Paint paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;

    // Adjust the radius to make the quarter circle larger
    final double radius = size.width / 1.5;

    // Draw a quarter of a circle with the center at the left-top corner
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, 0), radius: radius),
      pi / 2, // Rotate by 90 degrees
      -pi / 2, // Sweep angle (negative for the top-left quarter)
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
