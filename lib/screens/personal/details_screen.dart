import 'dart:core';
import 'package:casetracker/core/widgets/button/remove_item_button.dart';
import 'package:casetracker/core/widgets/details_page_textfields.dart';
import 'package:casetracker/product/constants/strings/edit_item_strings.dart';
import 'package:flutter/material.dart';
import '../../Utility/globals.dart';
import '../../core/widgets/button/edit_item_button.dart';
import '../../product/widgets/sizedbox/custom_sized_box.dart';
import 'edit_item_screen.dart';


class DetailsPage extends StatefulWidget {
  final String title;
  final String item;
  final String description;
  final DateTime itemDate;
  final VoidCallback onRemove;

  const DetailsPage({super.key,
    required this.title,
    required this.item,
    required this.description,
    required this.itemDate,
    required this.onRemove,
  });

  @override
  DetailsPageState createState() => DetailsPageState();
}

class DetailsPageState extends State<DetailsPage> {
  Item _item = Item(name: "", description: "", date: DateTime.now());
  final customTextFields = DetailsPageTextFields();
  @override
  void initState() {
    super.initState();
    _item = Item(name: widget.item, description: widget.description, date: widget.itemDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(DetailsItemStrings.personaldetailPageString),
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
              customTextFields.buildDescriptionField('', _item.description),

                CustomSizedBox().customSizedBox(30),
            Text('${DetailsItemStrings.date}  : ${_formatDate(_item.date)}',
              style: const TextStyle(
                  fontSize: 20
              ),
            ),
                CustomSizedBox().customSizedBox(50),
           // editButton(context),
                EditItemButton(navigateToEditItemScreen:  _navigateToEditItemScreen),
           RemoveItemButton(onRemove: widget.onRemove),

            ],
          ),
        ),
      ),
    )
    );
  }



  void _navigateToEditItemScreen(BuildContext context) async {
    final editedItem = await Navigator.push(
      context,
      MaterialPageRoute<Item>(
        builder: (context) => EditItemScreen(item: _item),
      ),
    ).then((_) {
      Navigator.pop(context); // Remove the current route from the stack
    });

    if (editedItem != null) {
      setState(() {
        _item.name = editedItem.name;
        _item.description = editedItem.description;
        _item.date = editedItem.date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

