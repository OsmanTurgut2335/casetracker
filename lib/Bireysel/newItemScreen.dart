import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';
import '../Utility/globals.dart';



class NewItemScreen extends StatefulWidget {
  final bool showRow;
  final int changeBehavior;
  NewItemScreen({required this.showRow,required this.changeBehavior  });

  @override
  _NewItemScreenState createState() => _NewItemScreenState();


}

class _NewItemScreenState extends State<NewItemScreen> {
  DateTime _selectedDueDate = DateTime.now();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _shareWithOrganization = false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('New Item'),
        backgroundColor: Colors.grey,
        elevation: 4,
        shape: const UnderlineInputBorder(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildItemNameField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildDueDateSelector(),
            const SizedBox(height: 8),
            Column(

              children: [
                // Wrap the Row widget in a Visibility widget
                Visibility(
                  visible: widget.showRow, // Control visibility based on the showRow flag
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _shareWithOrganization,
                        onChanged: (value) {
                          setState(() {
                            _shareWithOrganization = value!;
                          });
                        },
                      ),
                      const Text('Kurumla Paylaş'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_validateAndSave()) {
                      final newItem = Item(
                        name: _itemNameController.text,
                        description: _descriptionController.text,
                        date: _selectedDueDate,
                      );
                      final newKurumsalItem=KurumsalItem(
                      name: _itemNameController.text,
                      description: _descriptionController.text,
                      date: _selectedDueDate,
                        username: '',
                      );

                      // Check the source class and define behavior accordingly
                      if (widget.changeBehavior == 1) {
                        // Behavior for when coming from class A
                        // For example, pop with a different value
                        Navigator.pop(context, Tuple2(newItem, _shareWithOrganization));

                      } else {
                        // Behavior for when coming from other classes
                        // For example, pop normally without sharing with organization
                        Navigator.pop(context, newKurumsalItem);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Save'),
                ),
              ],
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
          child: ListView(
            scrollDirection: Axis.vertical, // Set the scroll direction to vertical
            children: [
              for (final slot in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 30, 45])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = DateTime.now().add(Duration(days: slot));
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400] ?? Colors.grey, // Set button color
                    ),
                    child: Text(
                      '$slot days',
                      style: const TextStyle(
                        color: Colors.black, // Set text color
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Due Date:',
          style: TextStyle(
            color: Colors.black, // Set text color
          ),
        ),
        const SizedBox(height: 16),
        Row(
mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              child: Text(
                '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
                style: const TextStyle(
                  color: Colors.black, // Set text color
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
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _itemNameController,
        maxLength: 50,
        decoration: InputDecoration(
          labelText: 'Item Name',
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

  Widget _buildDescriptionField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _descriptionController,
        maxLength: 200,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Description',
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
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:const  Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
