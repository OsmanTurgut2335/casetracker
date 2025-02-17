
import 'dart:core';
import 'package:casetracker/core/helpers/firebase_helper.dart';
import 'package:casetracker/core/widgets/button/edit_item_button.dart';
import 'package:casetracker/core/widgets/button/remove_item_button.dart';
import 'package:casetracker/product/constants/strings/edit_item_strings.dart';
import 'package:casetracker/product/widgets/sizedbox/custom_sized_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Utility/globals.dart';

import '../../core/widgets/custom_painter.dart';
import '../../core/widgets/details_page_textfields.dart';
import 'institutional_item_edit.dart';



class KurumsalDetailsPage extends ConsumerStatefulWidget {
  final String title;
  final String item;
  final String description;
  final DateTime itemDate;
  final VoidCallback onRemove;
  final String username;
  final String documentName;

  const KurumsalDetailsPage({super.key,
    required this.title,
    required this.item,
    required this.description,
    required this.itemDate,
    required this.onRemove,
    required this.username,
    required this.documentName,
  });

  @override
  KurumsalDetailsPageState createState() => KurumsalDetailsPageState();
}

class KurumsalDetailsPageState extends ConsumerState<KurumsalDetailsPage> {
  KurumsalItem _item = KurumsalItem(name: "", description: "", date: DateTime.now(), username: "");
  final customTextFields = DetailsPageTextFields();
  final firebaseRef =FirebaseHelper.firebaseRef;

  @override
  void initState() {
    super.initState();
    _item = KurumsalItem(name: widget.item, description: widget.description, date: widget.itemDate, username: widget.username);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(DetailsItemStrings.detailPageString),
        backgroundColor: Colors.grey,
        elevation: 4,
        shape: const UnderlineInputBorder(),
      ),
      body: CustomPaint(
        painter: MyCustomPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // Wrap your Column with SingleChildScrollView
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomSizedBox().customSizedBox(150),
                customTextFields.buildItemNameField('', _item.name),

                CustomSizedBox().customSizedBox(30),
                customTextFields.buildUsernameField('${DetailsItemStrings.dutyText} :', _item.username),

                CustomSizedBox().customSizedBox(30),
              customTextFields.buildDescriptionField('', _item.description),
                const SizedBox(height: 30),
                Text(
                  '${DetailsItemStrings.date} : ${_formatDate(_item.date)}',
                  style: const TextStyle(
                      fontSize: 20
                  ),
                ),
                CustomSizedBox().customSizedBox(50),
               EditItemButton(navigateToEditItemScreen:  _navigateToEditItemScreen),
               RemoveItemButton(onRemove:widget.onRemove),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _navigateToEditItemScreen(BuildContext context) async {

    final editedItem = await Navigator.push(
      context,
      MaterialPageRoute<KurumsalItem>(
        builder: (context) => EditKurumsalItemScreen(kurumsalItem: _item),
      ),
    );
    if (editedItem != null) {
      setState(() {
        _item.name = editedItem.name;
        _item.description = editedItem.description;
        _item.date = editedItem.date;
        _item.username = editedItem.username;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

}








