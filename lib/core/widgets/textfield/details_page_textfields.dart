import 'package:flutter/material.dart';

import '../../../product/constants/strings/edit_item_strings.dart';

class DetailsPageTextFields{


  Widget buildDescriptionField(String label, String? value) {

    return  SizedBox(
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value),
        style: TextStyle(
          backgroundColor: Colors.grey[200],
          fontSize: 20.0,  // Increase the font size if needed
        ),
        maxLines: 7,  // Increase the maxLines property to make the text field taller
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget buildItemNameField(String label, String? value) {
    return SizedBox(
      height: 75, // Adjust the height for the item name field
      child: TextField(
        textAlign: TextAlign.center,
        readOnly: true,
        controller: TextEditingController(text: value),
        style: const TextStyle(
          backgroundColor: Colors.transparent, // Set background color to be barely visible
          fontSize: 18.0,
        ),
        maxLines: 4,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.brown[100], // Set a slightly visible background color
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget buildUsernameField(String label, String? value) {
    return SizedBox(
      height: 50,
      child: TextField(
        textAlign: TextAlign.center,
        readOnly: true,
        controller: TextEditingController(text: '${DetailsItemStrings.dutyText} : $value' ),
        style: TextStyle(
          backgroundColor: Colors.grey[200],
          fontSize: 15.0, // Increase the font size if needed
        ),
        maxLines: 1, // Increase the maxLines property to make the text field taller
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          enabledBorder: OutlineInputBorder(
            borderSide:const  BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}