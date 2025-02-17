import 'package:flutter/material.dart';

import '../../../product/constants/strings/edit_item_strings.dart';

class RemoveItemButton extends StatelessWidget {
  const RemoveItemButton({
    super.key,
    required this.onRemove,
  });

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(DetailsItemStrings.remove),
              content: const Text(DetailsItemStrings.removeApprovalString),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(DetailsItemStrings.cancel),
                ),
                TextButton(
                  onPressed: () {
                   onRemove();
                    Navigator.pop(context);
                    Navigator.pop(context);


                  },
                  child: const Text(DetailsItemStrings.remove),
                ),
              ],
            );
          },
        );


      },
      style: ElevatedButton.styleFrom(
        elevation: 5,
        foregroundColor: Colors.limeAccent,
        backgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: const Text(DetailsItemStrings.remove),
    );
  }
}