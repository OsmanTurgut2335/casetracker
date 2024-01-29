import 'dart:core';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Utility/globals.dart';
import '../Utility/main.dart';
import 'mainBireysel.dart';

class NewItemScreen extends StatefulWidget {
  @override
  _NewItemScreenState createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  DateTime _selectedDueDate = DateTime.now();
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('New Item'),
        backgroundColor: Colors.grey,
        elevation: 4,
        shape: UnderlineInputBorder(),
      ),
      body: Padding(
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
              onPressed: () {
                if (_validateAndSave()) {
                  final newItem = Item(
                    name: _itemNameController.text,
                    description: _descriptionController.text,
                    date: _selectedDueDate,
                  );
                  Navigator.pop(context, newItem);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      children: [
        SizedBox(
          height: 200, // Set the height of the time slots
          child: Expanded(
            child: ListView(
              scrollDirection: Axis.vertical, // Set the scroll direction to vertical
              children: [
                for (final slot in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 30, 45])
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        // Set the selected days for the due date
                        setState(() {
                          _selectedDueDate = DateTime.now().add(Duration(days: slot));
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey[400] ?? Colors.grey, // Set button color
                      ),
                      child: Text(
                        '$slot days',
                        style: TextStyle(
                          color: Colors.black, // Set text color
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Due Date:',
          style: TextStyle(
            color: Colors.black, // Set text color
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextButton(
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
                  //   backgroundColor: Colors.grey[400] ?? Colors.grey, // Set button color
                ),
                child: Text(
                  '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
                  style: TextStyle(
                    color: Colors.black, // Set text color
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildItemNameField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _itemNameController,
        maxLength: 50,
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

  Widget _buildDescriptionField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _descriptionController,
        maxLength: 200,
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

  bool _validateAndSave() {
    final itemName = _itemNameController.text;
    final description = _descriptionController.text;

    if (itemName.length > 50) {
      _showErrorDialog('Item name cannot exceed 50 characters.');
      return false;
    }

    if (description.length > 200) {
      _showErrorDialog('Description cannot exceed 200 characters.');
      return false;
    }

    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}