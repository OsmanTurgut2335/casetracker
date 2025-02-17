import 'package:flutter/material.dart';
import '../../../product/constants/strings/edit_item_strings.dart';


class EditItemButton extends StatelessWidget {
  const EditItemButton({super.key, required this.navigateToEditItemScreen});
  final void Function(BuildContext) navigateToEditItemScreen;
  @override
  Widget build(BuildContext context) {


    return ElevatedButton(
      onPressed: () {
       navigateToEditItemScreen;
      },
      style: ElevatedButton.styleFrom(
        elevation: 5,
        foregroundColor: Colors.limeAccent,
        backgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: const Text(DetailsItemStrings.edit),
    );
  }



}
