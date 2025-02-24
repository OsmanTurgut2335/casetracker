import 'package:flutter/material.dart';

class EditPageTextFields{


  Widget buildItemNameField( TextEditingController itemNameController) {
    return Container(
      margin:const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: itemNameController,
        decoration: InputDecoration(
          labelText: 'İsim',
          labelStyle:const TextStyle(
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

  Widget buildDescriptionField(TextEditingController descriptionController) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: descriptionController,
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
  Widget buildDueDateSelector(DateTime _selectedDueDate,BuildContext context) {
    return Row(
      children: [
        const  Text(
          'Bitiş Tarihi:',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (pickedDate != null && pickedDate != _selectedDueDate) {

                _selectedDueDate = pickedDate;

            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[400],
          ),
          child: Text(
            '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
            style:const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

}