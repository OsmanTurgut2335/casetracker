import 'dart:core';
import 'package:casetracker/core/widgets/textfield/edit_page_textfields.dart';
import 'package:casetracker/product/widgets/custom_bulletlist.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';
import '../../core/helpers/globals.dart';

class NewItemScreen extends StatefulWidget {
  final bool showRow;
  final int changeBehavior;
  NewItemScreen({required this.showRow, required this.changeBehavior});

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
              EditPageTextFields()
                  .buildDescriptionField(_descriptionController),
              const SizedBox(height: 16),
              CustomBulletlist(
                initialDate: _selectedDueDate, // Pass the initial date
                onDateSelected: (newDate) {
                  // Update the parent's state when the date changes
                  setState(() {
                    _selectedDueDate = newDate;
                  });
                },
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  shareCheckBox(),
                  _buildSaveButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Visibility shareCheckBox() {
    return Visibility(
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
            borderSide:
                BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
          ),
          filled: true,
          fillColor: Colors.grey[400],
        ),
      ),
    );
  }

  // Helper method to create the ElevatedButton
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _onSavePressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
      ),
      child: const Text('Kaydet'),
    );
  }

  void _onSavePressed() {
    if (_validateAndSave()) {
      final newItem = Item(
        name: _itemNameController.text,
        description: _descriptionController.text,
        date: _selectedDueDate,
      );
      final newKurumsalItem = KurumsalItem(
        name: _itemNameController.text,
        description: _descriptionController.text,
        date: _selectedDueDate,
        username: '',
      );

      if (widget.changeBehavior == 1) {
        Navigator.pop(context, Tuple2(newItem, _shareWithOrganization));
      } else {
        Navigator.pop(context, newKurumsalItem);
      }
    }
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
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}
