import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
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
  User? user = FirebaseAuth.instance.currentUser;
  bool _isUserKurumsalMember = false;
  final Globals _globals = Globals();

  Future<void> _checkKurumsalMembership() async {
    bool isMember = await _globals.isUserKurumsalMember(user!.uid);
    setState(() {
      _isUserKurumsalMember = isMember;
    });
  }
  @override
  void initState() {
    super.initState();
    _checkKurumsalMembership();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Yeni Görev Ekranı'),
        backgroundColor: Colors.grey,
        elevation: 4,
        shape: const UnderlineInputBorder(),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                  Visibility(
                    visible: widget.showRow, // Control visibility based on the showRow flag
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _shareWithOrganization,
                          onChanged: !_isUserKurumsalMember
                              ? null
                              : (value) {
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
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      children: [
        SizedBox(
          height: 175, // Set the height of the time slots
          child: ListView(
            scrollDirection: Axis.vertical, // Set the scroll direction to vertical
            children: [
              for (final slot in [1, 3, 5, 7, 10, 14, 15, 30, 45])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {

                        _selectedDueDate = DateTime.now().add(Duration(days: slot));
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      maximumSize: const Size.fromHeight(40),
                    //  padding: const EdgeInsets.symmetric(horizontal: 1 ,vertical: 1), // Adjust button padding
                      backgroundColor: Colors.grey[400] ?? Colors.grey, // Set button color
                    ),
                    child: Text(
                      '$slot gün',
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

        const SizedBox(height: 5),
        const Text(
          'Bitiş Tarihi:',
          style: TextStyle(
            color: Colors.black, // Set text color
          ),
        ),

        const SizedBox(height: 5),
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
        const Text(
          'Tarihe basarak takvim üzerinden tarih seçimi yapabilirsiniz',
          style: TextStyle(
              color: Colors.black,
              fontSize: 10
          ),
        ),
      ],
    );
  }

  Widget _buildItemNameField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _itemNameController,
        autofillHints: const [AutofillHints.nickname],
        maxLength: 50,
        decoration: InputDecoration(
          labelText: 'Görev Adı',
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

  bool _validateAndSave() {
    final itemName = _itemNameController.text;
    final description = _descriptionController.text;

    if (itemName.length > 50) {
      _showErrorDialog('Görev adı 50 karakteri geçemez.');
      return false;
    }

    if (description.length > 200) {
      _showErrorDialog('Açıklama 200 karakteri geçemez.');
      return false;
    }

    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:const  Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}
